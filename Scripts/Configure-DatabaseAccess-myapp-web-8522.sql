-- Run this in Azure Portal Query Editor for database: SampleDB
-- Server: myapp-sql-8522.database.windows.net

-- Create user for the web app's Managed Identity
CREATE USER [myapp-web-8522] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [myapp-web-8522];
ALTER ROLE db_datawriter ADD MEMBER [myapp-web-8522];
ALTER ROLE db_ddladmin ADD MEMBER [myapp-web-8522];

-- Verify the user was created
SELECT name, type_desc FROM sys.database_principals WHERE name = 'myapp-web-8522';
