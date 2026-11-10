import { getSupabase } from './supabase.service.js';

export const commissionService = {
  /**
   * Calcula o resumo de comissões pendentes de uma loja
   */
  async getStoreCommissionSummary(storeId: string) {
    const supabase = getSupabase();

    const { data: ledgerEntries, error } = await supabase
      .from('commission_ledger')
      .select('commission_amount, order_total_amount')
      .eq('store_id', storeId);

    if (error) {
      console.error(`[Commission Error] getStoreCommissionSummary storeId=${storeId}:`, error);
      return { totalSales: 0, totalCommissionDue: 0, ordersCount: 0 };
    }

    const totalSales = (ledgerEntries || []).reduce((acc, row) => acc + Number(row.order_total_amount || 0), 0);
    const totalCommissionDue = (ledgerEntries || []).reduce((acc, row) => acc + Number(row.commission_amount || 0), 0);

    return {
      totalSales: Number(totalSales.toFixed(2)),
      totalCommissionDue: Number(totalCommissionDue.toFixed(2)),
      ordersCount: (ledgerEntries || []).length,
    };
  },

  /**
   * Gera uma nova fatura de comissão para a loja
   */
  async generateInvoice(storeId: string, periodText: string, commissionPercent: number = 8.0) {
    const supabase = getSupabase();
    const summary = await this.getStoreCommissionSummary(storeId);

    if (summary.totalCommissionDue <= 0) {
      return { success: false, message: 'Nenhuma comissão pendente encontrada para este período.' };
    }

    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 5); // Vencimento em 5 dias

    const pixKey = `00020126580014br.gov.bcb.pix0136boragas-faturas@plataforma.com520400005303986540${summary.totalCommissionDue.toFixed(2).replace('.', '')}5802BR5915BoraGas Admin6009Sao Paulo62070503***6304`;

    const { data, error } = await supabase
      .from('commission_invoices')
      .insert({
        store_id: storeId,
        period: periodText,
        total_store_sales: summary.totalSales,
        commission_percent: commissionPercent,
        total_commission_due: summary.totalCommissionDue,
        due_date: dueDate.toISOString().split('T')[0],
        status: 'open',
        pix_copy_paste: pixKey,
      })
      .select()
      .single();

    if (error) {
      console.error(`[Commission Error] generateInvoice storeId=${storeId}:`, error);
      return { success: false, error: error.message };
    }

    return { success: true, invoice: data };
  },
};
