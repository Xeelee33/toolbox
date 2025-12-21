/*
Script: Create Function STExtractPolygonGeog.sql
Created by: Joshua Wilshere
Created on 6/1/23
Reference: https://www.spdba.com.au/stextractpolygon-extract-polygons-from-result-of-stintersection-in-sql-server-spatial/
Dependencies: Create Function STExtract.sql

Instructions: 

SELECT dbo.STExtractPolygonGeog(geographyfield) FROM TABLE;

*/

DROP FUNCTION IF EXISTS dbo.STExtractPolygonGeog;
GO
-- Now create
--
CREATE FUNCTION dbo.STExtractPolygonGeog(@p_geography geography)
RETURNS geography
AS
BEGIN
  DECLARE
	@p_geometry geometry,
	@v_geom geometry,
	@v_geog geography;
  BEGIN
	-- Converts geography field to geometry
	SET @p_geometry = geometry::STGeomFromText(@p_geography.STAsText(),@p_geography.STSrid).MakeValid();
    IF ( @p_geometry IS NULL )
      RETURN NULL;
    IF ( @p_geometry.STGeometryType() NOT IN ('CurvePolygon','Polygon','MultiPolygon','GeometryCollection') )
    RETURN NULL;
  IF ( @p_geometry.STGeometryType() IN ('CurvePolygon','Polygon','MultiPolygon') )
    RETURN @p_geography;
  IF ( @p_geometry.STGeometryType() IN ('GeometryCollection') )
  BEGIN

		
    -- Need to extract and append any polygons that may be in the GeometryCollection
    --
      SELECT @v_geom = geometry::CollectionAggregate(e.[geom])
        FROM dbo.STExtract(@p_geometry,0) AS e
     WHERE e.[geom].STGeometryType() IN ('CurvePolygon','Polygon');
    IF ( @v_geom IS NOT NULL AND @v_geom.STNumGeometries() > 0 )
    BEGIN
      IF ( @v_geom.STNumGeometries() = 1 )
      BEGIN
      -- Get rid of GeometryCollection WKT token wrapper
      --
          --SET @v_geom = geometry::STGeomFromText(REPLACE(REPLACE(@v_geom.STAsText(),'GEOMETRYCOLLECTION (','')+'$',')$',''),@v_geom.STSrid);
		  SET @v_geog = geography::STGeomFromText(REPLACE(REPLACE(@v_geom.STAsText(),'GEOMETRYCOLLECTION (','')+'$',')$',''),@v_geom.STSrid).MakeValid();

      END
    ELSE
      BEGIN
      IF ( CHARINDEX('CURVEPOLYGON',@v_geom.STAsText()) = 0 )
      BEGIN
             -- Replace all internal POLYGON WKT tokens with nothing
         -- Then replace starting GeometryCollection token with MultiPolygon
         --
           --SET @v_geom = geometry::STGeomFromText(REPLACE(REPLACE(UPPER(@v_geom.STAsText()),'POLYGON',''),'GEOMETRYCOLLECTION','MULTIPOLYGON'),@v_geom.STSrid);
		   SET @v_geog = geography::STGeomFromText(REPLACE(REPLACE(UPPER(@v_geom.STAsText()),'POLYGON',''),'GEOMETRYCOLLECTION','MULTIPOLYGON'),@v_geom.STSrid).MakeValid();
      END;
      END;
    END;
  END;
  --RETURN @v_geom;
  RETURN @v_geog;
  END;
END
GO