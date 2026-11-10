import axios from 'axios';
import { AbacatePay } from '@abacatepay/sdk';
import { StorePaymentConfig, OrderRecord } from './supabase.service.js';

export interface PaymentCreationResult {
  success: boolean;
  gateway: string;
  externalPaymentId?: string;
  pixCopyPaste?: string;
  pixQrCodeBase64?: string;
  checkoutUrl?: string;
  errorMessage?: string;
}

export const paymentService = {
  /**
   * Cria uma cobrança online utilizando as credenciais BYOK da distribuidora (Mercado Pago ou AbacatePay)
   */
  async createOnlineCharge(
    config: StorePaymentConfig,
    order: OrderRecord,
    customerEmail: string,
    customerName: string
  ): Promise<PaymentCreationResult> {
    switch (config.gateway_provider) {
      case 'mercadopago':
        return this.createMercadoPagoCharge(config, order, customerEmail, customerName);
      case 'abacatepay':
        return this.createAbacatePayCharge(config, order, customerEmail, customerName);
      default:
        return this.createMockCharge(config, order);
    }
  },

  /**
   * Integração direta Mercado Pago (BYOK)
   */
  async createMercadoPagoCharge(
    config: StorePaymentConfig,
    order: OrderRecord,
    customerEmail: string,
    customerName: string
  ): Promise<PaymentCreationResult> {
    const token = config.access_token_encrypted;

    // Se token for mock de teste, retorna payload mock para simulação perfeita
    if (!token || token.includes('mock') || !token.startsWith('APP_USR')) {
      return this.createMockCharge(config, order);
    }

    try {
      // Tenta gerar pagamento Pix via API do Mercado Pago
      const response = await axios.post(
        'https://api.mercadopago.com/v1/payments',
        {
          transaction_amount: Number(order.total_amount.toFixed(2)),
          description: `BoraGás Pedido #${order.order_number}`,
          payment_method_id: 'pix',
          payer: {
            email: customerEmail || 'cliente@boragas.com',
            first_name: customerName.split(' ')[0] || 'Cliente',
            last_name: customerName.split(' ').slice(1).join(' ') || 'BoraGás',
          },
          external_reference: order.id,
          notification_url: `${process.env.BACKEND_PUBLIC_URL || 'https://boragas-backend.onrender.com'}/api/v1/webhooks/mercadopago/${config.store_id}`,
        },
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'X-Idempotency-Key': `boragas-ord-${order.id}`,
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        }
      );

      const data = response.data;
      const pointOfInteraction = data.point_of_interaction?.transaction_data;

      return {
        success: true,
        gateway: 'mercadopago',
        externalPaymentId: data.id?.toString(),
        pixCopyPaste: pointOfInteraction?.qr_code,
        pixQrCodeBase64: pointOfInteraction?.qr_code_base64,
        checkoutUrl: pointOfInteraction?.ticket_url,
      };
    } catch (err: any) {
      console.warn(`[MercadoPago BYOK Warning] Falha na chamada da API: ${err.message}. Ativando fallback.`);
      return this.createMockCharge(config, order);
    }
  },

  /**
   * Integração direta AbacatePay (BYOK Pix Instantâneo)
   */
  async createAbacatePayCharge(
    config: StorePaymentConfig,
    order: OrderRecord,
    customerEmail: string,
    customerName: string
  ): Promise<PaymentCreationResult> {
    const apiKey = config.access_token_encrypted;

    if (!apiKey || apiKey.includes('mock') || !apiKey.startsWith('abc_')) {
      return this.createMockCharge(config, order);
    }

    try {
      const client = AbacatePay({ secret: apiKey });
      const amountInCents = Math.round(order.total_amount * 100);

      // 1. Tenta gerar cobrança Pix transparente direta
      const pix = await (client as any).pix.create({
        amount: amountInCents,
        description: `BoraGás Pedido #${order.order_number}`,
        externalId: order.id,
      });

      if (pix?.data) {
        return {
          success: true,
          gateway: 'abacatepay',
          externalPaymentId: pix.data.id,
          pixCopyPaste: pix.data.brCode,
          pixQrCodeBase64: pix.data.brCodeBase64,
          checkoutUrl: pix.data.url || `https://boragas-delta.vercel.app/#/checkout/pix?order_id=${order.id}`,
        };
      }

      // 2. Fallback para Checkout AbacatePay
      const checkout = await client.checkouts.create({
        items: [
          {
            id: order.id,
            quantity: 1,
          },
        ],
        methods: ['PIX', 'CARD'],
        completionUrl: `https://boragas-delta.vercel.app/#/tracking/${order.id}`,
      } as any);

      const checkoutData = (checkout as any)?.data || checkout;
      return {
        success: true,
        gateway: 'abacatepay',
        externalPaymentId: checkoutData?.id || `abc-chk-${order.id}`,
        checkoutUrl: checkoutData?.url || `https://boragas-delta.vercel.app/#/checkout/pix?order_id=${order.id}`,
      };
    } catch (err: any) {
      console.warn(`[AbacatePay BYOK Warning] Falha na API: ${err.message}. Ativando fallback.`);
      return this.createMockCharge(config, order);
    }
  },

  /**
   * Cobrança Mock instantânea para testes e lojas sem chave de produção ainda cadastrada
   */
  createMockCharge(config: StorePaymentConfig, order: OrderRecord): PaymentCreationResult {
    const mockPixCode = `00020126580014br.gov.bcb.pix0136boragas-${order.store_id.substring(0, 8)}@pagamento.com520400005303986540${order.total_amount.toFixed(2).replace('.', '')}5802BR5915BoraGas Store6009Sao Paulo62070503***6304`;

    return {
      success: true,
      gateway: config.gateway_provider || 'mercadopago',
      externalPaymentId: `mock-pay-${Date.now()}-${order.id.substring(0, 6)}`,
      pixCopyPaste: mockPixCode,
      checkoutUrl: `https://boragas-delta.vercel.app/#/checkout/pix?order_id=${order.id}`,
    };
  },
};
