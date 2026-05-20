import { calculate } from '../../../lib/calculator';
import { query } from '../../../lib/db';

export async function POST(req) {
  const { num1, num2, operation } = await req.json();

  let result, error;
  try {
    result = calculate(num1, num2, operation);
  } catch (e) {
    error = e.message;
  }

  try {
    await query(
      `INSERT INTO calculations (num1, num2, operation, result, error) VALUES ($1, $2, $3, $4, $5)`,
      [Number(num1), num2 ?? null, operation, result ?? null, error ?? null]
    );
  } catch {}

  if (error) return Response.json({ error }, { status: 400 });
  return Response.json({ result });
}
