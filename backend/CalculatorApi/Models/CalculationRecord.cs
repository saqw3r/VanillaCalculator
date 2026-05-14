namespace CalculatorApi.Models;

public class CalculationRecord
{
    public int Id { get; set; }
    public double Num1 { get; set; }
    public double? Num2 { get; set; }
    public required string Operation { get; set; }
    public double? Result { get; set; }
    public string? Error { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
