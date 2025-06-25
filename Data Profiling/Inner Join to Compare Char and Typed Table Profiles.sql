/*
Script: Inner Join to Compare Char and Typed Table Profiles.sql
Created by: Joshua Wilshere
Created on: 12/5/23
Purpose: Join the AllChar and datatyped table profiles together for comparison

!!!!Important Note!!!! - The [char_DISTINCT_COUNT] will be 1 higher than the [type_DISTINCT_COUNT] if the column had blanks in the _AllChar table
that were converted to NULL in the datatyped table, as '' is a counted a value in DISTINCT() but NULL is not.

Pre-requisites: Created and Populate Table Profile Meta Table.sql
*/

with tablechar as (
SELECT [SCHEMA_NAME]
      ,[TABLE_NAME]
      ,[COLUMN_ID]
      ,[COLUMN_NAME]
      ,[DATATYPE]
      ,[MAX_LEN]
      ,[MAX_LEN_VALUE]
      ,[MIN_LEN]
      ,[NULL_COUNT]
      ,[BLANK_COUNT]
      ,[NUMERIC_VALUE_COUNT]
      ,[MAX_PRECISION]
      ,[MAX_SCALE]
      ,[DISTINCT_COUNT]
      ,[TOTAL_RECORD_COUNT]
  FROM [meta].[TABLE_PROFILES]
  where TABLE_NAME = '[green_tripdata_2020-04_Excel_AllChar]')

, tabletype as (
SELECT [SCHEMA_NAME]
      ,[TABLE_NAME]
      ,[COLUMN_ID]
      ,[COLUMN_NAME]
      ,[DATATYPE]
      ,[MAX_LEN]
      ,[MAX_LEN_VALUE]
      ,[MIN_LEN]
      ,[NULL_COUNT]
      ,[BLANK_COUNT]
      ,[NUMERIC_VALUE_COUNT]
      ,[MAX_PRECISION]
      ,[MAX_SCALE]
      ,[DISTINCT_COUNT]
      ,[TOTAL_RECORD_COUNT]
  FROM [meta].[TABLE_PROFILES]
  where TABLE_NAME = '[green_tripdata_2020-04_Excel]')

select 

c.[COLUMN_NAME] as [char_COLUMN_NAME]
,t.[COLUMN_NAME] as [type_COLUMN_NAME]
,c.[DATATYPE] as [char_DATATYPE]
,t.[DATATYPE] as [type_DATATYPE]
,c.[MAX_LEN] as [char_MAX_LEN]
,t.[MAX_LEN] as [type_MAX_LEN]
,c.[MAX_LEN_VALUE] as [char_MAX_LEN_VALUE]
,t.[MAX_LEN_VALUE] as [type_MAX_LEN_VALUE]
,c.[MIN_LEN] as [char_MIN_LEN]
,t.[MIN_LEN] as [type_MIN_LEN]
,c.[NULL_COUNT] as [char_NULL_COUNT]
,t.[NULL_COUNT] as [type_NULL_COUNT]
,c.[BLANK_COUNT] as [char_BLANK_COUNT]
,t.[BLANK_COUNT] as [type_BLANK_COUNT]
,c.[NUMERIC_VALUE_COUNT] as [char_NUMERIC_VALUE_COUNT]
,t.[NUMERIC_VALUE_COUNT] as [type_NUMERIC_VALUE_COUNT]
,c.[MAX_PRECISION] as [char_MAX_PRECISION]
,t.[MAX_PRECISION] as [type_MAX_PRECISION]
,c.[MAX_SCALE] as [char_MAX_SCALE]
,t.[MAX_SCALE] as [type_MAX_SCALE]
,c.[DISTINCT_COUNT] as [char_DISTINCT_COUNT]
,t.[DISTINCT_COUNT] as [type_DISTINCT_COUNT]
,c.[TOTAL_RECORD_COUNT] as [char_TOTAL_RECORD_COUNT]
,t.[TOTAL_RECORD_COUNT] as [type_TOTAL_RECORD_COUNT]


from tablechar c
left join tabletype t
on c.COLUMN_ID = t.COLUMN_ID