namespace SampleWebApp.Models;

public class DashboardViewModel
{
    public decimal TotalRevenue { get; set; }
    public int TotalUnitsSold { get; set; }
    public List<SalesData> RecentSales { get; set; } = new();
    public Dictionary<string, decimal> RevenueByCategory { get; set; } = new();
    public Dictionary<string, int> SalesByRegion { get; set; } = new();
}
