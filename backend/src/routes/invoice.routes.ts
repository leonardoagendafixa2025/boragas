import { Router } from 'express';
import { getStoreInvoices, generateInvoice } from '../controllers/invoice.controller.js';

export const invoiceRoutes = Router();

invoiceRoutes.get('/store/:storeId', getStoreInvoices);
invoiceRoutes.post('/generate', generateInvoice);
