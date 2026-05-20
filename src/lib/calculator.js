export function calculate(num1, num2, operation) {
  const a = Number(num1);
  const b = num2 !== undefined ? Number(num2) : undefined;

  switch (operation) {
    case '+':
      if (b === undefined) throw new Error('Missing operand');
      return a + b;
    case '-':
      if (b === undefined) throw new Error('Missing operand');
      return a - b;
    case '*':
      if (b === undefined) throw new Error('Missing operand');
      return a * b;
    case '/':
      if (b === undefined) throw new Error('Missing operand');
      if (b === 0) throw new Error('Division by zero');
      return a / b;
    case '%':
      if (b === undefined) throw new Error('Missing operand');
      return a * b / 100;
    case '^':
      if (b === undefined) throw new Error('Missing operand');
      return Math.pow(a, b);
    case '√':
      if (a < 0) throw new Error('Invalid input');
      return Math.sqrt(a);
    case 'x²':
      return a * a;
    case 'x⁻¹':
      if (a === 0) throw new Error('Division by zero');
      return 1 / a;
    case 'sin':
      return Math.sin(a);
    case 'cos':
      return Math.cos(a);
    case 'log':
      if (a <= 0) throw new Error('Invalid input');
      return Math.log10(a);
    default:
      throw new Error('Invalid operation');
  }
}
