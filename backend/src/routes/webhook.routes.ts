import { Router } from 'express';
import { handleMercadoPagoWebhook, handleAbacatePayWebhook } from '../controllers/webhook.controller.js';

export const webhookRoutes = Router();

// Webhook Mercado Pago por Loja
webhookRoutes.post('/mercadopago/:storeId', handleMercadoPagoWebhook);

// Webhook AbacatePay por Loja
webhookRoutes.post('/abacatepay/:storeId', handleAbacatePayWebhook);
