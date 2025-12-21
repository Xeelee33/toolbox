/*
Script: Create Function STExtractPolygon.sql
Created by: Joshua Wilshere
Created on 6/1/23
Reference: https://www.spdba.com.au/stextractpolygon-extract-polygons-from-result-of-stintersection-in-sql-server-spatial/
Dependencies: Create Function STExtract.sql
*/

DROP FUNCTION IF EXISTS dbo.STExtractPolygon;
GO
-- Now create
--
CREATE FUNCTION dbo.STExtractPolygon(@p_geometry geometry)
RETURNS geometry
AS
BEGIN
  DECLARE
     @v_geom geometry;
  BEGIN
    IF ( @p_geometry IS NULL )
      RETURN NULL;
    IF ( @p_geometry.STGeometryType() NOT IN ('CurvePolygon','Polygon','MultiPolygon','GeometryCollection') )
    RETURN NULL;
  IF ( @p_geometry.STGeometryType() IN ('CurvePolygon','Polygon','MultiPolygon') )
    RETURN @p_geometry;
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
          SET @v_geom = geometry::STGeomFromText(REPLACE(REPLACE(@v_geom.STAsText(),'GEOMETRYCOLLECTION (','')+'$',')$',''),@v_geom.STSrid);
      END
    ELSE
      BEGIN
      IF ( CHARINDEX('CURVEPOLYGON',@v_geom.STAsText()) = 0 )
      BEGIN
             -- Replace all internal POLYGON WKT tokens with nothing
         -- Then replace starting GeometryCollection token with MultiPolygon
         --
           SET @v_geom = geometry::STGeomFromText(REPLACE(REPLACE(UPPER(@v_geom.STAsText()),'POLYGON',''),'GEOMETRYCOLLECTION','MULTIPOLYGON'),@v_geom.STSrid);
      END;
      END;
    END;
  END;
  RETURN @v_geom;
  END;
END
GO