import fs from 'fs';
import path from 'path';

const DB_MODE = process.env.DB_MODE || 'postgres';
const DATA_DIR = process.env.SANDBOX_DIR || './.sandbox-data';

let pgPool = null;

async function getPgPool() {
  if (!pgPool) {
    const { Pool } = await import('pg');
    pgPool = new Pool({
      connectionString: process.env.DATABASE_URL,
      max: 5,
    });
    await pgPool.query(`
      CREATE TABLE IF NOT EXISTS calculations (
        id SERIAL PRIMARY KEY,
        num1 DOUBLE PRECISION NOT NULL,
        num2 DOUBLE PRECISION,
        operation VARCHAR(10) NOT NULL,
        result DOUBLE PRECISION,
        error TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);
  }
  return pgPool;
}

const filePath = path.join(DATA_DIR, 'calculations.json');

function fileLoad() {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return [];
  }
}

function fileSave(rows) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(rows, null, 2));
}

export async function query(text, params) {
  if (DB_MODE === 'skip') {
    return { rows: [] };
  }

  if (DB_MODE === 'file') {
    if (text.startsWith('CREATE TABLE')) {
      return { rows: [] };
    }
    if (text.startsWith('INSERT INTO')) {
      const rows = fileLoad();
      rows.push({
        id: rows.length + 1,
        num1: params[0],
        num2: params[1],
        operation: params[2],
        result: params[3],
        error: params[4],
        created_at: new Date().toISOString(),
      });
      fileSave(rows);
      return { rows: [] };
    }
    if (text.startsWith('SELECT')) {
      const rows = fileLoad();
      return { rows: [...rows].reverse().slice(0, 100) };
    }
    if (text.startsWith('DELETE')) {
      fileSave([]);
      return { rows: [] };
    }
    throw new Error(`Unsupported SQL in file mode: ${text.substring(0, 60)}`);
  }

  const pool = await getPgPool();
  const client = await pool.connect();
  try {
    return await client.query(text, params);
  } finally {
    client.release();
  }
}
