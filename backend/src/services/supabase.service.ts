import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../config/env.js';

let supabaseClient: SupabaseClient | null = null;

export function getSupabase(): SupabaseClient {
  if (!supabaseClient) {
    const key = config.supabase.serviceRoleKey || config.supabase.anonKey;
    supabaseClient = createClient(config.supabase.url, key, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });
  }
  return supabaseClient;
}

export interface StorePaymentConfig {
  store_id: string;
  gateway_provider: 'mercadopago' | 'asaas' | 'pagbank' | 'stripe';
  public_key?: string | null;
  access_token_encrypted?: string | null;
  webhook_secret?: string | null;
  pos_terminal_provider?: string | null;
  pos_device_serial_id?: string | null;
  accepts_online_pix: boolean;
  accepts_online_card: boolean;
  accepts_pos_on_delivery: boolean;
  accepts_cash_on_delivery: boolean;
}

export interface OrderRecord {
  id: string;
  order_number: string;
  customer_id: string;
  store_id: string;
  delivery_address_snapshot: any;
  status: string;
  payment_mode: string;
  payment_status: string;
  external_payment_id?: string | null;
  subtotal: number;
  delivery_fee: number;
  discount: number;
  total_amount: number;
  commission_rate_applied: number;
  platform_commission_amount: number;
  delivery_confirmation_code: string;
  courier_name?: string | null;
  courier_phone?: string | null;
}

export const db = {
  // Lojas e Configuração BYOK
  async getStorePaymentConfig(storeId: string): Promise<StorePaymentConfig | null> {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('store_payment_configs')
      .select('*')
      .eq('store_id', storeId)
      .maybeSingle();

    if (error) {
      console.error(`[DB Error] getStorePaymentConfig storeId=${storeId}:`, error);
      return null;
    }
    return data as StorePaymentConfig;
  },

  // Pedidos
  async getOrderById(orderId: string): Promise<OrderRecord | null> {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('id', orderId)
      .maybeSingle();

    if (error) {
      console.error(`[DB Error] getOrderById orderId=${orderId}:`, error);
      return null;
    }
    return data as OrderRecord;
  },

  async getOrderByNumber(orderNumber: string): Promise<OrderRecord | null> {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('order_number', orderNumber)
      .maybeSingle();

    if (error) {
      console.error(`[DB Error] getOrderByNumber orderNumber=${orderNumber}:`, error);
      return null;
    }
    return data as OrderRecord;
  },

  async updateOrderPaymentStatus(
    orderId: string, 
    paymentStatus: 'paid_directly_to_store' | 'awaiting_payment' | 'failed' | 'refunded',
    externalPaymentId?: string
  ): Promise<boolean> {
    const supabase = getSupabase();
    const updatePayload: any = {
      payment_status: paymentStatus,
      updated_at: new Date().toISOString(),
    };
    if (externalPaymentId) {
      updatePayload.external_payment_id = externalPaymentId;
    }

    const { error } = await supabase
      .from('orders')
      .update(updatePayload)
      .eq('id', orderId);

    if (error) {
      console.error(`[DB Error] updateOrderPaymentStatus orderId=${orderId}:`, error);
      return false;
    }
    return true;
  },

  // Registrar Comissão no Ledger
  async recordCommission(order: OrderRecord): Promise<boolean> {
    const supabase = getSupabase();
    const commissionAmount = Number(((order.total_amount * order.commission_rate_applied) / 100).toFixed(2));

    const { error } = await supabase
      .from('commission_ledger')
      .insert({
        order_id: order.id,
        order_number: order.order_number,
        store_id: order.store_id,
        order_total_amount: order.total_amount,
        commission_rate_applied: order.commission_rate_applied,
        commission_amount: commissionAmount,
      });

    if (error) {
      // Ignora duplicidade se já registrado
      if (error.code === '23505') return true;
      console.error(`[DB Error] recordCommission orderId=${order.id}:`, error);
      return false;
    }
    return true;
  },
};
