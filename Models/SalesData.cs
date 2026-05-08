using System.ComponentModel.DataAnnotations;

namespace SampleWebApp.Models;

public class SalesData
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string ProductName { get; set; } = string.Empty;

    [Required]
    [StringLength(50)]
    public string Category { get; set; } = string.Empty;

    public decimal Revenue { get; set; }

    public int UnitsSold { get; set; }

    public DateTime SaleDate { get; set; }

    [StringLength(100)]
    public string Region { get; set; } = string.Empty;
}
