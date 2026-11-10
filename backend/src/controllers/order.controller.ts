import { Request, Response } from 'express';
import { z } from 'zod';
import { getSupabase, db, StorePaymentConfig } from '../services/supabase.service.js';
import { paymentService } from '../services/payment.service.js';
import { config } from '../config/env.js';

const CheckoutItemSchema = z.object({
  product_id: z.string().uuid(),
  product_name: z.string(),
  quantity: z.number().int().positive(),
  unit_price: z.number().positive(),
  is_refill_only: z.boolean().default(true),
});

const CheckoutPayloadSchema = z.object({
  customer_id: z.string().uuid(),
  store_id: z.string().uuid(),
  customer_name: z.string().default('Cliente BoraGás'),
  customer_email: z.string().email().default('cliente@boragas.com'),
  delivery_address: z.object({
    street: z.string(),
    number: z.string(),
    complement: z.string().optional().nullable(),
    neighborhood: z.string(),
    city: z.string(),
    state: z.string(),
    zip_code: z.string(),
    lat: z.number().optional().nullable(),
    lng: z.number().optional().nullable(),
  }),
  payment_mode: z.enum([
    'online_store_api',
    'pos_machine_push',
    'card_on_delivery',
    'pix_on_delivery',
    'cash_on_delivery',
  ]),
  change_for_amount: z.number().optional().nullable(),
  delivery_fee: z.number().default(0.0),
  discount: z.number().default(0.0),
  items: z.array(CheckoutItemSchema).min(1),
});

export async function createCheckout(req: Request, res: Response) {
  try {
    const parsed = CheckoutPayloadSchema.parse(req.body);

    // 1. Calcular subtotal e total
    const subtotal = parsed.items.reduce((acc, item) => acc + item.unit_price * item.quantity, 0);
    const totalAmount = Math.max(0, subtotal + parsed.delivery_fee - parsed.discount);
    const commissionPercent = config.platform.commissionPercent;
    const commissionAmount = Number(((totalAmount * commissionPercent) / 100).toFixed(2));

    // 2. Gerar número de pedido único e código de confirmação
    const randomSuffix = Math.floor(1000 + Math.random() * 9000);
    const orderNumber = `BG-${randomSuffix}`;
    const confirmationCode = Math.floor(1000 + Math.random() * 9000).toString();

    // 3. Buscar configuração de pagamento BYOK da loja
    const storePaymentConfig = await db.getStorePaymentConfig(parsed.store_id);

    // 4. Salvar pedido no Supabase
    const supabase = getSupabase();
    const orderInsertPayload = {
      order_number: orderNumber,
      customer_id: parsed.customer_id,
      store_id: parsed.store_id,
      delivery_address_snapshot: parsed.delivery_address,
      status: 'accepted',
      payment_mode: parsed.payment_mode,
      payment_status: parsed.payment_mode === 'online_store_api' ? 'awaiting_payment' : 'paid_directly_to_store',
      change_for_amount: parsed.change_for_amount,
      subtotal: Number(subtotal.toFixed(2)),
      delivery_fee: Number(parsed.delivery_fee.toFixed(2)),
      discount: Number(parsed.discount.toFixed(2)),
      total_amount: Number(totalAmount.toFixed(2)),
      commission_rate_applied: commissionPercent,
      platform_commission_amount: commissionAmount,
      delivery_confirmation_code: confirmationCode,
      courier_name: 'Entregador Flash BoraGás',
      courier_phone: '(11) 98765-4321',
    };

    const { data: createdOrder, error: orderError } = await supabase
      .from('orders')
      .insert(orderInsertPayload)
      .select()
      .single();

    if (orderError || !createdOrder) {
      console.error('[Order Controller] Erro ao criar pedido:', orderError);
      return res.status(500).json({ error: 'Falha ao gravar pedido', details: orderError?.message });
    }

    // 5. Inserir itens do pedido
    const orderItemsPayload = parsed.items.map((item) => ({
      order_id: createdOrder.id,
      product_id: item.product_id,
      product_name: item.product_name,
      quantity: item.quantity,
      is_refill_only: item.is_refill_only,
      unit_price: Number(item.unit_price.toFixed(2)),
      total_price: Number((item.unit_price * item.quantity).toFixed(2)),
    }));

    await supabase.from('order_items').insert(orderItemsPayload);

    // 6. Se o pagamento for Online (Pix/Cartão pelo gateway da distribuidora)
    let paymentResult = null;
    if (parsed.payment_mode === 'online_store_api') {
      const activeConfig = storePaymentConfig || {
        store_id: parsed.store_id,
        gateway_provider: 'mercadopago',
        accepts_online_pix: true,
        accepts_online_card: true,
        accepts_pos_on_delivery: true,
        accepts_cash_on_delivery: true,
      };

      paymentResult = await paymentService.createOnlineCharge(
        activeConfig,
        createdOrder,
        parsed.customer_email,
        parsed.customer_name
      );

      // Atualiza o ID externo no pedido
      if (paymentResult.externalPaymentId) {
        await supabase
          .from('orders')
          .update({ external_payment_id: paymentResult.externalPaymentId })
          .eq('id', createdOrder.id);
      }
    } else {
      // Pedido pago diretamente na entrega: registra comissão imediata no Ledger
      await db.recordCommission(createdOrder);
    }

    return res.status(201).json({
      success: true,
      order: createdOrder,
      payment: paymentResult,
      message: 'Pedido gerado com sucesso.',
    });
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Dados inválidos', issues: err.issues });
    }
    console.error('[Order Controller] Exceção:', err);
    return res.status(500).json({ error: 'Erro interno ao processar pedido' });
  }
}

export async function getOrder(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const order = await db.getOrderById(id);

    if (!order) {
      return res.status(404).json({ error: 'Pedido não encontrado' });
    }

    const supabase = getSupabase();
    const { data: items } = await supabase.from('order_items').select('*').eq('order_id', id);

    return res.json({ order, items });
  } catch (err: any) {
    return res.status(500).json({ error: 'Erro ao buscar pedido', message: err.message });
  }
}
