using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CalculatorApi.Data;
using CalculatorApi.Models;

namespace CalculatorApi.Controllers;

[ApiController]
[Route("api")]
public class CalculateController : ControllerBase
{
    private readonly CalcDbContext _db;
    public CalculateController(CalcDbContext db) => _db = db;

    [HttpPost("calculate")]
    public async Task<IActionResult> Calculate([FromBody] CalculateRequest req)
    {
        var record = new CalculationRecord { Num1 = req.Num1, Num2 = req.Num2, Operation = req.Operation };
        try
        {
            var result = (req.Operation switch
            {
                "+" => req.Num1 + req.Num2!.Value,
                "-" => req.Num1 - req.Num2!.Value,
                "*" => req.Num1 * req.Num2!.Value,
                "/" => req.Num2!.Value == 0 ? throw new DivideByZeroException() : req.Num1 / req.Num2.Value,
                "%" => req.Num1 * req.Num2!.Value / 100,
                "^" => Math.Pow(req.Num1, req.Num2!.Value),
                "√" => req.Num1 < 0 ? throw new InvalidOperationException("Invalid input") : Math.Sqrt(req.Num1),
                "x²" => req.Num1 * req.Num1,
                "x⁻¹" => req.Num1 == 0 ? throw new DivideByZeroException() : 1 / req.Num1,
                "sin" => Math.Sin(req.Num1),
                "cos" => Math.Cos(req.Num1),
                "log" => req.Num1 <= 0 ? throw new InvalidOperationException("Invalid input") : Math.Log10(req.Num1),
                _ => throw new InvalidOperationException("Invalid operation"),
            });
            record.Result = result;
            _db.Calculations.Add(record);
            await _db.SaveChangesAsync();
            return Ok(new { result });
        }
        catch (DivideByZeroException)
        {
            record.Error = "Division by zero";
            _db.Calculations.Add(record);
            await _db.SaveChangesAsync();
            return BadRequest(new { error = "Division by zero" });
        }
        catch (InvalidOperationException ex)
        {
            record.Error = ex.Message;
            _db.Calculations.Add(record);
            await _db.SaveChangesAsync();
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory()
    {
        return Ok(await _db.Calculations.OrderByDescending(c => c.CreatedAt).ToListAsync());
    }

    [HttpGet("history/{id}")]
    public async Task<IActionResult> GetHistoryItem(int id)
    {
        var record = await _db.Calculations.FindAsync(id);
        return record is null ? NotFound() : Ok(record);
    }

    [HttpDelete("history")]
    public async Task<IActionResult> ClearHistory()
    {
        _db.Calculations.RemoveRange(_db.Calculations);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
