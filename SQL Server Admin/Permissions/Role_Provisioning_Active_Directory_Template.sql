/*
    Script: Perms_servername_databasename.sql
    Created by: Joshua Wilshere
    Created on: 


Instructions:
(Recommended)
0. Save a copy of this script reflecting the server and database name
    Ex: Perms_SERVER_NAME_01_DATABASE_NAME.sql
(Mandatory)
1. Change or confirm the value for @DATABASE
2. Confirm all the necessary roles and grant statements exist in ##roles
    Ex: ('rl_analyst_view', 'GRANT SELECT, REFERENCES, VIEW DEFINITION')
    NOTE - If you add an additional role here, make sure you add a heading template to Step 3
3. Uncomment/add/update assignedRoles and userNames
    Ex: ('rl_analyst_view', 'DOMAIN_PREFIX\username')
    NOTE - If you add an additional role here, make sure you add a heading template to Step 3
4. Execute
*/

-- Comment below for enhanced troubleshooting if needed
SET NOCOUNT ON
GO
/************************** INITIALIZATION SECTION **************************/

-- Declare the necessary variables
DECLARE @USER NVARCHAR(225), @DATABASE NVARCHAR(50), @TOPROLE NVARCHAR(50), @ROLENAME NVARCHAR(50), @CREATELOGON NVARCHAR(500), 
@CREATEUSER NVARCHAR(500), @CONNECTUSER NVARCHAR(500), @CREATEROLE NVARCHAR(500), @ROLEGRANT NVARCHAR(500),@ASSIGNROLE NVARCHAR(500),
@ROLEDISCOVERY NVARCHAR(2000), @CONFLICTROLE NVARCHAR(50), @USERDISCOVERY NVARCHAR(500), @ASSIGNSCHEMA NVARCHAR(500);

-- Checks for existing temporary tables used by this script and drops any that exist
IF OBJECT_ID('tempdb..##userNameTable') IS NOT NULL DROP TABLE ##userNameTable;
IF OBJECT_ID('tempdb..##roles') IS NOT NULL DROP TABLE ##roles;
IF OBJECT_ID('tempdb..##createRoleTable') IS NOT NULL DROP TABLE ##createRoleTable;
IF OBJECT_ID('tempdb..##createStatements') IS NOT NULL DROP TABLE ##createStatements;
IF OBJECT_ID('tempdb..##roleConflictTable') IS NOT NULL DROP TABLE ##roleConflictTable;
IF OBJECT_ID('tempdb..##roleDropStatements') IS NOT NULL DROP TABLE ##roleDropStatements;
IF OBJECT_ID('tempdb..##dropUserTable') IS NOT NULL DROP TABLE ##dropUserTable;

-- Creates GLOBAL temporary table ##userNameTable
CREATE TABLE ##userNameTable ( assignedRole nvarchar(50) NOT NULL, userName nvarchar(225) NOT NULL);
-- Creates GLOBAL temporary table ##roles
CREATE TABLE ##roles (roleName nvarchar(50) NOT NULL, roleRights nvarchar(250) NOT NULL);
-- Creates GLOBAL temporary table ##roleDropStatements
CREATE TABLE ##roleDropStatements (roleDrop nvarchar(250) NOT NULL);


/************************** MAKE MODIFICATIONS IN THIS SECTION **************************/

-- Step 1. Confirm the database to run the script against
SET @DATABASE = 'ChangeMe'

/* Step 2. Confirm that the below roles meet the needs, or add addtional roles and GRANT statements as needed
    NOTE - If you add an additional role here, make sure you add a heading template to Step 3 */
INSERT INTO ##roles 
    (roleName, roleRights)
VALUES
	('rl_tableau_view', 'GRANT SELECT, REFERENCES, VIEW DEFINITION'),
    ('rl_analyst_view', 'GRANT SELECT, REFERENCES, VIEW DEFINITION, SHOWPLAN'),
    ('rl_data_analyst_full', 'GRANT SELECT, REFERENCES, VIEW DEFINITION, ALTER, DELETE, EXECUTE, INSERT, UPDATE, SHOWPLAN'),
    ('rl_data_architect', 'GRANT SELECT, REFERENCES, VIEW DEFINITION, ALTER, CONTROL, DELETE, EXECUTE, INSERT, UPDATE, SHOWPLAN'),
    ('rl_data_analyst_create_views', 'GRANT SELECT, REFERENCES, VIEW DEFINITION, CREATE VIEW, EXECUTE, SHOWPLAN'),
    ('rl_execute_scripts', 'GRANT SELECT, EXECUTE ANY EXTERNAL SCRIPT'),
    ('rl_investigator_view', 'GRANT SELECT, REFERENCES, VIEW DEFINITION, SHOWPLAN'),
	('rl_investigator_full', 'GRANT SELECT, REFERENCES, VIEW DEFINITION, ALTER, DELETE, EXECUTE, INSERT, UPDATE, SHOWPLAN'),
	('rl_informatica_user', 'GRANT SELECT, EXECUTE, DELETE, INSERT, VIEW DEFINITION, REFERENCES, UPDATE, ALTER');


/* Step 3. Copy and paste the appropriate role templates under the relevant section and add the username after the \
    Example: 
    VALUES
    -- ('rl_analyst_view', 'DOMAIN_PREFIX\'),
    ('rl_analyst_view','DOMAIN_PREFIX\username'),
    -- ('rl_investigator_view', 'DOMAIN_PREFIX\'),
    ('rl_investigator_view', 'DOMAIN_PREFIX\username')
    ;
    Inserts assignedRoles and userNames into temporary table ##userNameTable */
INSERT INTO ##userNameTable
	(assignedRole, userName)
VALUES
-- ('rl_tableau_view', 'DOMAIN_PREFIX\'),
	('rl_tableau_view', 'DOMAIN_PREFIX\Tableau Service Account Group'),                        /* Tableau Service Accounts - READ */
    
-- ('rl_analyst_view', 'DOMAIN_PREFIX\'),
    ('rl_analyst_view', 'DOMAIN_PREFIX\username1'),
	-- ('rl_analyst_view', 'DOMAIN_PREFIX\AD GROUP NAME 1'),            /* Senior Staff - READ */
	-- ('rl_analyst_view', 'DOMAIN_PREFIX\AD GROUP NAME 2'),       /* Analyst Staff  - READ */
	-- ('rl_analyst_view', 'DOMAIN_PREFIX\AD GROUP NAME 3'),  /* Analyst Contractors  - READ */

-- ('rl_data_analyst_create_views', 'DOMAIN_PREFIX\'),
	-- ('rl_data_analyst_create_views', 'DOMAIN_PREFIX\AD GROUP NAME 2'),       /* Analyst Staff  - READ ALL, CREATE VIEWS ONLY*/
	-- ('rl_data_analyst_create_views', 'DOMAIN_PREFIX\AD GROUP NAME 3'),  /* Analyst Contractors  - READ, CREATE VIEWS ONLY */

-- ('rl_data_analyst_full', 'DOMAIN_PREFIX\'),
	-- ('rl_data_analyst_full', 'DOMAIN_PREFIX\AD GROUP NAME 2'),          /* Analyst Staff - WRITE */
	-- ('rl_data_analyst_full', 'DOMAIN_PREFIX\AD GROUP NAME 3'),    /* Analyst Contractors - WRITE */

-- ('rl_data_architect', 'DOMAIN_PREFIX\'),
	('rl_data_architect', 'DOMAIN_PREFIX\AD GROUP NAME 4'),           /* Architect Staff - WRITE */
	('rl_data_architect', 'DOMAIN_PREFIX\AD GROUP NAME 5'),     /* Architect Contractors - WRITE */
    
-- ('rl_investigator_view', 'DOMAIN_PREFIX\'),
    -- ('rl_investigator_view', 'DOMAIN_PREFIX\username2'),
    -- ('rl_investigator_view', 'DOMAIN_PREFIX\username3'),
    -- ('rl_investigator_view', 'DOMAIN_PREFIX\username4'),

-- ('rl_investigator_full', 'DOMAIN_PREFIX\'),
    -- ('rl_investigator_full', 'DOMAIN_PREFIX\username2'),

-- ('rl_informatica_user', 'DOMAIN_PREFIX\InformaticaServiceAccount')
-- This adds the Informatica SQL Server connection account to the database. Do not add named users to this role.
	('rl_informatica_user', 'DOMAIN_PREFIX\InformaticaServiceAccount')
;

/************************** STEP 4. EXECUTE **************************/

/* Consolidates all roles from the #userNameTable with a username associated with it
   into GLOBAL temporary table ##createRoleTable
    If a requested role doesn't exist in the database, creates it
    Grants privilages to the database role as defined in the ##roles table
*/
SELECT DISTINCT(u.assignedRole) as validRole, r.roleRights
INTO ##createRoleTable
FROM ##userNameTable u
JOIN ##roles r
ON u.assignedRole = r.roleName

WHILE EXISTS (SELECT 1 FROM ##createRoleTable)
    BEGIN
        SELECT TOP 1
            @TOPROLE = validRole
            ,@CREATEROLE = 'USE ' + @DATABASE + '; IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE [type] = ''R'' AND name = ''' + validRole + ''') BEGIN CREATE ROLE ' + validRole + '; END'
            ,@ROLEGRANT = 'USE ' + @DATABASE + '; ' + roleRights + ' TO ' + validRole + ';'
        FROM ##createRoleTable

        EXEC(@CREATEROLE)
        EXEC(@ROLEGRANT)

        DELETE ##createRoleTable
            WHERE @TOPROLE = validRole
    END

/* 
Creates and populates GLOBAL temporary table ##createStatements with all the necessary SQL Statements to provision a user and add them to a role:
    CreateLoginStatement: Creates a domain login account on the SQL Server instance if the user does not have an existing login
    CreateUserStatement: Creates a user account for the database if the user does not already have an account
    GrantConnectStatement: Grants CONNECT privilages on the database to the user account
    AssignRoleStatement: Assigns the user account to the uncommented role if the user is not already assigned to that role
    AssignDefaultSchema: Sets the user account or user group with [dbo] as the default schema.

Each row of the table corresponds to a single user or group

*/

SELECT 
    userName  -- Included for the PRINT statement in the following WHILE loop
    ,assignedRole
    ,CreateLoginStatement = 'IF NOT EXISTS (SELECT LOGINNAME FROM MASTER.DBO.SYSLOGINS WHERE NAME = ''' + userName + ''') BEGIN CREATE LOGIN ' + QUOTENAME(userName) + ' FROM WINDOWS; END'
    ,CreateUserStatement = 'USE ' + @DATABASE + '; IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE [type] IN (''U'', ''G'') AND name = ''' + userName + ''') BEGIN CREATE USER ' + QUOTENAME(userName) + ' FOR LOGIN ' + QUOTENAME(userName) + '; END'
    ,GrantConnectStatement = 'USE ' + @DATABASE + '; GRANT CONNECT TO ' + QUOTENAME(userName) + ';'
    ,AssignRoleStatement = 'USE ' + @DATABASE + '; IF IS_ROLEMEMBER(''' + assignedRole + ''',''' + userName + ''') = 0 BEGIN EXEC sp_addrolemember ''' + assignedRole + ''', ''' + userName + '''; END '
    ,AssignDefaultSchema = 'USE ' + @DATABASE + '; ALTER USER [' + userName + '] WITH DEFAULT_SCHEMA=[dbo];'

INTO ##createStatements
FROM ##userNameTable
    
-- Loops through the ##createStatements table with each iteration representing a single user
-- 1. Selects the top row of the ##createStatements table
-- 2. Assigns each of the statements from the returns row into the corresponding variables
-- 3. Executes each of the variables in turn (Create the login, Create the user, Grant CONNECT, Assign the user to a role)
-- 4. Prints out a confirmation statement
--      Note - This statement will print even if the user was not properly added to the role.
-- 5. Deletes the row currently in use from ##createStatements
-- 6. Back to step 1 until there are no more rows in ##createStatements, thus, no more users to provision
WHILE EXISTS (SELECT 1 FROM ##createStatements)
BEGIN
	SELECT TOP 1 @USER = userName
	,@ROLENAME = assignedRole
    ,@CREATELOGON = CreateLoginStatement
    ,@CREATEUSER = CreateUserStatement
    ,@CONNECTUSER = GrantConnectStatement
    ,@ASSIGNROLE = AssignRoleStatement
    ,@ASSIGNSCHEMA = AssignDefaultSchema
	FROM ##createStatements

	EXEC (@CREATELOGON)
    EXEC (@CREATEUSER)
    EXEC (@CONNECTUSER)
    EXEC (@ASSIGNROLE)
    EXEC (@ASSIGNSCHEMA)

    PRINT @USER + ' added to the ' + @ROLENAME + ' role on the ' + @DATABASE + ' database.'

	DELETE ##createStatements
	    WHERE AssignRoleStatement = @ASSIGNROLE
END

-- Check for conflicting roles

INSERT INTO ##roleDropStatements (roleDrop)
VALUES  ('--Examine and run the necessary statements below to remove and drop authorized users'),
        ('/************ DROP USERS FROM ROLES ************/');

SET @ROLEDISCOVERY = '
WITH RoleMembers (member_principal_id, role_principal_id) 
AS 
(
  SELECT 
   rm1.member_principal_id, 
   rm1.role_principal_id
  FROM ' + @DATABASE + '.sys.database_role_members rm1 (NOLOCK)
   UNION ALL
  SELECT 
   d.member_principal_id, 
   rm.role_principal_id
  
  FROM ' + @DATABASE + '.sys.database_role_members rm (NOLOCK)
   INNER JOIN RoleMembers AS d 
   ON rm.member_principal_id = d.role_principal_id
)
select distinct rp.name as existingRole, mp.name as databaseUser, un.assignedRole
into ##roleConflictTable
from RoleMembers drm
  join ' + @DATABASE + '.sys.database_principals rp on (drm.role_principal_id = rp.principal_id)
  join ' + @DATABASE + '.sys.database_principals mp on (drm.member_principal_id = mp.principal_id)
  left outer join ##userNameTable un on (un.userName = mp.name and rp.name = un.assignedRole)
where un.assignedRole IS NULL
and mp.name != ''dbo''
order by rp.name'

EXEC(@ROLEDISCOVERY)

WHILE EXISTS (SELECT 1 FROM ##roleConflictTable)
	BEGIN
		SELECT TOP 1
			@USER = databaseUser
			,@CONFLICTROLE = existingRole
			FROM ##roleConflictTable;

        INSERT INTO ##roleDropStatements (roleDrop)
		VALUES('EXEC ' +@DATABASE + '..sp_droprolemember ''' + @CONFLICTROLE + ''', ''' + @USER + ''';');

		DELETE FROM ##roleConflictTable 
			WHERE databaseUser = @USER
			AND existingRole = @CONFLICTROLE;
	END

-- Check for users no longer assigned to a role that should be dropped

INSERT INTO ##roleDropStatements (roleDrop)
VALUES  ('/************ DROP USERS FROM DATABASE ************/');

SET @USERDISCOVERY = '
select princ.name as dropUser
into ##dropUserTable
from ' + @DATABASE +'.sys.database_principals princ
where LOWER(princ.name) like ''DOMAIN_PREFIX\%''
and LOWER(princ.name) not in (select lower(userName) from ##userNameTable);'

EXEC(@USERDISCOVERY)

WHILE EXISTS (SELECT 1 FROM ##dropUserTable)
    BEGIN
        SELECT TOP 1
            @USER = dropUser
        FROM ##dropUserTable;

        INSERT INTO ##roleDropStatements (roleDrop)
        VALUES('USE ' +@DATABASE + '; DROP USER [' + @USER + '];');

        DELETE FROM ##dropUserTable
            WHERE dropUser = @USER;
    END

INSERT INTO ##roleDropStatements (roleDrop)
VALUES  ('DROP TABLE ##roleDropStatements;'),
        ('DROP TABLE ##dropUserTable;');

-- Prints out a SQL Query that a user can copy and paste into a second query window to confirm that 
--  the users were properly assigned to the right role and generate drop statements if they are not
PRINT ''
PRINT N'To get list of ' + @DATABASE + N' users assigned to defined roles run the below query in a new window.'
PRINT N'****************************************************************************************'
PRINT N''
PRINT N'USE ' + @DATABASE + ';
WITH RoleMembers (member_principal_id, role_principal_id) 
AS 
(
  SELECT 
   rm1.member_principal_id, 
   rm1.role_principal_id
  FROM sys.database_role_members rm1 (NOLOCK)
   UNION ALL
  SELECT 
   d.member_principal_id, 
   rm.role_principal_id
  FROM sys.database_role_members rm (NOLOCK)
   INNER JOIN RoleMembers AS d 
   ON rm.member_principal_id = d.role_principal_id
)
select distinct rp.name as database_role, mp.name as database_user
from RoleMembers drm
  join sys.database_principals rp on (drm.role_principal_id = rp.principal_id)
  join sys.database_principals mp on (drm.member_principal_id = mp.principal_id)
where 
    mp.name like ''DOMAIN_PREFIX\%''
 --   and
 --   rp.name like ''rl_%''
order by rp.name, mp.name;

SELECT * FROM ##roleDropStatements;'

-- Drops the temporary tables so that the script can be easily run again on the same database
DROP TABLE ##createRoleTable;
DROP TABLE ##roles;
DROP TABLE ##userNameTable;
DROP TABLE ##createStatements;
GO