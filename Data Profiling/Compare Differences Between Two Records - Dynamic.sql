/*
Script: Compare Differences Between Two Records.sql
Created by: Joshua Wilshere
Created on: 6/24/25
Adapted from: https://stackoverflow.com/questions/28194628/compare-two-rows-and-identify-columns-whose-values-are-different

Purpose: Compare two records identified by unique ID (AUD_SEQ_ID) and return columns and values that are different

Instructions:
	1. Update the variables in the SET statements
    2. Run the script

Notes:
	1. If one side shows as all NULL values, then it means that AUD_SEQ_ID had a NULL value for a column while the other AUD_SEQ_ID did not
*/

DECLARE @SCHEMA_NAME NVARCHAR(50), @TABLE_NAME NVARCHAR(100), @FIRST_VALUE BIGINT, @SECOND_VALUE BIGINT, @SCHEMA_TABLE_NAME NVARCHAR(150), @SCHEMA_TABLE_NAME_BRACKETS NVARCHAR(150), @QUERY NVARCHAR(MAX);

SET @SCHEMA_NAME = 'dbo' -- Update schema name if needed
SET @TABLE_NAME = 'green_tripdata_2020-04_Excel' -- Update table name if needed
SET @FIRST_VALUE = 20 -- Replace with the first AUD_SEQ_ID for comparison
SET @SECOND_VALUE = 1000 -- Replace with the second AUD_SEQ_ID for comparison

SET @SCHEMA_TABLE_NAME = CONCAT(@SCHEMA_NAME, '.', @TABLE_NAME) 
SET @SCHEMA_TABLE_NAME_BRACKETS = CONCAT(@SCHEMA_NAME, '.[', @TABLE_NAME, ']')

SET @QUERY = 'with A as (    
select  AUD_SEQ_ID    
 ,   (
      Select  *
      from  ' +  @SCHEMA_TABLE_NAME_BRACKETS + '
      where   AUD_SEQ_ID = pp.AUD_SEQ_ID                            
      for xml auto, type) as X 
from ' +  @SCHEMA_TABLE_NAME_BRACKETS + ' pp 
	)
, B as (    
select  AUD_SEQ_ID        
   ,   X.query(
       ''for $f in ' + @SCHEMA_TABLE_NAME + '/@*          
       return         
       <data  name="{ local-name($f) }" value="{ data($f) }" />      
       '') 
       as X2 from A 
)
,    C as (    

 select B.AUD_SEQ_ID as AUD_SEQ_ID  
   ,   norm.data.value(''@name'', ''nvarchar(max)'') as Name  
   ,   norm.data.value(''@value'', ''nvarchar(max)'') as Value
from B cross apply B.X2.nodes(''/data'') as norm(data)
)


select *
from ( select * from C where 
	AUD_SEQ_ID = TRY_CAST(' + TRY_CAST(@FIRST_VALUE AS NVARCHAR(50)) + ' AS BIGINT)
	) C1
full outer join ( select * from C where
	AUD_SEQ_ID = TRY_CAST(' + TRY_CAST(@SECOND_VALUE AS NVARCHAR(50)) + ' AS BIGINT)
	) C2
    on C1.Name = c2.Name
where c1.Value <> c2.Value 
 or  (c1.Value is null and c2.Value is NOT null)
 or  (c1.Value is NOT null and c2.Value is null)

ORDER BY C1.Name'

EXEC(@QUERY)

