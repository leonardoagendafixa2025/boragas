import { Router } from 'express';
import {
  listSupportTickets,
  createSupportTicket,
  addSupportMessage,
  updateSupportTicketStatus,
} from '../controllers/support.controller.js';

export const supportRoutes = Router();

supportRoutes.get('/tickets', listSupportTickets);
supportRoutes.post('/tickets', createSupportTicket);
supportRoutes.post('/tickets/:ticketId/messages', addSupportMessage);
supportRoutes.patch('/tickets/:ticketId/status', updateSupportTicketStatus);
