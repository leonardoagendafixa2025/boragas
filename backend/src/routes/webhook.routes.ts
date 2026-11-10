import { Router } from 'express';
import { handleMercadoPagoWebhook, handleAsaasWebhook } from '../controllers/webhook.controller.js';

export const webhookRoutes = Router();

// Webhook Mercado Pago por Loja
webhookRoutes.post('/mercadopago/:storeId', handleMercadoPagoWebhook);

// Webhook Asaas por Loja
webhookRoutes.post('/asaas/:storeId', handleAsaasWebhook);
