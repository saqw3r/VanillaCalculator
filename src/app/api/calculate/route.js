import { query } from '../../../lib/db';

export async function POST(req) {
  const { num1, num2, operation } = await req.json();
  const a = Number(num1);
  const b = num2 !== undefined ? Number(num2) : undefined;

  let result, error;
  try {
    switch (operation) {
      case '+': result = a + b; break;
      case '-': result = a - b; break;
      case '*': result = a * b; break;
      case '/':
        if (b === 0) throw new Error('Division by zero');
        result = a / b; break;
      case '%': result = a * b / 100; break;
      case '^': result = Math.pow(a, b); break;
      case '√':
        if (a < 0) throw new Error('Invalid input');
        result = Math.sqrt(a); break;
      case 'x²': result = a * a; break;
      case 'x⁻¹':
        if (a === 0) throw new Error('Division by zero');
        result = 1 / a; break;
      case 'sin': result = Math.sin(a); break;
      case 'cos': result = Math.cos(a); break;
      case 'log':
        if (a <= 0) throw new Error('Invalid input');
        result = Math.log10(a); break;
      default: throw new Error('Invalid operation');
    }
  } catch (e) {
    error = e.message;
  }

  try {
    await query(
      `INSERT INTO calculations (num1, num2, operation, result, error) VALUES ($1, $2, $3, $4, $5)`,
      [a, b ?? null, operation, result ?? null, error ?? null]
    );
  } catch {}

  if (error) return Response.json({ error }, { status: 400 });
  return Response.json({ result });
}
