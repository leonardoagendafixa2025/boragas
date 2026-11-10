import { Request, Response } from 'express';
import { db, getSupabase } from '../services/supabase.service.js';

export async function handleMercadoPagoWebhook(req: Request, res: Response) {
  const { storeId } = req.params;
  const body = req.body || {};
  const query = req.query || {};

  console.log(`[Webhook MercadoPago] Recebido para Loja ${storeId}:`, JSON.stringify({ body, query }));

  try {
    const paymentId = body.data?.id || body.id || query['data.id'] || query.id;
    const action = body.action || body.type;

    // Responde 200 rápido para a API do Mercado Pago
    if (!paymentId) {
      return res.status(200).json({ status: 'ignored_no_payment_id' });
    }

    const supabase = getSupabase();

    // 1. Localizar o pedido pelo external_payment_id ou external_reference
    let { data: order } = await supabase
      .from('orders')
      .select('*')
      .eq('external_payment_id', paymentId.toString())
      .maybeSingle();

    if (!order && body.external_reference) {
      const { data: orderByRef } = await supabase
        .from('orders')
        .select('*')
        .eq('id', body.external_reference)
        .maybeSingle();
      order = orderByRef;
    }

    if (order) {
      // 2. Se o status for aprovado / pago
      const isApproved =
        action === 'payment.created' ||
        action === 'payment.updated' ||
        body.status === 'approved' ||
        body.status === 'paid';

      if (isApproved) {
        await db.updateOrderPaymentStatus(order.id, 'paid_directly_to_store', paymentId.toString());
        await db.recordCommission(order);
        console.log(`[Webhook MercadoPago] Pedido #${order.order_number} confirmado com sucesso!`);
      }
    }

    return res.status(200).json({ status: 'success', processed: Boolean(order) });
  } catch (err: any) {
    console.error('[Webhook MercadoPago] Erro ao processar:', err);
    // Sempre retorna 200 para evitar que o gateway fique retentando indefinidamente em caso de erro interno
    return res.status(200).json({ status: 'error_logged' });
  }
}

export async function handleAbacatePayWebhook(req: Request, res: Response) {
  const { storeId } = req.params;
  const body = req.body || {};

  console.log(`[Webhook AbacatePay] Recebido para Loja ${storeId}:`, body.event || body.type);

  try {
    const event = body.event || body.type;
    const data = body.data || body;
    const externalId = data.externalId || data.metadata?.orderId;
    const paymentId = data.id || data.pixId;

    // Eventos de sucesso no AbacatePay
    if (event === 'billing.paid' || event === 'pix.paid' || data.status === 'PAID') {
      const supabase = getSupabase();
      let order = null;

      if (externalId) {
        const { data: orderData } = await supabase.from('orders').select('*').eq('id', externalId).maybeSingle();
        order = orderData;
      } else if (paymentId) {
        const { data: orderData } = await supabase.from('orders').select('*').eq('external_payment_id', paymentId).maybeSingle();
        order = orderData;
      }

      if (order) {
        await db.updateOrderPaymentStatus(order.id, 'paid_directly_to_store', paymentId);
        await db.recordCommission(order);
        console.log(`[Webhook AbacatePay] Pedido #${order.order_number} confirmado com sucesso via Pix!`);
      }
    }

    return res.status(200).json({ status: 'received' });
  } catch (err: any) {
    console.error('[Webhook AbacatePay] Erro:', err);
    return res.status(200).json({ status: 'error_logged' });
  }
}
