-- Run this script in Azure SQL Database (SampleDB) to grant access to the web app
-- Server: myapp-sql-8522.database.windows.net
-- Database: SampleDB
-- Resource Group: rg-test-ntt-vnet

-- Create user for the web app's Managed Identity
CREATE USER [myapp-web-2840] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [myapp-web-2840];
ALTER ROLE db_datawriter ADD MEMBER [myapp-web-2840];
ALTER ROLE db_ddladmin ADD MEMBER [myapp-web-2840];

-- Verify the user was created
SELECT name, type_desc FROM sys.database_principals WHERE name = 'myapp-web-2840';
