import { Router } from 'express';
import { healthRoutes } from './health.routes.js';
import { orderRoutes } from './order.routes.js';
import { webhookRoutes } from './webhook.routes.js';
import { invoiceRoutes } from './invoice.routes.js';
import { whatsappRoutes } from './whatsapp.routes.js';

export const apiRouter = Router();

apiRouter.use('/health', healthRoutes);
apiRouter.use('/orders', orderRoutes);
apiRouter.use('/webhooks', webhookRoutes);
apiRouter.use('/invoices', invoiceRoutes);
apiRouter.use('/whatsapp', whatsappRoutes);
