export async function POST(req) {
  const { num1, num2, operation } = await req.json();
  await new Promise(r => setTimeout(r, 300));
  const a = Number(num1), b = Number(num2);
  switch (operation) {
    case '+': return Response.json({ result: a + b });
    case '-': return Response.json({ result: a - b });
    case '*': return Response.json({ result: a * b });
    case '/':
      if (b === 0) return Response.json({ error: 'Division by zero' }, { status: 400 });
      return Response.json({ result: a / b });
    default:
      return Response.json({ error: 'Invalid operation' }, { status: 400 });
  }
}
