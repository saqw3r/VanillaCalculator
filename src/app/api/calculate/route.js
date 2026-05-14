export async function POST(req) {
  const { num1, num2, operation } = await req.json();
  await new Promise(r => setTimeout(r, 300));
  const a = Number(num1), b = num2 !== undefined ? Number(num2) : undefined;

  switch (operation) {
    case '+': return Response.json({ result: a + b });
    case '-': return Response.json({ result: a - b });
    case '*': return Response.json({ result: a * b });
    case '/':
      if (b === 0) return Response.json({ error: 'Division by zero' }, { status: 400 });
      return Response.json({ result: a / b });
    case '%': return Response.json({ result: a * b / 100 });
    case '^': return Response.json({ result: Math.pow(a, b) });
    case '√':
      if (a < 0) return Response.json({ error: 'Invalid input' }, { status: 400 });
      return Response.json({ result: Math.sqrt(a) });
    case 'x²': return Response.json({ result: a * a });
    case 'x⁻¹':
      if (a === 0) return Response.json({ error: 'Division by zero' }, { status: 400 });
      return Response.json({ result: 1 / a });
    case 'sin': return Response.json({ result: Math.sin(a) });
    case 'cos': return Response.json({ result: Math.cos(a) });
    case 'log':
      if (a <= 0) return Response.json({ error: 'Invalid input' }, { status: 400 });
      return Response.json({ result: Math.log10(a) });
    default:
      return Response.json({ error: 'Invalid operation' }, { status: 400 });
  }
}
