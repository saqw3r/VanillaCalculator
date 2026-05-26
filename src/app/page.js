'use client';
import { useState, useEffect, useRef } from 'react';

const C = '#F7F2EC', D = '#ECE1D9', U = '#E6D9CF', O = '#D6CAD6', S = '#C4B4C4', A = '#B8A9C9', T = '#3D3D3D';
const API_BASE = process.env.NEXT_PUBLIC_API_URL;

export default function Home() {
  const [a, setA] = useState(''), [op, setOp] = useState(''), [b, setB] = useState('');
  const [r, setR] = useState(null), [loading, setLoading] = useState(false);
  const [mem, setMem] = useState(null);
  const mounted = useRef(true);

  useEffect(() => { mounted.current = true; return () => { mounted.current = false; }; }, []);

  const disp = r !== null ? (typeof r === 'number' ? r : r) : b || a || '0';
  const expr = r !== null ? (op ? `${a} ${op} ${b} =` : '') : op ? `${a} ${op}${b ? ' ' + b : ''}` : '';

  const num = n => {
    if (r !== null) { setA(n); setB(''); setOp(''); setR(null); return; }
    if (n === '.') {
      if (op) { if (!b.includes('.')) setB(v => v === '' ? '0.' : v + '.'); }
      else { if (!a.includes('.')) setA(v => v === '' ? '0.' : v + '.'); }
    } else {
      if (op) setB(v => v === '0' ? n : v + n);
      else setA(v => v === '0' ? n : v + n);
    }
  };

  const pressOp = o => { if (r !== null) { setA(String(r)); setB(''); setR(null); } if (a) setOp(o); };

  const eq = async () => {
    if (!a || !b || !op || loading) return;
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/calculate`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ num1: +a, num2: +b, operation: op }),
      });
      const data = await res.json();
      if (mounted.current) { setR(data.error ?? data.result); setLoading(false); }
    } catch { if (mounted.current) setLoading(false); }
  };

  const unary = async fn => {
    if (loading) return;
    const val = r !== null ? +r : +(b || a || '0');
    if (!val && val !== 0) return;
    if (val === 0 && fn === 'x⁻¹') { setR('Division by zero'); return; }
    if (val <= 0 && (fn === '√' || fn === 'log')) { setR('Invalid input'); return; }
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/calculate`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ num1: val, operation: fn }),
      });
      const data = await res.json();
      if (mounted.current) {
        if (data.error) { setR(data.error); }
        else { setA(String(data.result)); setOp(''); setB(''); setR(data.result); }
        setLoading(false);
      }
    } catch { if (mounted.current) setLoading(false); }
  };

  const clr = () => { setA(''); setOp(''); setB(''); setR(null); };

  const neg = () => {
    if (r !== null) { setA(String(-r)); setB(''); setOp(''); setR(null); }
    else if (op && b) setB(v => v.startsWith('-') ? v.slice(1) : '-' + v);
    else if (!op && a) setA(v => v.startsWith('-') ? v.slice(1) : '-' + v);
  };

  const back = () => {
    if (r !== null) { clr(); return; }
    if (op && b) setB(v => v.length > 1 ? v.slice(0, -1) : '');
    else if (!op && a) setA(v => v.length > 1 ? v.slice(0, -1) : '');
  };

  const cur = () => r !== null ? +r : +(b || a || '0');
  const ms = () => setMem(cur());
  const mPlus = () => setMem(m => (m ?? 0) + cur());
  const mMinus = () => setMem(m => (m ?? 0) - cur());
  const mr = () => { if (mem !== null) { setA(String(mem)); setOp(''); setB(''); setR(null); } };
  const mc = () => setMem(null);

  const hRef = useRef();

  hRef.current = e => {
    if (e.ctrlKey || e.altKey || e.metaKey) return;
    if (e.key >= '0' && e.key <= '9') { num(e.key); return; }
    if (e.key === '.') { num('.'); return; }
    if ('+-*/%^'.includes(e.key)) { pressOp(e.key); return; }
    if (e.key === 'Enter' || e.key === '=') { e.preventDefault(); eq(); return; }
    if (e.key === 'Backspace') { e.preventDefault(); back(); return; }
    if (e.key === 'Escape' || e.key === 'Delete') { clr(); return; }
  };

  useEffect(() => {
    const h = e => hRef.current(e);
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, []);

  const R = [
    [['MC',mc,U],['MR',mr,U],['MS',ms,U],['M+',mPlus,U]],
    [['M-',mMinus,U],['sin',()=>unary('sin'),O],['cos',()=>unary('cos'),O],['log',()=>unary('log'),O]],
    [['%',()=>pressOp('%'),O],['√',()=>unary('√'),O],['x²',()=>unary('x²'),O],['^',()=>pressOp('^'),O]],
    [['1/x',()=>unary('x⁻¹'),U],['⌫',back,U],['C',clr,U],['±',neg,U]],
    [['7',()=>num('7'),D],['8',()=>num('8'),D],['9',()=>num('9'),D],['/',()=>pressOp('/'),O]],
    [['4',()=>num('4'),D],['5',()=>num('5'),D],['6',()=>num('6'),D],['*',()=>pressOp('*'),O]],
    [['1',()=>num('1'),D],['2',()=>num('2'),D],['3',()=>num('3'),D],['-',()=>pressOp('-'),O]],
    [['.',()=>num('.'),D],['0',()=>num('0'),D],['=',eq,A],['+',()=>pressOp('+'),O]],
  ];

  return (
    <>
      <style>{`
        body{margin:0;background:#FCF8F4;display:flex;min-height:100vh;align-items:center;justify-content:center;font-family:system-ui,-apple-system,sans-serif}
        .b{transition:all .1s;border:none;border-radius:10px;cursor:pointer;color:${T};font-size:1em;padding:12px 0;box-shadow:0 1px 3px rgba(0,0,0,.04);-webkit-tap-highlight-color:transparent}
        .b:active{transform:scale(.93);opacity:.75}
        .b:disabled{opacity:.5;cursor:default}
        .b:disabled:active{transform:none}
      `}</style>
      <div style={{width:310}}>
        <div style={{
          background:'#FFFCF8',borderRadius:16,padding:'16px 20px',marginBottom:10,wordBreak:'break-word',
          minHeight:80,display:'flex',flexDirection:'column',justifyContent:'flex-end',
          boxShadow:'0 4px 16px rgba(0,0,0,.05)',
        }}>
          <div style={{fontSize:'.75em',color:A,minHeight:18,fontWeight:500,display:'flex',justifyContent:'space-between',width:'100%'}}>
            <span>{mem !== null ? 'M' : ''}</span>
            <span>{expr}</span>
          </div>
          <div style={{fontSize:'1.8em',fontWeight:600,lineHeight:1.2,color:T,textAlign:'right',width:'100%'}}>
            {loading ? '...' : disp}
          </div>
        </div>
        <div style={{display:'flex',flexDirection:'column',gap:6}}>
          {R.map((row,i)=>(
            <div key={i} style={{display:'flex',gap:6}}>
              {row.map(([l,fn,bg,f])=>{
                const sel=l.length===1&&'+-*/%^'.includes(l)&&l===op;
                return <button key={l} onClick={fn} disabled={l==='='&&loading} className="b"
                  style={{flex:f||1,background:sel?S:bg,fontWeight:sel||l==='='?700:400,fontSize:l==='1/x'?'.8em':'1em'}}>{l}</button>;
              })}
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
