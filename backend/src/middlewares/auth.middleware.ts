import { Request, Response, NextFunction } from 'express';
import { getSupabase } from '../services/supabase.service.js';

export interface AuthenticatedUser {
  id: string;
  email?: string;
  role?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // Se estiver em modo de teste/desenvolvimento e for mock explícito, aceita com log de aviso
    if (process.env.NODE_ENV !== 'production' && req.headers['x-mock-user-id']) {
      req.user = {
        id: req.headers['x-mock-user-id'] as string,
        email: (req.headers['x-mock-user-email'] as string) || 'mock@boragas.app',
        role: (req.headers['x-mock-user-role'] as string) || 'customer',
      };
      return next();
    }

    return res.status(401).json({
      error: 'Não autorizado: Token de autenticação ausente ou inválido.',
      code: 'UNAUTHORIZED',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const supabase = getSupabase();
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({
        error: 'Sessão inválida ou expirada. Faça login novamente.',
        code: 'INVALID_TOKEN',
      });
    }

    // Busca o role na tabela profiles
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

    req.user = {
      id: user.id,
      email: user.email,
      role: profile?.role || 'customer',
    };

    next();
  } catch (err: any) {
    console.error('[Auth Middleware Error]:', err.message);
    return res.status(500).json({ error: 'Erro ao validar autenticação.' });
  }
}

export function requireRole(allowedRoles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Autenticação necessária.' });
    }

    if (!allowedRoles.includes(req.user.role || '')) {
      return res.status(403).json({
        error: `Acesso negado: Perfil '${req.user.role}' não possui permissão para esta operação.`,
        code: 'FORBIDDEN',
      });
    }

    next();
  };
}
