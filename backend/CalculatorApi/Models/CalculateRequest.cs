namespace CalculatorApi.Models;

public class CalculateRequest
{
    public double Num1 { get; set; }
    public double? Num2 { get; set; }
    public required string Operation { get; set; }
}
