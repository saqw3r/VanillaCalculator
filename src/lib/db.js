import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 5,
});

let initialized = false;

export async function query(text, params) {
  if (!initialized) {
    await pool.query(`
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
    initialized = true;
  }
  const client = await pool.connect();
  try {
    return await client.query(text, params);
  } finally {
    client.release();
  }
}
