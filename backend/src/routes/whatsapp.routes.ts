import { Router } from 'express';
import {
  getWhatsAppStatus,
  renderWhatsAppQrView,
  sendWhatsAppMessage,
  triggerOrderWhatsAppNotification,
  reconnectWhatsApp,
} from '../controllers/whatsapp.controller.js';

export const whatsappRoutes = Router();

whatsappRoutes.get('/status', getWhatsAppStatus);
whatsappRoutes.get('/qr', renderWhatsAppQrView);
whatsappRoutes.post('/send', sendWhatsAppMessage);
whatsappRoutes.post('/notify-order', triggerOrderWhatsAppNotification);
whatsappRoutes.post('/reconnect', reconnectWhatsApp);
