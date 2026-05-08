-- Sample SQL Script to manually create and populate the database
-- This is an alternative to using EF Core migrations

-- Create the SalesData table
CREATE TABLE SalesData (
    Id INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Revenue DECIMAL(18, 2) NOT NULL,
    UnitsSold INT NOT NULL,
    SaleDate DATETIME2 NOT NULL,
    Region NVARCHAR(100) NOT NULL
);

-- Insert sample data
INSERT INTO SalesData (ProductName, Category, Revenue, UnitsSold, SaleDate, Region) VALUES
('Laptop Pro', 'Electronics', 1299.99, 45, DATEADD(day, -30, GETDATE()), 'North America'),
('Wireless Mouse', 'Accessories', 29.99, 320, DATEADD(day, -25, GETDATE()), 'Europe'),
('Mechanical Keyboard', 'Accessories', 89.99, 150, DATEADD(day, -20, GETDATE()), 'Asia'),
('4K Monitor', 'Electronics', 449.99, 78, DATEADD(day, -15, GETDATE()), 'North America'),
('USB-C Hub', 'Accessories', 49.99, 210, DATEADD(day, -10, GETDATE()), 'Europe'),
('Gaming Headset', 'Electronics', 129.99, 95, DATEADD(day, -5, GETDATE()), 'Asia'),
('Webcam HD', 'Electronics', 79.99, 185, DATEADD(day, -8, GETDATE()), 'North America'),
('Laptop Stand', 'Accessories', 39.99, 140, DATEADD(day, -12, GETDATE()), 'Europe'),
('External SSD 1TB', 'Electronics', 149.99, 98, DATEADD(day, -18, GETDATE()), 'Asia'),
('Wireless Charger', 'Accessories', 34.99, 275, DATEADD(day, -22, GETDATE()), 'North America');

-- Verify the data
SELECT * FROM SalesData ORDER BY SaleDate DESC;

-- Summary queries
SELECT 
    Category,
    SUM(Revenue * UnitsSold) AS TotalRevenue,
    SUM(UnitsSold) AS TotalUnits
FROM SalesData
GROUP BY Category
ORDER BY TotalRevenue DESC;

SELECT 
    Region,
    COUNT(*) AS NumberOfSales,
    SUM(UnitsSold) AS TotalUnits
FROM SalesData
GROUP BY Region
ORDER BY TotalUnits DESC;
