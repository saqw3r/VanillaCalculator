import { query } from '../../../lib/db';

export async function GET() {
  try {
    const { rows } = await query(
      'SELECT * FROM calculations ORDER BY created_at DESC LIMIT 100'
    );
    return Response.json(rows);
  } catch {
    return Response.json([]);
  }
}

export async function DELETE() {
  try {
    await query('DELETE FROM calculations');
  } catch {}
  return new Response(null, { status: 204 });
}
