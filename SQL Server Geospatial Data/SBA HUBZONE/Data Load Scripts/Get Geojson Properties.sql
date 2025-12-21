DECLARE @geoJSONFile nvarchar(max), @SRID BIGINT,
		@BULKDIR NVARCHAR(255), @AUDFILENAME NVARCHAR(255), 
		@BULKSQL NVARCHAR(255), @tab CHAR(2);

-- File must be located on the SQL Server
SET @BULKDIR = 'S:\bulkdata\sba_hubzone\geojson\'
SET @AUDFILENAME = 'County.geojson'

SET @tab = CHAR(9)

SET @BULKSQL = 'SELECT @JSONFile = BulkColumn FROM OPENROWSET 
(BULK ''' + CONCAT(@BULKDIR, @AUDFILENAME) + ''', SINGLE_CLOB) as JSON'

EXECUTE sp_executesql @BULKSQL, N'@JSONFile nvarchar(max) OUTPUT', @JSONFile = @geoJSONFile OUTPUT;

-- These queries help to describe the keys and properties of the geojson file
--SELECT *,
--		[type_desc] = CASE [type]
--			WHEN 0 THEN 'NULL'
--			WHEN 1 THEN 'STRING'
--			WHEN 2 THEN 'NUMBER'
--			WHEN 3 THEN 'TRUE/FALSE'
--			WHEN 4 THEN 'ARRAY'
--			WHEN 5 THEN 'OBJECT'
--		END
--FROM OPENJSON(@geoJSONFile, '$.features[0].geometry');
SELECT *,
		[type_desc] = CASE [type]
			WHEN 0 THEN 'NULL'
			WHEN 1 THEN 'STRING'
			WHEN 2 THEN 'NUMBER'
			WHEN 3 THEN 'TRUE/FALSE'
			WHEN 4 THEN 'ARRAY'
			WHEN 5 THEN 'OBJECT'
		END
FROM OPENJSON(@geoJSONFile, '$.features[0].properties');

with key_cte as(
SELECT 
	[key] = CASE [key] COLLATE SQL_Latin1_General_CP1_CI_AS
		WHEN 'state_fip' THEN 'state_fips'
		WHEN 'county_fip' THEN 'county_fips'
		WHEN 'state_name' THEN 'state'
		WHEN 'county_name' THEN 'county'
		WHEN 'st_name' THEN 'state'
		WHEN 'brac_sba_name' THEN 'sba_name'
		WHEN 'name' THEN 'sba_name'
		ELSE [key] COLLATE SQL_Latin1_General_CP1_CI_AS
		END,
	[value],
	[type],
		[type_desc] = CASE [type]
			WHEN 0 THEN 'NULL'
			WHEN 1 THEN 'STRING'
			WHEN 2 THEN 'NUMBER'
			WHEN 3 THEN 'TRUE/FALSE'
			WHEN 4 THEN 'ARRAY'
			WHEN 5 THEN 'OBJECT'
		END
FROM OPENJSON(@geoJSONFile, '$.features[0].properties')

),


type_cte as(

SELECT 
	a.[key],
	a.[value],
	a.[type],
	[type_desc] = CASE [type]
			WHEN 0 THEN 'NULL'
			WHEN 1 THEN 'STRING'
			WHEN 2 THEN 'NUMBER'
			WHEN 3 THEN 'TRUE/FALSE'
			WHEN 4 THEN 'ARRAY'
			WHEN 5 THEN 'OBJECT'
		END,
		c.name,
		datatype = CASE
			WHEN LOWER(t.Name) in ('nvarchar', 'nchar') and c.max_length = -1
				THEN CONCAT(UPPER(t.name), '(MAX)')
			WHEN LOWER(t.Name) in ('nvarchar', 'nchar') and c.max_length != -1
				THEN CONCAT(UPPER(t.name), '(', c.max_length/2, ')')
			WHEN t.name like '%char%'
				THEN CONCAT(UPPER(t.name), '(', c.max_length, ')')
			WHEN LOWER(t.Name) in ('numeric', 'decimal', 'money', 'smallmoney')
				THEN CONCAT(UPPER(t.name), '(', c.precision, ',', c.scale, ')')
			ELSE UPPER(t.name)
		END
from key_cte a
left join 
	(SELECT * FROM sys.columns
		WHERE [object_id] = OBJECT_ID('dbo.SBA_HUBZONE_GEOGRAPHY_Stage'))c
	on a.[key] COLLATE SQL_Latin1_General_CP1_CI_AS = c.name
	
left JOIN 
	sys.types t ON c.user_type_id = t.user_type_id
)

select 
	[key],
	[value],
	[type],
	[type_desc],
	[name],
	[datatype],
	JSONWITH = CONCAT(@tab, @tab, name, ' ', datatype, @tab, '''$.properties.', [key], ''','),
	--CASE
	--	WHEN [name] IS NULL
	--		THEN CONCAT(@tab, @tab, [key], ' NVARCHAR(100) ', @tab, '''$.properties.', [key], ''',')
	--	ELSE CONCAT(@tab, @tab, name, ' ', datatype, @tab, '''$.properties.', [key], ''',')
	--END,
	SELECTFROM = concat(@tab, @tab, name, ',')
	
	--CASE
	--	WHEN [name] IS NULL
	--		THEN concat(@tab, @tab, [key], ',')
	--	ELSE concat(@tab, @tab, name, ',')
	--	END
from type_cte

