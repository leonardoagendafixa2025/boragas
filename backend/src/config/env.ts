import dotenv from 'dotenv';
import path from 'path';

// Carrega o arquivo .env
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '10000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  frontendUrl: process.env.FRONTEND_URL || 'https://boragas-delta.vercel.app',
  supabase: {
    url: process.env.SUPABASE_URL || 'https://elkelrotleuyszmtkbye.supabase.co',
    anonKey: process.env.SUPABASE_ANON_KEY || 'sb_publishable_2ic-HESrCJHYoCk_XNyN2Q_j5zuxKDc',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || '',
  },
  platform: {
    commissionPercent: parseFloat(process.env.PLATFORM_COMMISSION_PERCENT || '8.0'),
    defaultCommissionRate: parseFloat(process.env.DEFAULT_COMMISSION_RATE || '8.0'),
  },
};
