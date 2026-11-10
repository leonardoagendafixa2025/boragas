import { Router } from 'express';
import { createCheckout, getOrder, updateOrderStatus } from '../controllers/order.controller.js';

export const orderRoutes = Router();

orderRoutes.post('/checkout', createCheckout);
orderRoutes.get('/:id', getOrder);
orderRoutes.patch('/:id/status', updateOrderStatus);

