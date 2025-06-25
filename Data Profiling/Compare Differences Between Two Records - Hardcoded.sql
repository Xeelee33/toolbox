/*
Script: Compare Differences Between Two Records - Hardcoded.sql
Created by: Joshua Wilshere
Created on: 4/8/24
Adapted from: https://stackoverflow.com/questions/28194628/compare-two-rows-and-identify-columns-whose-values-are-different

Purpose: Compare two records identified by unique ID (AUD_SEQ_ID) and return columns and values that are different

Instructions:
	1. Replace the schema.tablename where instructed (3 places, find and replace all recommended)
		a. dbo.TEST used in template script to make find/replace easier
	2. Update the two AUD_SEQ_IDs to be compared near the bottom

Notes:
	1. If one side shows as all NULL values, then it means that AUD_SEQ_ID had a NULL value for a column while the other AUD_SEQ_ID did not
*/


with A as (    
--  We're going to return the product ID, plus an XML version of the     
--  entire record. 
select  AUD_SEQ_ID    
 ,   (
      Select  *
	  /********* REPLACE SCHEMA.TABLENAME, DO NOT USE [] *********/
      from    dbo.TEST      
      where   AUD_SEQ_ID = pp.AUD_SEQ_ID                            
      for xml auto, type) as X 
	  /********* REPLACE SCHEMA.TABLENAME, DO NOT USE [] *********/
from    dbo.TEST pp 
	)
, B as (    
--  We're going to run an Xml query against the XML field, and transform it    
--  into a series of name-value pairs.  But X2 will still be a single XML    
--  field, associated with this ID.    
select  AUD_SEQ_ID        
   ,   X.query(
		/********* REPLACE SCHEMA.TABLENAME, DO NOT USE [] *********/
       'for $f in dbo.TEST/@*          
       return         
       <data  name="{ local-name($f) }" value="{ data($f) }" />      
       ') 
       as X2 from A 
)
,    C as (    
 --  We're going to run the Nodes function against the X2 field,  splitting     
 --  our list of "data" elements into individual nodes.  We will then use    
 -- the Value function to extract the name and value.   
 select B.AUD_SEQ_ID as AUD_SEQ_ID  
   ,   norm.data.value('@name', 'nvarchar(max)') as Name  
   ,   norm.data.value('@value', 'nvarchar(max)') as Value
from B cross apply B.X2.nodes('/data') as norm(data)
)

-- Select our results.

select *
from ( select * from C where 
	/********* REPLACE FIRST AUD_SEQ_ID FOR COMPARISON *********/
	AUD_SEQ_ID = 6148622
	) C1
full outer join ( select * from C where
	/********* REPLACE SECOND AUD_SEQ_ID FOR COMPARISON *********/
	AUD_SEQ_ID = 6148623
	) C2
    on C1.Name = c2.Name
where c1.Value <> c2.Value 
 or  (c1.Value is null and c2.Value is NOT null)
 or  (c1.Value is NOT null and c2.Value is null)

ORDER BY C1.Name