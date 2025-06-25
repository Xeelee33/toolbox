/*
Script: Step 2 - Create and Populate Table Profile Meta Table - AllChar.sql
Created by: Joshua Wilshere
Created on: 11/2/23

Purpose: Creates, or if exists, populates a schema and table called meta.TABLES_PROFILES with a basic profile of the named table

Instructions: 
	1. Update the table name in the SET @TABLE_NAME line below
	2. Confirm the schema name in @SCHEMA_NAME
	3. Execute
	4. If needed, add a USE YOUR_DATABASE_NAME; directly below this commend block and above the DECLARE statement
	5. To customize the output further, tweak the SELECT * FROM #PROFILE_TABLE at the very end of this script

Documentation/Notes:
	1. sp_executesql Documentation: --https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-executesql-transact-sql?view=sql-server-ver16
*/

USE SANDBOX
GO

-- Comment this statement for enhanced troubleshooting if needed
SET NOCOUNT ON
GO

DECLARE @TABLE_NAME NVARCHAR(100), @SCHEMA_NAME NVARCHAR(50), @TABLE_OBJECT_ID BIGINT, @COLUMN_ID INT, @COLUMN_NAME NVARCHAR(255), @MAX_LEN_QUERY NVARCHAR(500), 
		@MIN_LEN_QUERY NVARCHAR(500), @NULL_COUNT_QUERY NVARCHAR(500), @BLANK_COUNT_QUERY NVARCHAR(500), @DISTINCT_COUNT_QUERY NVARCHAR(500),
		@COUNTER INT, @COLUMN_COUNT INT, @DATATYPE NVARCHAR(50), @MAX_LEN BIGINT, @MIN_LEN BIGINT,
		@NULL_COUNT BIGINT, @BLANK_COUNT BIGINT, @DISTINCT_COUNT BIGINT, @ParmDefinition NVARCHAR(100), @SCHEMA_TABLE_NAME NVARCHAR(150),
		@NUMERIC_VALUE_COUNT_QUERY NVARCHAR(500), @NUMERIC_VALUE_COUNT BIGINT, @TOTAL_RECORD_COUNT_QUERY NVARCHAR(500), @TOTAL_RECORD_COUNT BIGINT,
		@MAX_LEN_VALUE_QUERY NVARCHAR(500), @MAX_LEN_VALUE NVARCHAR(MAX), @ParmDefinitionString NVARCHAR(100), @PRECISION_VALUE_QUERY NVARCHAR(500),
		@SCALE_VALUE_QUERY NVARCHAR(500), @PRECISION_VALUE BIGINT, @SCALE_VALUE BIGINT;

/*************** UPDATE @TABLE_NAME AND CONFIRM SCHEMA BELOW ***************/
SET @TABLE_NAME = '[green_tripdata_2020-04_Excel_AllChar]'

SET @SCHEMA_NAME = 'dbo'

/*************** EXECUTE SCRIPT ***************/

-- Initialize values for other variables
SET @SCHEMA_TABLE_NAME = CONCAT('[',@SCHEMA_NAME, '].[', @TABLE_NAME, ']')
SET @TABLE_OBJECT_ID = OBJECT_ID(@SCHEMA_TABLE_NAME)
SET @COUNTER = 1
SET @COLUMN_COUNT = (SELECT COUNT(*) from sys.columns where object_id = @TABLE_OBJECT_ID);
SET @ParmDefinition = N'@valueOUT bigint OUTPUT'
SET @ParmDefinitionString = N'@stringOUT NVARCHAR(MAX) OUTPUT'

-- Create local meta table to hold and output profile results if it doesn't exist
IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'meta' )
    EXEC('CREATE SCHEMA [meta] AUTHORIZATION [dbo]');

IF OBJECT_ID('meta.TABLE_PROFILES','U') IS NULL
	CREATE TABLE meta.TABLE_PROFILES ([SCHEMA_NAME] NVARCHAR(50), TABLE_NAME NVARCHAR(100), COLUMN_ID BIGINT, COLUMN_NAME NVARCHAR(255), DATATYPE NVARCHAR(50), 
														MAX_LEN BIGINT, MAX_LEN_VALUE NVARCHAR(MAX), MIN_LEN BIGINT, NULL_COUNT BIGINT, BLANK_COUNT BIGINT, NUMERIC_VALUE_COUNT BIGINT, 
														MAX_PRECISION BIGINT, MAX_SCALE BIGINT, DISTINCT_COUNT BIGINT, TOTAL_RECORD_COUNT BIGINT);

-- Delete any existing records from the profile table for the table being profiled
IF EXISTS (SELECT TOP 1 * FROM meta.TABLE_PROFILES WHERE [SCHEMA_NAME] = @SCHEMA_NAME AND [TABLE_NAME] = @TABLE_NAME)
	DELETE FROM meta.TABLE_PROFILES  WHERE [SCHEMA_NAME] = @SCHEMA_NAME AND [TABLE_NAME] = @TABLE_NAME;

SET @TOTAL_RECORD_COUNT_QUERY =  'SELECT @valueOUT = COUNT(1) FROM ' + @SCHEMA_TABLE_NAME
EXEC sp_executesql @TOTAL_RECORD_COUNT_QUERY, @ParmDefinition, @valueOUT = @TOTAL_RECORD_COUNT OUTPUT;

-- Loop through all columns in the table and profile them
WHILE @COUNTER <= @COLUMN_COUNT
BEGIN
-- Get column name, id, and data type
	SELECT TOP 1
    @COLUMN_NAME = CONCAT('[', c.name, ']'),
	@COLUMN_ID = c.column_id,
	@DATATYPE =  
		CASE
			WHEN LOWER(t.Name) in ('nvarchar', 'nchar') and c.max_length = -1
				THEN CONCAT(UPPER(t.name), '(MAX)')
			WHEN LOWER(t.Name) in ('nvarchar', 'nchar') and c.max_length != -1
				THEN CONCAT(UPPER(t.name), '(', c.max_length/2, ')')
			WHEN t.name like '%char%'
				THEN CONCAT(UPPER(t.name), '(', c.max_length, ')')
			WHEN LOWER(t.Name) in ('numeric', 'decimal', 'money', 'smallmoney')
				THEN CONCAT(UPPER(t.name), '(', c.precision, ',', c.scale, ')')
			ELSE UPPER(t.name)
		END
	FROM    
		sys.columns c
	INNER JOIN 
		sys.types t ON c.user_type_id = t.user_type_id
	LEFT OUTER JOIN 
		sys.index_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
	LEFT OUTER JOIN 
		sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
	WHERE
		c.object_id = @TABLE_OBJECT_ID
		--AND c.name NOT LIKE 'AUD_%'
		and c.column_id = @COUNTER;

-- Declare the queries for the profile outputs
	SET @MAX_LEN_QUERY = 'SELECT @valueOUT = ISNULL(MAX(LEN(' + @COLUMN_NAME + ')),0) FROM ' + @SCHEMA_TABLE_NAME
	SET @MIN_LEN_QUERY = 'SELECT @valueOUT = ISNULL(MIN(LEN(' + @COLUMN_NAME + ')),0) FROM ' + @SCHEMA_TABLE_NAME
	SET @NULL_COUNT_QUERY = 'SELECT @valueOUT = COUNT(1) FROM ' + @SCHEMA_TABLE_NAME + ' WHERE ' + @COLUMN_NAME + ' IS NULL'
	SET @BLANK_COUNT_QUERY = 'SELECT @valueOUT = COUNT(1) FROM ' + @SCHEMA_TABLE_NAME + ' WHERE LTRIM(RTRIM(' + @COLUMN_NAME + ')) = '''''
	SET @DISTINCT_COUNT_QUERY = 'SELECT @valueOUT = COUNT(DISTINCT(' + @COLUMN_NAME + ')) FROM ' + @SCHEMA_TABLE_NAME
    -- ISNUMERIC requires a string datatype, so will return error if numeric or date datatypes are fed in
	-- Converts NULL values to 0 for purposes of determining whether non-NULL values are all numeric
	IF @DATATYPE LIKE '%char%'
	BEGIN
		SET @NUMERIC_VALUE_COUNT_QUERY = 'SELECT @valueOUT = COUNT(ISNULL(' + @COLUMN_NAME + ','''')) FROM  ' + @SCHEMA_TABLE_NAME + ' WHERE ISNUMERIC(ISNULL(' + @COLUMN_NAME + ',''''))=1'	    --SET @NUMERIC_VALUE_COUNT_QUERY = 'SELECT @valueOUT = COUNT(ISNULL(' + @COLUMN_NAME + ',0)) FROM  ' + @SCHEMA_TABLE_NAME + ' WHERE ISNUMERIC(ISNULL(' + @COLUMN_NAME + ',0))=1'
		-- Determines the max PRECISION and SCALE of strings that look like decimals
		SET @PRECISION_VALUE_QUERY = 'SELECT @valueOUT = MAX(LEN(PARSENAME(REPLACE(' + @COLUMN_NAME + ', ''-'',''''), 2)) + LEN(PARSENAME(REPLACE(' + @COLUMN_NAME + ', ''-'',''''), 1))) FROM  ' + @SCHEMA_TABLE_NAME + ' WHERE ISNUMERIC(ISNULL(' + @COLUMN_NAME + ',0))=1 AND CHARINDEX(''.'', ' + @COLUMN_NAME + ') != 0'
		SET @SCALE_VALUE_QUERY = 'SELECT @valueOUT = MAX(LEN(PARSENAME(REPLACE(' + @COLUMN_NAME + ', ''-'',''''), 1))) FROM  ' + @SCHEMA_TABLE_NAME + ' WHERE ISNUMERIC(ISNULL(' + @COLUMN_NAME + ',0))=1 AND CHARINDEX(''.'', ' + @COLUMN_NAME + ') != 0'
	END

-- Execute the queries and assign the output to the profile variables
	EXEC sp_executesql @MAX_LEN_QUERY, @ParmDefinition, @valueOUT = @MAX_LEN OUTPUT;
	EXEC sp_executesql @MIN_LEN_QUERY, @ParmDefinition, @valueOUT = @MIN_LEN OUTPUT;
	EXEC sp_executesql @NULL_COUNT_QUERY, @ParmDefinition, @valueOUT = @NULL_COUNT OUTPUT;
	EXEC sp_executesql @BLANK_COUNT_QUERY, @ParmDefinition, @valueOUT = @BLANK_COUNT OUTPUT;
	EXEC sp_executesql @DISTINCT_COUNT_QUERY, @ParmDefinition, @valueOUT = @DISTINCT_COUNT OUTPUT;
	
	IF @DATATYPE LIKE '%char%'
	BEGIN
		EXEC sp_executesql @NUMERIC_VALUE_COUNT_QUERY, @ParmDefinition, @valueOUT = @NUMERIC_VALUE_COUNT OUTPUT;
		EXEC sp_executesql @PRECISION_VALUE_QUERY, @ParmDefinition, @valueOUT = @PRECISION_VALUE OUTPUT;
		EXEC sp_executesql @SCALE_VALUE_QUERY, @ParmDefinition, @valueOUT = @SCALE_VALUE OUTPUT;
	END
	ELSE 
	BEGIN
		SET @NUMERIC_VALUE_COUNT = NULL
		SET @PRECISION_VALUE = NULL
		SET @SCALE_VALUE = NULL
	END

-- Set the max length value to NULL if the column is 100% NULL
	IF @MAX_LEN > 0
	BEGIN
		SET @MAX_LEN_VALUE_QUERY = 'SELECT TOP 1 @stringOUT = TRY_CAST(' + @COLUMN_NAME + ' AS NVARCHAR(MAX)) FROM ' + @SCHEMA_TABLE_NAME + ' WHERE LEN(' + @COLUMN_NAME + ') = ' + TRY_CAST(@MAX_LEN AS NVARCHAR(20))
		EXEC sp_executesql @MAX_LEN_VALUE_QUERY, @ParmDefinitionString, @stringOUT = @MAX_LEN_VALUE OUTPUT;
	END

	IF @MAX_LEN = 0
		SET @MAX_LEN_VALUE = NULL

-- Populate row of the profile table with all the necessary values for the column
	INSERT INTO meta.TABLE_PROFILES([SCHEMA_NAME], TABLE_NAME, COLUMN_ID, COLUMN_NAME, DATATYPE, MAX_LEN, MAX_LEN_VALUE, MIN_LEN, 
														NULL_COUNT, BLANK_COUNT, NUMERIC_VALUE_COUNT, MAX_PRECISION, MAX_SCALE, DISTINCT_COUNT, TOTAL_RECORD_COUNT)
	VALUES (@SCHEMA_NAME, @TABLE_NAME, @COLUMN_ID, @COLUMN_NAME, @DATATYPE, @MAX_LEN, @MAX_LEN_VALUE, @MIN_LEN, 
			@NULL_COUNT, @BLANK_COUNT, @NUMERIC_VALUE_COUNT, @PRECISION_VALUE, @SCALE_VALUE, @DISTINCT_COUNT, @TOTAL_RECORD_COUNT)

-- Increment counter to go to next column
	SET @COUNTER = @COUNTER + 1
END

-- Display results
SELECT * 
FROM meta.TABLE_PROFILES
WHERE [SCHEMA_NAME] = @SCHEMA_NAME
AND [TABLE_NAME] = @TABLE_NAME
ORDER BY COLUMN_ID