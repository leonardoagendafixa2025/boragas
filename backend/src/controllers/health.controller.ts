import { Request, Response } from 'express';
import { getSupabase } from '../services/supabase.service.js';

export async function healthCheck(req: Request, res: Response) {
  const startTime = Date.now();
  let dbStatus = 'healthy';
  let dbLatencyMs = 0;

  try {
    const supabase = getSupabase();
    const dbStart = Date.now();
    const { error } = await supabase.from('remote_configs').select('key').limit(1);
    dbLatencyMs = Date.now() - dbStart;

    if (error) {
      dbStatus = `degraded: ${error.message}`;
    }
  } catch (err: any) {
    dbStatus = `error: ${err.message}`;
  }

  const responsePayload = {
    service: 'boragas-backend',
    status: dbStatus.startsWith('error') ? 'degraded' : 'ok',
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    database: {
      provider: 'supabase',
      status: dbStatus,
      latencyMs: dbLatencyMs,
    },
    version: '1.0.0',
  };

  return res.status(dbStatus.startsWith('error') ? 503 : 200).json(responsePayload);
}
