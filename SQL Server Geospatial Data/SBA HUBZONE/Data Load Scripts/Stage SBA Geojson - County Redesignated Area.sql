/*
Script: Stage SBA Geojson - County Redesignated Area.sql
Created by: Joshua Wilshere
Created on: 5/30/23

(98 rows affected)

Completion time: 2023-06-02T11:35:24.5095324-07:00
*/

DECLARE @geoJSONFile nvarchar(max), @SRID BIGINT,
		@BULKDIR NVARCHAR(255), @AUDFILENAME NVARCHAR(255), 
		@BULKSQL NVARCHAR(255);

-- File must be located on the SQL Server
SET @BULKDIR = 'S:\bulkdata\sba_hubzone\geojson\'
SET @AUDFILENAME = 'County Redesignated Area.geojson'

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
    county_fips,
    county,
    state,
    income,
    unemployment,
    dda,
    redesignated,
    expires,
    median_household_income_ratio_2017,
    state_unemployment_ratio_2017,
    us_unemployment_ratio_2017,
    omb_delineation,
    july_2017_status_previous,
    q_inc_2018,
    q_dda_2018,
    q_unemp_2016,
    q_unemp_2015,
    q_unemp_2014,
    january_2018_current,
    status_change,
    effective,
    qda,
	-- Don't adjust the below 4 columns
	[SRID],
	[geo_type], 
	[coordinates], 
	[AUD_FILENAME]
)
select 
    gid,
    county_fips,
    county,
    state,
    income,
    unemployment,
    dda,
    redesignated,
    expires,
    median_household_income_ratio_2017,
    state_unemployment_ratio_2017,
    us_unemployment_ratio_2017,
    omb_delineation,
    july_2017_status_previous,
    q_inc_2018,
    q_dda_2018,
    q_unemp_2016,
    q_unemp_2015,
    q_unemp_2014,
    january_2018_current,
    status_change,
    effective,
    qda,
	-- Don't adjust the below 4 columns
	@SRID,
	[geo_type], 
	[coordinates], 
	@AUDFILENAME
from   openjson (@geoJSONFile, '$.features')
with
(
    gid BIGINT  '$.properties.gid',
    county_fips NVARCHAR(100)  '$.properties.county_fips',
    county NVARCHAR(100)  '$.properties.county',
    state NVARCHAR(100)  '$.properties.state',
    income NVARCHAR(30)  '$.properties.income',
    unemployment NVARCHAR(30)  '$.properties.unemployment',
    dda NVARCHAR(30)  '$.properties.dda',
    redesignated NVARCHAR(30)  '$.properties.redesignated',
    expires DATE  '$.properties.expires',
    median_household_income_ratio_2017 FLOAT  '$.properties.median_household_income_ratio_2017',
    state_unemployment_ratio_2017 FLOAT  '$.properties.state_unemployment_ratio_2017',
    us_unemployment_ratio_2017 FLOAT  '$.properties.us_unemployment_ratio_2017',
    omb_delineation NVARCHAR(100)  '$.properties.omb_delineation',
    july_2017_status_previous NVARCHAR(100)  '$.properties.july_2017_status_previous',
    q_inc_2018 NVARCHAR(100)  '$.properties.q_inc_2018',
    q_dda_2018 NVARCHAR(100)  '$.properties.q_dda_2018',
    q_unemp_2016 NVARCHAR(100)  '$.properties.q_unemp_2016',
    q_unemp_2015 NVARCHAR(100)  '$.properties.q_unemp_2015',
    q_unemp_2014 NVARCHAR(100)  '$.properties.q_unemp_2014',
    january_2018_current NVARCHAR(100)  '$.properties.january_2018_current',
    status_change NVARCHAR(30)  '$.properties.status_change',
    effective DATE  '$.properties.effective',
    qda NVARCHAR(30)  '$.properties.qda',

	-- Don't adjust the below 2 columns
	[geo_type] Varchar(64)		'$.geometry.type',
    [coordinates] nvarchar(max) '$.geometry.coordinates' as json
)
END
ELSE 
	PRINT @AUDFILENAME + ' is already loaded'