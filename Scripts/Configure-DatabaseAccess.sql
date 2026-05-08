-- Run this script in Azure SQL Database (SampleDB) to grant access to the web app
-- You can run this using Azure Portal Query Editor or Azure Data Studio

-- Create user for the web app's Managed Identity
CREATE USER [myapp-web-5233] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [myapp-web-5233];
ALTER ROLE db_datawriter ADD MEMBER [myapp-web-5233];
ALTER ROLE db_ddladmin ADD MEMBER [myapp-web-5233];

-- Verify the user was created
SELECT name, type_desc FROM sys.database_principals WHERE name = 'myapp-web-5233';
