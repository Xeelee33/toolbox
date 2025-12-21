/*
Script: Stage SBA Geojson - Indian Land.sql
Created by: Joshua Wilshere
Created on: 5/30/23

(619 rows affected)

Completion time: 2023-06-02T11:37:20.1373720-07:00
*/

DECLARE @geoJSONFile nvarchar(max), @SRID BIGINT,
		@BULKDIR NVARCHAR(255), @AUDFILENAME NVARCHAR(255), 
		@BULKSQL NVARCHAR(255);

-- File must be located on the SQL Server
SET @BULKDIR = 'S:\bulkdata\sba_hubzone\geojson\'
SET @AUDFILENAME = 'Indian Land.geojson'

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
    objectid,
    id,
    indian,
    state,
    census,
    gnis,
    sba_name,
    type,
    class,
    recognitio,
    land_area,
    water_area,
    shape_leng,
    shape_area,
    effective,
    expires,
	-- Don't adjust the below 4 columns
	[SRID],
	[geo_type], 
	[coordinates], 
	[AUD_FILENAME]
)
select 
    gid,
    objectid,
    id,
    indian,
    state,
    census,
    gnis,
    sba_name,
    type,
    class,
    recognitio,
    land_area,
    water_area,
    shape_leng,
    shape_area,
    effective,
    expires,
	-- Don't adjust the below 4 columns
	@SRID,
	[geo_type], 
	[coordinates], 
	@AUDFILENAME
from   openjson (@geoJSONFile, '$.features')
with
(
    gid BIGINT  '$.properties.gid',
    objectid BIGINT  '$.properties.objectid',
    id NVARCHAR(50)  '$.properties.id',
    indian NVARCHAR(100)  '$.properties.indian',
    state NVARCHAR(100)  '$.properties.state',
    census NVARCHAR(100)  '$.properties.census',
    gnis BIGINT  '$.properties.gnis',
    sba_name NVARCHAR(255)  '$.properties.sba_name',
    type NVARCHAR(100)  '$.properties.type',
    class NVARCHAR(100)  '$.properties.class',
    recognitio NVARCHAR(100)  '$.properties.recognitio',
    land_area FLOAT  '$.properties.land_area',
    water_area FLOAT  '$.properties.water_area',
    shape_leng FLOAT  '$.properties.shape_leng',
    shape_area FLOAT  '$.properties.shape_area',
    effective DATE  '$.properties.effective',
    expires DATE  '$.properties.expires',

	-- Don't adjust the below 2 columns
	[geo_type] Varchar(64)		'$.geometry.type',
    [coordinates] nvarchar(max) '$.geometry.coordinates' as json
)
END
ELSE 
	PRINT @AUDFILENAME + ' is already loaded'