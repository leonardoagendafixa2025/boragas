import { Router } from 'express';
import { createCheckout, getOrder } from '../controllers/order.controller.js';

export const orderRoutes = Router();

orderRoutes.post('/checkout', createCheckout);
orderRoutes.get('/:id', getOrder);
