/*
Script: Load SBA Geojson From Stage.sql
Created by: Joshua Wilshere
Created on: 5/30/23
Purpose: Load all data from stage into SBA_HUBZONE_GEOGRAPHY and ensure all
	geography elements are POLYGON and MULTIPOLYGON


(28744 rows affected)

Completion time: 2023-06-02T14:42:07.0124148-07:00
*/
--DECLARE @AUDFILENAME NVARCHAR(255);

-- Drops spatial index (if it exists) prior to loading table. Index recreated at bottom of script.
DROP INDEX IF EXISTS spix_sba_hubzone_geography_coordinates on [SBA_HUBZONE_GEOGRAPHY];

Insert Into [SBA_HUBZONE_GEOGRAPHY] (
	gid
	,id
	,tract_fips
	,brac_id
	,sba_name
	,state_fips
	,county_fips
	,objectid
	,qda_id
	,county
	,indian
	,state
	,tract_code
	,qda_publish
	,income
	,qda_declaration
	,effective
	,fac_type
	,omb_delineation
	,date_approved
	,prior_status
	,closure
	,unemployment
	,qnmc_max_expires
	,expires
	,census
	,dda
	,gnis
	,publish_date
	,qnmc_current_status
	,qct_max_expires
	,current_status
	,import_table_name
	,qnmc_current_omb
	,qct_current_status
	,qnmc_data_table
	,status_change
	,redesignated
	,qct_data_table
	,qda_designation
	,brac
	,type
	,census_year
	,raw_geom
	,class
	,median_household_income_ratio_2017
	,state_unemployment_ratio_2017
	,recognitio
	,us_unemployment_ratio_2017
	,land_area
	,water_area
	,disaster_state
	,disaster_type
	,july_2017_status_previous
	,shape_leng
	,shape_area
	,q_inc_2018
	,fema_code
	,incident_description
	,q_dda_2018
	,q_unemp_2016
	,incidence_period
	,amendment
	,q_unemp_2015
	,q_unemp_2014
	,january_2018_current
	,qda
	,coordinates 
	,AUD_FILENAME
	,AUD_SEQ_ID
)

select 
	gid
	,id
	,tract_fips
	,brac_id
	,sba_name
	,state_fips
	,county_fips
	,objectid
	,qda_id
	,county
	,indian
	,state
	,tract_code
	,qda_publish
	,income
	,qda_declaration
	,effective
	,fac_type
	,omb_delineation
	,date_approved
	,prior_status
	,closure
	,unemployment
	,qnmc_max_expires
	,expires
	,census
	,dda
	,gnis
	,publish_date
	,qnmc_current_status
	,qct_max_expires
	,current_status
	,import_table_name
	,qnmc_current_omb
	,qct_current_status
	,qnmc_data_table
	,status_change
	,redesignated
	,qct_data_table
	,qda_designation
	,brac
	,type
	,census_year
	,raw_geom
	,class
	,median_household_income_ratio_2017
	,state_unemployment_ratio_2017
	,recognitio
	,us_unemployment_ratio_2017
	,land_area
	,water_area
	,disaster_state
	,disaster_type
	,july_2017_status_previous
	,shape_leng
	,shape_area
	,q_inc_2018
	,fema_code
	,incident_description
	,q_dda_2018
	,q_unemp_2016
	,incidence_period
	,amendment
	,q_unemp_2015
	,q_unemp_2014
	,january_2018_current
	,qda
	--WKT, 
	-- Ensure any GeometryCollections are converted to Polygon/Multipolygon
	-- Some records must be run through multiple times because the .MakeValid() of the first round adds a new POINT or LINESTRING to the result
	,coordinates =
		CASE
		WHEN fixed.STGeometryType() = 'GeometryCollection'
			THEN dbo.STExtractPolygonGeog(dbo.STExtractPolygonGeog(fixed))
		ELSE fixed
		END
	,AUD_FILENAME
	,AUD_SEQ_ID
--into SBA_HUBZONE_GEOGRAPHY_test2
from [dbo].[SBA_HUBZONE_GEOGRAPHY_Stage] Geodata
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
    WHERE GeoData.[geo_type] = 'MultiPolygon'
) MultigonData
cross apply (
    SELECT concat(upper(GeoData.[geo_type]),'((',MultigonData.multi,'))') WKT
) shapeDef
outer apply (
    select geography::STGeomFromText(WKT,4326).MakeValid()/*.ReorientObject()*/ as geom
) geography
outer apply (
    select CASE WHEN geom.EnvelopeAngle() > 90 THEN geom.ReorientObject() ELSE geom END as fixed
) fixes;

-- Creates Spatial Index on coordinate column
CREATE SPATIAL INDEX spix_sba_hubzone_geography_coordinates on [SBA_HUBZONE_GEOGRAPHY]([coordinates]);