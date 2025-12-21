/*
Script: Create and Load Table addresses_with_coords.sql
Purpose: 
      1. Load subset of addresses with latitude and longitude tables from main address table to subset table
      2. Convert latitude and longitude to a SQL Server POINT datatype
      3. Convert latitude and longitude to a SQL Server GEOGRAPHY datatype

*/

drop table if exists [dbo].[addresses_with_coords]
go

SELECT [ADDRESS_ID]
      ,[ADDRESS_LINE_1]
      ,[ADDRESS_LINE_2]
      ,[CITY]
      ,[STATE_OR_PROVINCE]
      ,[ZIP_CODE]
      ,[ZIP_CODE4]
      ,[ZIPCODE_COMPLETE]
      ,[LATITUDE]
      ,[LONGITUDE]
	  ,address_point = CONCAT('POINT(',try_cast(LONGITUDE as nvarchar(25)), ' ', try_cast(LATITUDE as nvarchar(25)),')')
	  ,address_coords = geography::STGeomFromText(CONCAT('POINT(',try_cast(LONGITUDE as nvarchar(25)), ' ', try_cast(LATITUDE as nvarchar(25)), ')'),4326).MakeValid()
	INTO [DFAU_Sandbox].[dbo].[addresses_with_coords]
  FROM [dbo].ADDRESS
  where COUNTRYCODE = 'USA'
  and LATITUDE is not null
  and LONGITUDE is not null;

  -- spatial indexes require the table to have a clustered primary key column
  alter table [addresses_with_coords] add primary key([ADDRESS_ID]);

  -- create spatial index for faster geospatial analysis, like point within polygon    
  create spatial index spix_address_coords on [addresses_with_coords](address_coords);