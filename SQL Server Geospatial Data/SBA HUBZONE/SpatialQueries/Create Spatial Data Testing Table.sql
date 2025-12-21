
-- Create table of alaskan addresses for testing

drop table if exists dbo.alaska_address;

select *
into dbo.alaska_address
  FROM [dbo].[ADDRESS]
  where COUNTRYCODE = 'USA'
  and STATE_OR_PROVINCE = 'AK'

-- Load the data into a new table, converting the lat/long into geography data type
drop table if exists [dbo].[alaska_coords];

SELECT [ADDRESS_ID]
      ,[ADDRESS_LINE_1]
      ,[ADDRESS_LINE_2]
      ,[CITY]
      ,[STATE_OR_PROVINCE]
      ,[ZIP_CODE]
      ,[ZIP_CODE4]
      ,[ZIPCODE_COMPLETE]
      ,[COUNTRYCODE]
      ,[LATITUDE]
      ,[LONGITUDE]
	  ,address_point = CONCAT('POINT(',try_cast(LONGITUDE as nvarchar(25)), ' ', try_cast(latitude as nvarchar(25)),')')
	  ,address_coords = geography::STGeomFromText(CONCAT('POINT(',try_cast(LONGITUDE as nvarchar(25)), ' ', try_cast(latitude as nvarchar(25)), ')'),4326).MakeValid()
	INTO [dbo].[alaska_coords]
  FROM [dbo].[alaska_address];

  -- spatial indexes require the table to have a clustered primary key column
  alter table [alaska_coords] add primary key([ADDRESS_ID]);
  
  -- create spatial index for faster geospatial analysis, like point within polygon
  create spatial index spix_address_coords on [alaska_coords](address_coords);