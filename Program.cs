using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.EntityFrameworkCore;
using SampleWebApp.Data;
using SampleWebApp.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

// Configure Azure Key Vault
var keyVaultUri = builder.Configuration["AzureKeyVault:VaultUri"];
if (!string.IsNullOrEmpty(keyVaultUri))
{
    var credential = new DefaultAzureCredential();
    var secretClient = new SecretClient(new Uri(keyVaultUri), credential);
    builder.Services.AddSingleton(secretClient);
}

// Register Key Vault Service
builder.Services.AddScoped<IKeyVaultService, KeyVaultService>();

// Configure Database Context
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (connectionString == "UseInMemoryDatabase")
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseInMemoryDatabase("SampleDB"));
}
else
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseSqlServer(connectionString));
}

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// Ensure database is created and seeded
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    
    // Create database schema if it doesn't exist
    context.Database.EnsureCreated();
    
    // Log database initialization
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    logger.LogInformation("Database initialized successfully");
}

app.Run();
