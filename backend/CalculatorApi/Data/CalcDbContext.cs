using Microsoft.EntityFrameworkCore;
using CalculatorApi.Models;

namespace CalculatorApi.Data;

public class CalcDbContext : DbContext
{
    public CalcDbContext(DbContextOptions<CalcDbContext> opts) : base(opts) { }
    public DbSet<CalculationRecord> Calculations => Set<CalculationRecord>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<CalculationRecord>(e =>
        {
            e.ToTable("Calculations");
            e.HasKey(r => r.Id);
            e.Property(r => r.Id).ValueGeneratedOnAdd();
            e.Property(r => r.CreatedAt).HasDefaultValueSql("NOW()");
        });
    }
}
