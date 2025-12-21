/*
Script: Load Geojson with Multipolygon Into Table.sql
Created by: Joshua Wilshere
Created on: 5/30/23

References:
https://stackoverflow.com/questions/56371128/issue-on-trying-to-query-geojson-multipolygons-in-sql-server-2016
https://learn.microsoft.com/en-us/sql/relational-databases/spatial/multipolygon?view=sql-server-ver16
https://stackoverflow.com/questions/33371865/convert-geojson-data-to-sql-server-spatial-data-type-gis
https://jeremylindsayni.wordpress.com/2019/01/14/use-sql-server-to-import-geojson-files-and-convert-geo-data-back-into-geojson/
https://techcommunity.microsoft.com/t5/sql-server-blog/loading-geojson-data-into-sql-server/ba-p/384601

*/


DECLARE @geoJSONFile nvarchar(max)
SELECT @geoJSONFile = BulkColumn
FROM OPENROWSET
-- File must be located on the SQL Server
(BULK 'T:\BulkLoad\sba_hubzone\geojson\Closed Base Area.geojson', SINGLE_CLOB)
as JSON

-- These queries help to describe the keys and properties of the geojson file
SELECT *,
		[type_desc] = CASE [type]
			WHEN 0 THEN 'NULL'
			WHEN 1 THEN 'STRING'
			WHEN 2 THEN 'NUMBER'
			WHEN 3 THEN 'TRUE/FALSE'
			WHEN 4 THEN 'ARRAY'
			WHEN 5 THEN 'OBJECT'
		END
FROM OPENJSON(@geoJSONFile, '$.features[0].geometry');

SELECT *,
		[type_desc] = CASE [type]
			WHEN 0 THEN 'NULL'
			WHEN 1 THEN 'STRING'
			WHEN 2 THEN 'NUMBER'
			WHEN 3 THEN 'TRUE/FALSE'
			WHEN 4 THEN 'ARRAY'
			WHEN 5 THEN 'OBJECT'
		END
FROM OPENJSON(@geoJSONFile, '$.features[1].properties');
/*
drop table if exists closed_base_area;

create table closed_base_area (
	gid char(5),
    sba_name varchar(100),
    county char(50),
    st_name char(50),
    fac_type Varchar(100),
	closure	date,
	import_table_name varchar(50),
	effective date,
	expires date,
	[type] Varchar(64),
	[boundary] geography
    --[coordinates] nvarchar(max)
);
*/

Insert Into [closed_base_area] ([gid], [sba_name], [county], [st_name], [fac_type], [closure], [import_table_name], [effective], [expires], [type], [boundary])
select gid, sba_name, county, st_name, fac_type, closure, import_table_name, effective, expires, [type], Geo=fixed
from   openjson (@geoJSONFile, '$.features')
with
(
    gid char(5)				'$.properties.gid',
    sba_name varchar(100)	'$.properties.sba_name',
    county char(50)			'$.properties.county',
    st_name char(50)		'$.properties.st_name',
    fac_type Varchar(100)	'$.properties.fac_type',
	closure	date			'$.properties.closure',
	import_table_name varchar(50)	'$.properties.import_table_name',
	effective date			'$.properties.effective',
	expires date			'$.properties.expires',
	[type] Varchar(64)		'$.geometry.type',
    [coordinates] nvarchar(max) '$.geometry.coordinates' as json
) as GeoData
OUTER APPLY (
select 
   stuff( 
      (
        select concat(',  ', json_value(Value,'$[0]'),' ',json_value(Value,'$[1]'))  
        from openjson(GeoData.coordinates,'$[0]') 
        order by cast([key] as int)
        for xml path('')
      ),1,3,'') [path]
      WHERE GeoData.[type] = 'Polygon'
) PolygonData
OUTER APPLY (
    SELECT  STUFF(
        (
            SELECT CONCAT(',  ', polygon)
            FROM OPENJSON(GeoData.coordinates) as Poly 
            CROSS APPLY OPENJSON(Poly.value) as Shape 
            CROSS APPLY (
                SELECT '(' + stuff( 
                (
                    select concat(',  ', json_value(Value,'$[0]'),' ',json_value(Value,'$[1]'))  
                    from OPENJSON(Shape.value)
                    order by cast([key] as int)
                    for xml path('')
                ),1,3,'')+')' polygon
        ) Polygons
        for xml path('')
    ),1,3,'') multi
    WHERE GeoData.[type] = 'MultiPolygon'
) MultigonData
cross apply (
    SELECT concat(upper(GeoData.[type]),'((',COALESCE(PolygonData.path, MultigonData.multi),'))') WKT
) shapeDef
-- Extract the SRID from the feature collection header.
outer apply (
    select ID = Substring(name, CharIndex('::', name) + 2, LEN(name) - CharIndex('::', name)) from  openjson (@geoJSONFile, '$.crs.properties')
    with ( name varchar(100) '$.name')
) SRID
outer apply (
    select geography::STGeomFromText(WKT,IsNull(SRID.ID, 4326)).MakeValid()/*.ReorientObject()*/ as geom
) geography
outer apply (
    select CASE WHEN geom.EnvelopeAngle() > 90 THEN geom.ReorientObject() ELSE geom END as fixed
) fixes