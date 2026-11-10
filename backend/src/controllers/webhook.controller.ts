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

export async function handleAsaasWebhook(req: Request, res: Response) {
  const { storeId } = req.params;
  const body = req.body || {};

  console.log(`[Webhook Asaas] Recebido para Loja ${storeId}:`, body.event);

  try {
    const event = body.event;
    const payment = body.payment || {};
    const externalRef = payment.externalReference;
    const paymentId = payment.id;

    if (event === 'PAYMENT_RECEIVED' || event === 'PAYMENT_CONFIRMED') {
      const supabase = getSupabase();
      let order = null;

      if (externalRef) {
        const { data } = await supabase.from('orders').select('*').eq('id', externalRef).maybeSingle();
        order = data;
      } else if (paymentId) {
        const { data } = await supabase.from('orders').select('*').eq('external_payment_id', paymentId).maybeSingle();
        order = data;
      }

      if (order) {
        await db.updateOrderPaymentStatus(order.id, 'paid_directly_to_store', paymentId);
        await db.recordCommission(order);
        console.log(`[Webhook Asaas] Pedido #${order.order_number} confirmado!`);
      }
    }

    return res.status(200).json({ status: 'received' });
  } catch (err: any) {
    console.error('[Webhook Asaas] Erro:', err);
    return res.status(200).json({ status: 'error_logged' });
  }
}
