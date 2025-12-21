/*
Script: Stage SBA Geojson - County Governor-Designated Covered Area.sql
Created by: Joshua Wilshere
Created on: 5/30/23

(39 rows affected)

Completion time: 2023-06-02T11:33:57.9740016-07:00
*/

DECLARE @geoJSONFile nvarchar(max), @SRID BIGINT,
		@BULKDIR NVARCHAR(255), @AUDFILENAME NVARCHAR(255), 
		@BULKSQL NVARCHAR(255);

-- File must be located on the SQL Server
SET @BULKDIR = 'S:\bulkdata\sba_hubzone\geojson\'
SET @AUDFILENAME = 'County Governor-Designated Covered Area.geojson'

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
    id,
    state_fips,
    county_fips,
    tract_code,
    date_approved,
    state,
    county,
    expires,
    census_year,
	-- Don't adjust the below 4 columns
	[SRID],
	[geo_type], 
	[coordinates], 
	[AUD_FILENAME]
)
select 
    id,
    state_fips,
    county_fips,
    tract_code,
    date_approved,
    state,
    county,
    expires,
    census_year,
	-- Don't adjust the below 4 columns
	@SRID,
	[geo_type], 
	[coordinates], 
	@AUDFILENAME
from   openjson (@geoJSONFile, '$.features')
with
(
    id NVARCHAR(50)  '$.properties.id',
    state_fips NVARCHAR(100)  '$.properties.state_fips',
    county_fips NVARCHAR(100)  '$.properties.county_fips',
    tract_code NVARCHAR(100)  '$.properties.tract_code',
    date_approved DATE  '$.properties.date_approved',
    state NVARCHAR(100)  '$.properties.state',
    county NVARCHAR(100)  '$.properties.county',
    expires DATE  '$.properties.expires',
    census_year NVARCHAR(30)  '$.properties.census_year',

	-- Don't adjust the below 2 columns
	[geo_type] Varchar(64)		'$.geometry.type',
    [coordinates] nvarchar(max) '$.geometry.coordinates' as json
)
END
ELSE 
	PRINT @AUDFILENAME + ' is already loaded'