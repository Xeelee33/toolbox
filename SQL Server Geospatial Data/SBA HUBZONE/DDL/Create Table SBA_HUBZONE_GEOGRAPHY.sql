/*
Script: Create Table SBA_HUBZONE_GEOGRAPHY.sql
Created by: Joshua Wilshere
Created on: 5/30/23
Purpose: Create single unified table to consolidate all geojson files from SBA HUBZONE

*/

DROP TABLE IF EXISTS SBA_HUBZONE_GEOGRAPHY;

CREATE TABLE SBA_HUBZONE_GEOGRAPHY (
    gid BIGINT,
    id NVARCHAR(50),
    tract_fips NVARCHAR(100),
    brac_id BIGINT,
    sba_name NVARCHAR(255),
    state_fips NVARCHAR(100),
    county_fips NVARCHAR(100),
    objectid BIGINT,
    qda_id BIGINT,
    county NVARCHAR(100),
    indian NVARCHAR(100),
    state NVARCHAR(100),
    tract_code NVARCHAR(100),
    qda_publish DATE,
    income NVARCHAR(30), --Might be boolean
    qda_declaration DATE,
    effective DATE,
    fac_type NVARCHAR(100),
    omb_delineation NVARCHAR(100),
    date_approved DATE,
    prior_status NVARCHAR(100),
    closure DATE,
    unemployment NVARCHAR(30), --Might be boolean
    qnmc_max_expires DATE,
    expires DATE,
    census NVARCHAR(100),
    dda NVARCHAR(30), --Might be boolean
    gnis BIGINT,
    publish_date DATE,
    qnmc_current_status NVARCHAR(100),
    qct_max_expires DATE,
    current_status NVARCHAR(100),
    import_table_name NVARCHAR(100),
    qnmc_current_omb NVARCHAR(100),
    qct_current_status NVARCHAR(100),
    qnmc_data_table NVARCHAR(100),
    status_change NVARCHAR(30), --Might be boolean
    redesignated NVARCHAR(30), --Might be boolean
    qct_data_table NVARCHAR(100),
    qda_designation DATE,
    brac NVARCHAR(30), --Might be boolean
    [type] NVARCHAR(100),
    census_year NVARCHAR(30),
    raw_geom NVARCHAR(MAX),
    class NVARCHAR(100),
    median_household_income_ratio_2017 FLOAT,
    state_unemployment_ratio_2017 FLOAT,
    recognitio NVARCHAR(100),
    us_unemployment_ratio_2017 FLOAT,
    land_area FLOAT,
    water_area FLOAT,
    disaster_state NVARCHAR(100),
    disaster_type NVARCHAR(100),
    july_2017_status_previous NVARCHAR(100),
    shape_leng FLOAT,
    shape_area FLOAT,
    q_inc_2018 NVARCHAR(100),
    fema_code NVARCHAR(100),
    incident_description NVARCHAR(100),
    q_dda_2018 NVARCHAR(100),
    q_unemp_2016 NVARCHAR(100),
    incidence_period NVARCHAR(100),
    amendment  NVARCHAR(100),
    q_unemp_2015 NVARCHAR(100),
    q_unemp_2014 NVARCHAR(100),
    january_2018_current NVARCHAR(100),
    qda NVARCHAR(30), --Might be boolean,
    coordinates GEOGRAPHY,
	
	-- Audit Columns added during load
    AUD_SEQ_ID BIGINT PRIMARY KEY, -- Acquires value of AUD_SEQ_ID from SBA_HUBZONE_GEOGRAPHY_Stage
    AUD_INSRT_TMSTP DATETIME2 DEFAULT SYSDATETIME(),
    AUD_FILENAME NVARCHAR(255)
);
