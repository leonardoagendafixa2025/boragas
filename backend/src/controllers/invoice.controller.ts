import { Request, Response } from 'express';
import { getSupabase } from '../services/supabase.service.js';
import { commissionService } from '../services/commission.service.js';

export async function getStoreInvoices(req: Request, res: Response) {
  try {
    const storeId = req.params.storeId as string;
    const supabase = getSupabase();

    const { data: invoices, error } = await supabase
      .from('commission_invoices')
      .select('*')
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    const summary = await commissionService.getStoreCommissionSummary(storeId);

    return res.json({
      invoices,
      pendingSummary: summary,
    });
  } catch (err: any) {
    return res.status(500).json({ error: 'Erro ao buscar faturas', message: err.message });
  }
}

export async function generateInvoice(req: Request, res: Response) {
  try {
    const { store_id, period, commission_percent } = req.body;

    if (!store_id || !period) {
      return res.status(400).json({ error: 'store_id e period são obrigatórios' });
    }

    const result = await commissionService.generateInvoice(
      store_id,
      period,
      commission_percent ? parseFloat(commission_percent) : 8.0
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    return res.status(201).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: 'Erro ao gerar fatura', message: err.message });
  }
}
