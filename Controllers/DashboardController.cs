using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SampleWebApp.Data;
using SampleWebApp.Models;

namespace SampleWebApp.Controllers;

public class DashboardController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<DashboardController> _logger;

    public DashboardController(ApplicationDbContext context, ILogger<DashboardController> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            var salesData = await _context.SalesData.ToListAsync();

            var model = new DashboardViewModel
            {
                TotalRevenue = salesData.Sum(s => s.Revenue * s.UnitsSold),
                TotalUnitsSold = salesData.Sum(s => s.UnitsSold),
                RecentSales = salesData.OrderByDescending(s => s.SaleDate).Take(10).ToList(),
                RevenueByCategory = salesData
                    .GroupBy(s => s.Category)
                    .ToDictionary(g => g.Key, g => g.Sum(s => s.Revenue * s.UnitsSold)),
                SalesByRegion = salesData
                    .GroupBy(s => s.Region)
                    .ToDictionary(g => g.Key, g => g.Sum(s => s.UnitsSold))
            };

            return View(model);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading dashboard data");
            return View(new DashboardViewModel());
        }
    }
}
