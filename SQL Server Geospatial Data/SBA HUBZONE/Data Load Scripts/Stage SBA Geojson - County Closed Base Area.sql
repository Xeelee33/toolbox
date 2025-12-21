/*
Script: Stage SBA Geojson - County Closed Base Area.sql
Created by: Joshua Wilshere
Created on: 5/30/23

(63 rows affected)

Completion time: 2023-06-02T11:32:33.5241216-07:00
*/

DECLARE @geoJSONFile nvarchar(max), @SRID BIGINT,
		@BULKDIR NVARCHAR(255), @AUDFILENAME NVARCHAR(255), 
		@BULKSQL NVARCHAR(255);

-- File must be located on the SQL Server
SET @BULKDIR = 'S:\bulkdata\sba_hubzone\geojson\'
SET @AUDFILENAME = 'County Closed Base Area.geojson'

-- Check for data existence to prevent duplication
IF (SELECT TOP 1 [AUD_FILENAME] FROM [SBA_HUBZONE_GEOGRAPHY_Stage] WHERE [AUD_FILENAME] = @AUDFILENAME) IS NULL
BEGIN

-- Bulk load the file into a JSON CLOB
SET @BULKSQL = 'SELECT @JSONFile = BulkColumn FROM OPENROWSET 
(BULK ''' + CONCAT(@BULKDIR, @AUDFILENAME) + ''', SINGLE_CLOB) as JSON'

EXECUTE sp_executesql @BULKSQL, N'@JSONFile nvarchar(max) OUTPUT', @JSONFile = @geoJSONFile OUTPUT

-- Extract the SRID from the feature collection header.
SELECT @SRID = Substring(crs_name, CharIndex('::', crs_name) + 2, LEN(crs_name) - CharIndex('::', crs_name))
	from openjson (@geoJSONFile)
	WITH
	(crs_name nvarchar(100) '$.crs.properties.name');

-- Extract properties out of JSON document into stage table columns
-- Extract coordinates as json into an NVARCHAR(MAX) field. 
-- Coordinates will be converted to geography datatype in follow-on process
Insert Into [SBA_HUBZONE_GEOGRAPHY_Stage] 
(
    gid,
    brac_id,
    sba_name,
    county_fips,
    effective,
    expires,
    publish_date,
    qnmc_data_table,
    brac,
    raw_geom,
    fac_type,
    closure,
    county,
    state,
	-- Don't adjust the below 4 columns
	[SRID],
	[geo_type], 
	[coordinates], 
	[AUD_FILENAME]
)
select 
    gid,
    brac_id,
    sba_name,
    county_fips,
    effective,
    expires,
    publish_date,
    qnmc_data_table,
    brac,
    raw_geom,
    fac_type,
    closure,
    county,
    state,
	-- Don't adjust the below 4 columns
	@SRID,
	[geo_type], 
	[coordinates], 
	@AUDFILENAME
from   openjson (@geoJSONFile, '$.features')
with
(
    gid BIGINT  '$.properties.gid',
    brac_id BIGINT  '$.properties.brac_id',
    sba_name NVARCHAR(255)  '$.properties.sba_name',
    county_fips NVARCHAR(100)  '$.properties.county_fips',
    effective DATE  '$.properties.effective',
    expires DATE  '$.properties.expires',
    publish_date DATE  '$.properties.publish_date',
    qnmc_data_table NVARCHAR(100)  '$.properties.qnmc_data_table',
    brac NVARCHAR(30)  '$.properties.brac',
    raw_geom NVARCHAR(MAX)  '$.properties.raw_geom',
    fac_type NVARCHAR(100)  '$.properties.fac_type',
    closure DATE  '$.properties.closure',
    county NVARCHAR(100)  '$.properties.county',
    state NVARCHAR(100)  '$.properties.state',

	-- Don't adjust the below 2 columns
	[geo_type] Varchar(64)		'$.geometry.type',
    [coordinates] nvarchar(max) '$.geometry.coordinates' as json
)
END
ELSE 
	PRINT @AUDFILENAME + ' is already loaded'