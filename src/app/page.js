'use client';
import { useState } from 'react';

const btn = { flex: 1, padding: 15, fontSize: '1.2em', border: '1px solid #555', cursor: 'pointer', color: '#fff' };

export default function Home() {
  const [a, setA] = useState(''), [op, setOp] = useState(''), [b, setB] = useState(''), [r, setR] = useState(null);
  const d = r !== null ? r : b || a || '0';

  const num = n => {
    if (r !== null) { setA(n); setR(null); return; }
    if (op) setB(v => v === '0' ? n : v + n);
    else setA(v => v === '0' ? n : v + n);
  };

  const pressOp = o => {
    if (r !== null) { setA(String(r)); setR(null); }
    if (a) setOp(o);
  };

  const eq = async () => {
    if (!a || !b || !op) return;
    const res = await fetch('/api/calculate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ num1: +a, num2: +b, operation: op }),
    });
    const data = await res.json();
    setR(data.error ?? data.result);
  };

  const clr = () => { setA(''); setOp(''); setB(''); setR(null); };

  return (
    <div style={{ width: 260, margin: '50px auto', fontFamily: 'monospace' }}>
      <div style={{
        background: '#222', color: '#0f0', padding: '15px 20px', fontSize: '2em',
        textAlign: 'right', minHeight: 40, border: '1px solid #555',
      }}>{typeof d === 'number' ? d : d}</div>
      <button onClick={clr} style={{ ...btn, background: '#a00', width: '100%' }}>C</button>
      {[
        ['7','8','9','/'],
        ['4','5','6','*'],
        ['1','2','3','-'],
        ['0','=','+'],
      ].map((row, i) => (
        <div key={i} style={{ display: 'flex' }}>
          {row.map(n => (
            <button key={n} onClick={() => n === '=' ? eq() : '+-*/'.includes(n) ? pressOp(n) : num(n)}
              style={{ ...btn, background: n === '=' ? '#060' : '+-*/'.includes(n) ? '#335' : '#444' }}>
              {n}
            </button>
          ))}
        </div>
      ))}
    </div>
  );
}
