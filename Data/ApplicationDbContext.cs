using Microsoft.EntityFrameworkCore;
using SampleWebApp.Models;

namespace SampleWebApp.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<SalesData> SalesData { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Seed some sample data
        modelBuilder.Entity<SalesData>().HasData(
            new SalesData
            {
                Id = 1,
                ProductName = "Laptop Pro",
                Category = "Electronics",
                Revenue = 1299.99m,
                UnitsSold = 45,
                SaleDate = DateTime.Now.AddDays(-30),
                Region = "North America"
            },
            new SalesData
            {
                Id = 2,
                ProductName = "Wireless Mouse",
                Category = "Accessories",
                Revenue = 29.99m,
                UnitsSold = 320,
                SaleDate = DateTime.Now.AddDays(-25),
                Region = "Europe"
            },
            new SalesData
            {
                Id = 3,
                ProductName = "Mechanical Keyboard",
                Category = "Accessories",
                Revenue = 89.99m,
                UnitsSold = 150,
                SaleDate = DateTime.Now.AddDays(-20),
                Region = "Asia"
            },
            new SalesData
            {
                Id = 4,
                ProductName = "4K Monitor",
                Category = "Electronics",
                Revenue = 449.99m,
                UnitsSold = 78,
                SaleDate = DateTime.Now.AddDays(-15),
                Region = "North America"
            },
            new SalesData
            {
                Id = 5,
                ProductName = "USB-C Hub",
                Category = "Accessories",
                Revenue = 49.99m,
                UnitsSold = 210,
                SaleDate = DateTime.Now.AddDays(-10),
                Region = "Europe"
            },
            new SalesData
            {
                Id = 6,
                ProductName = "Gaming Headset",
                Category = "Electronics",
                Revenue = 129.99m,
                UnitsSold = 95,
                SaleDate = DateTime.Now.AddDays(-5),
                Region = "Asia"
            }
        );
    }
}
