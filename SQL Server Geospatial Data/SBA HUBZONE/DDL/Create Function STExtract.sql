/*
Script: Create Function STExtract.sql
Created by: Joshua Wilshere
Created on 6/1/23
Reference: https://www.spdba.com.au/stextract-extract-elements-of-a-geometry-object/

Note: Incoming datatype MUST be geometry. To convert a data element from geography to geometry
	modify and use the following statement.

SET @p_geometry = geometry::STGeomFromText(@p_geography.STAsText(),@p_geography.STSrid).MakeValid();

*/

DROP FUNCTION IF EXISTS [dbo].[STExtract]
 GO
 CREATE FUNCTION [dbo].[STExtract](@p_geometry geometry,
                                 @p_sub_geom INT = 0 )
   RETURNS @geometries TABLE
    (gid  INTEGER,
     sid  INTEGER,
     geom geometry)
 AS
 BEGIN
   DECLARE
     @v_GeometryType VARCHAR(1000),
     @v_sub_n        INT,
     @v_geom_n       INT,
     @geom           geometry;
   BEGIN
     IF ( @p_geometry IS NULL )
       RETURN;
     SET @v_GeometryType = @p_geometry.STGeometryType();
     IF ( @v_GeometryType = 'Point' )
     BEGIN
       INSERT INTO @geometries ( [gid],[sid],[geom] )
            VALUES ( 1,
                     0,
                     @p_geometry );
       RETURN;
     END;
     IF ( @v_GeometryType = 'MultiPoint' )
     BEGIN
       SET @v_geom_n  = 1;
       WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
       BEGIN
         INSERT INTO @geometries ( [gid],[sid],[geom] )
              VALUES ( @v_geom_n,
                       0,
                       @p_geometry.STGeometryN(@v_geom_n) );
         SET @v_geom_n = @v_geom_n + 1;
       END;
       RETURN;
     END;
     IF ( @v_GeometryType IN ('LineString') )
     BEGIN
       INSERT INTO @geometries ( [gid],[sid],[geom] )
            VALUES ( 1,
                     0,
                     @p_geometry );
       RETURN;
     END;
     IF ( @v_GeometryType IN ('CircularCurve','CompoundCurve') )
     BEGIN
       IF ( @p_sub_geom = 0 )
       BEGIN
         INSERT INTO @geometries ( [gid],[sid],[geom] )
              VALUES ( 1, 0, @p_geometry );
       RETURN;
       END
       ELSE
       BEGIN
         SET @v_geom_n  = 1;
         WHILE ( @v_geom_n <= @p_geometry.STNumCurves() )
         BEGIN
           INSERT INTO @geometries ( [gid],[sid],[geom] )
               VALUES ( 1,
                         @v_geom_n,
                         @p_geometry.STCurveN(@v_geom_n) ); 
           SET @v_geom_n = @v_geom_n + 1;
         END;
         RETURN;
      END
     END;
     IF ( @v_GeometryType IN ('MultiLineString') )
     BEGIN
       SET @v_geom_n  = 1;
       WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
       BEGIN
         INSERT INTO @geometries ( [gid],[sid],[geom] )
              SELECT @v_geom_n,
                     [sid],
                     [geom]
                FROM dbo.STExtract(@p_geometry.STGeometryN(@v_geom_n),@p_sub_geom);
         SET @v_geom_n = @v_geom_n + 1;
       END;
       RETURN;
     END;
     IF ( @v_GeometryType IN ('Polygon','CurvePolygon') )
     BEGIN
       IF ( @p_sub_geom = 1 )
       BEGIN
         SET @v_sub_n  = 0;
         WHILE ( @v_sub_n < ( 1 + @p_geometry.STNumInteriorRing() ) )
         BEGIN
           IF ( @v_sub_n = 0 )
             SET @geom = @p_geometry.STExteriorRing()
           ELSE
             SET @geom = @p_geometry.STInteriorRingN(@v_sub_n);
           IF ( @v_geometryType = 'CurvePolygon' )
           BEGIN
              INSERT INTO @geometries ( [gid],[sid],[geom] )
              SELECT a.gid, a.sid, a.geom
                FROM dbo.STExtract(@geom,@p_sub_geom) AS a;
           END
           ELSE
           BEGIN
             INSERT INTO @geometries ( [gid],[sid],[geom] )
                VALUES ( 1,
                         @v_sub_n + 1,
                         geometry::STGeomFromText(
                                   CASE WHEN UPPER(@geom.STAsText()) LIKE 'LINESTRING%'
                                        THEN REPLACE(REPLACE(UPPER(@geom.STAsText()),'LINESTRING (','POLYGON (('),')','))')
                                        WHEN UPPER(@geom.STAsText()) LIKE 'COMPOUNDCURVE%'
                                        THEN REPLACE(UPPER(@geom.STAsText()),'COMPOUNDCURVE','CURVEPOLYGON(COMPOUNDCURVE') + ')'
                                        ELSE @geom.STAsText()
                                     END,
                                   @p_geometry.STSrid));
           END;
           SET @v_sub_n = @v_sub_n + 1;
         END;
       END
       ELSE
       BEGIN
         INSERT INTO @geometries ( [gid],[sid],[geom] )
              VALUES ( 1,
                       0,
                       @p_geometry);
       END;
       RETURN;
     END;
     IF ( @v_GeometryType = 'MultiPolygon' )
     BEGIN
       SET @v_geom_n  = 1;
       WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
       BEGIN
          IF ( @p_sub_geom = 0 )
          BEGIN
              INSERT INTO @geometries ( [gid],[sid],[geom] )
                   VALUES ( @v_geom_n,
                            0,
                            @p_geometry.STGeometryN(@v_geom_n));
          END
          ELSE
          BEGIN
              INSERT INTO @geometries ( [gid],[sid],[geom] )
              SELECT @v_geom_n,
                     [sid],
                     [geom]
                FROM dbo.STExtract(@p_geometry.STGeometryN(@v_geom_n),@p_sub_geom);
          END;
          SET @v_geom_n = @v_geom_n + 1;
       END;
       RETURN;
     END;
     IF ( @v_GeometryType = 'GeometryCollection' )
     BEGIN
       SET @v_geom_n  = 1;
       WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
       BEGIN
          INSERT INTO @geometries ( [gid],[sid],[geom] )
               SELECT @v_geom_n,
                      [sid],
                      [geom]
                 FROM dbo.STExtract(@p_geometry.STGeometryN(@v_geom_n),@p_sub_geom);
         SET @v_geom_n = @v_geom_n + 1;
       END;
       RETURN;
     END;
   END;
   RETURN;
 END
 GO