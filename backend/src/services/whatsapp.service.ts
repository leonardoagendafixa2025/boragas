import makeWASocket, {
  DisconnectReason,
  useMultiFileAuthState,
  WASocket,
  ConnectionState,
} from '@whiskeysockets/baileys';
import { Boom } from '@hapi/boom';
import QRCode from 'qrcode';
import pino from 'pino';
import path from 'path';
import fs from 'fs';

export type WhatsAppConnectionStatus = 'disconnected' | 'connecting' | 'qr_ready' | 'connected';

export interface WhatsAppStatusInfo {
  status: WhatsAppConnectionStatus;
  connectedPhone: string | null;
  qrCodeRaw: string | null;
  qrCodeBase64: string | null;
  lastConnectedAt: string | null;
}

class WhatsAppService {
  private sock: WASocket | null = null;
  private status: WhatsAppConnectionStatus = 'disconnected';
  private connectedPhone: string | null = null;
  private qrCodeRaw: string | null = null;
  private qrCodeBase64: string | null = null;
  private lastConnectedAt: string | null = null;
  private isInitializing: boolean = false;
  private sessionDir: string;

  constructor() {
    this.sessionDir = path.resolve(process.cwd(), 'sessions/whatsapp_session');
    // Garante que o diretório de sessões existe
    if (!fs.existsSync(this.sessionDir)) {
      fs.mkdirSync(this.sessionDir, { recursive: true });
    }
  }

  /**
   * Inicializa o cliente Baileys
   */
  async initialize(): Promise<void> {
    if (this.isInitializing || this.status === 'connected') {
      return;
    }

    this.isInitializing = true;
    this.status = 'connecting';
    console.log('🤖 [Baileys WhatsApp] Inicializando socket...');

    try {
      const { state, saveCreds } = await useMultiFileAuthState(this.sessionDir);

      const logger = pino({ level: 'silent' });

      this.sock = makeWASocket({
        auth: state,
        logger,
        printQRInTerminal: true,
        browser: ['BoraGás Bot', 'Chrome', '1.0.0'],
        syncFullHistory: false,
      });

      // Atualizações de credenciais
      this.sock.ev.on('creds.update', saveCreds);

      // Atualizações de conexão
      this.sock.ev.on('connection.update', async (update: Partial<ConnectionState>) => {
        const { connection, lastDisconnect, qr } = update;

        if (qr) {
          this.qrCodeRaw = qr;
          try {
            this.qrCodeBase64 = await QRCode.toDataURL(qr);
            this.status = 'qr_ready';
            console.log('📱 [Baileys WhatsApp] Novo QR Code gerado! Escaneie para conectar.');
          } catch (qrErr) {
            console.error('[Baileys WhatsApp] Erro ao converter QR Code:', qrErr);
          }
        }

        if (connection === 'close') {
          const shouldReconnect =
            (lastDisconnect?.error as Boom)?.output?.statusCode !== DisconnectReason.loggedOut;
          const statusCode = (lastDisconnect?.error as Boom)?.output?.statusCode;

          console.log(`⚠️ [Baileys WhatsApp] Conexão fechada (Code: ${statusCode}). Reconectar: ${shouldReconnect}`);
          this.status = 'disconnected';
          this.connectedPhone = null;
          this.qrCodeRaw = null;
          this.qrCodeBase64 = null;
          this.isInitializing = false;

          if (shouldReconnect) {
            setTimeout(() => this.initialize(), 5000);
          } else {
            console.log('🚪 [Baileys WhatsApp] Sessão encerrada/desconectada pelo celular.');
            // Limpa arquivos de sessão se deslogado
            try {
              fs.rmSync(this.sessionDir, { recursive: true, force: true });
              fs.mkdirSync(this.sessionDir, { recursive: true });
            } catch (_) {}
          }
        } else if (connection === 'open') {
          this.status = 'connected';
          this.isInitializing = false;
          this.qrCodeRaw = null;
          this.qrCodeBase64 = null;
          this.lastConnectedAt = new Date().toISOString();

          const userJid = this.sock?.user?.id || '';
          this.connectedPhone = userJid.split(':')[0] || userJid.split('@')[0];
          console.log(`✅ [Baileys WhatsApp] CONECTADO COM SUCESSO! WhatsApp Número: ${this.connectedPhone}`);
        }
      });

      // Receptor de mensagens recebidas (atendimento automatizado / bot)
      this.sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify') return;

        for (const msg of messages) {
          // Ignora mensagens enviadas pelo próprio bot
          if (msg.key.fromMe) continue;

          const senderJid = msg.key.remoteJid;
          const text = msg.message?.conversation || msg.message?.extendedTextMessage?.text;

          if (senderJid && text) {
            this.handleIncomingMessage(senderJid, text.trim());
          }
        }
      });
    } catch (err) {
      console.error('[Baileys WhatsApp] Erro fatal na inicialização:', err);
      this.status = 'disconnected';
      this.isInitializing = false;
    }
  }

  /**
   * Resposta inteligente básica a comandos do cliente
   */
  private async handleIncomingMessage(senderJid: string, text: string) {
    const lower = text.toLowerCase();
    console.log(`📩 [WhatsApp Mensagem Recebida de ${senderJid}]: ${text}`);

    if (lower.includes('ajuda') || lower.includes('ola') || lower.includes('olá') || lower.includes('bom dia') || lower.includes('boa tarde')) {
      const reply = 
        `🔥 *Olá! Sou o assistente virtual do BoraGás.*\n\n` +
        `Como posso te ajudar hoje?\n\n` +
        `1️⃣ *Pedir Gás ou Água:* Acesse https://boragas-delta.vercel.app\n` +
        `2️⃣ *Rastrear Entregador:* Envie o número do seu pedido (ex: BG-1024)\n` +
        `3️⃣ *Falar com Suporte Humano:* Ligue para nosso SAC 0800-BORAGAS`;
      await this.sock?.sendMessage(senderJid, { text: reply });
    } else if (lower.startsWith('bg-')) {
      const reply = 
        `🔍 *Rastreamento BoraGás:*\n` +
        `Localizamos o pedido *${text.toUpperCase()}*!\n` +
        `Acompanhe a moto em tempo real no mapa:\n` +
        `👉 https://boragas-delta.vercel.app/#/tracking/${text.toLowerCase()}`;
      await this.sock?.sendMessage(senderJid, { text: reply });
    }
  }

  /**
   * Formata número brasileiro para o padrão JID do WhatsApp (ex: 5511999998888@s.whatsapp.net)
   */
  private formatJid(phone: string): string {
    let digits = phone.replace(/\D/g, '');

    // Se não tiver DDI (55), adiciona
    if (!digits.startsWith('55')) {
      digits = '55' + digits;
    }

    return `${digits}@s.whatsapp.net`;
  }

  /**
   * Envia mensagem de texto simples
   */
  async sendTextMessage(phone: string, text: string): Promise<boolean> {
    if (!this.sock || this.status !== 'connected') {
      console.warn(`[Baileys WhatsApp] Não conectado. Mensagem para ${phone} enfileirada ou ignorada.`);
      return false;
    }

    try {
      const jid = this.formatJid(phone);
      await this.sock.sendMessage(jid, { text });
      console.log(`📤 [Baileys WhatsApp] Mensagem enviada para ${phone}`);
      return true;
    } catch (err: any) {
      console.error(`[Baileys WhatsApp] Falha ao enviar mensagem para ${phone}:`, err.message);
      return false;
    }
  }

  /**
   * Dispara notificação de Novo Pedido para o Cliente
   */
  async notifyOrderCreated(payload: {
    customerPhone: string;
    customerName: string;
    orderNumber: string;
    storeName: string;
    itemsSummary: string;
    totalAmount: number;
    deliveryAddress: string;
    confirmationCode: string;
    orderId: string;
  }): Promise<boolean> {
    const text = 
      `🔥 *BoraGás - Pedido Confirmado!*\n\n` +
      `Olá, *${payload.customerName}*! Seu pedido *#${payload.orderNumber}* foi recebido e já está em preparação na distribuidora *${payload.storeName}*.\n\n` +
      `📦 *Itens do Pedido:*\n${payload.itemsSummary}\n` +
      `💰 *Total:* R$ ${payload.totalAmount.toFixed(2)}\n` +
      `📍 *Entrega em:* ${payload.deliveryAddress}\n\n` +
      `🔐 *SEU CÓDIGO DE ENTREGA:* *${payload.confirmationCode}*\n` +
      `_(Informe este código de 4 dígitos ao entregador SOMENTE após conferir o lacre do botijão!)_\n\n` +
      `🛵 *Acompanhe seu entregador em tempo real no mapa:*\n` +
      `👉 https://boragas-delta.vercel.app/#/tracking/${payload.orderId}\n\n` +
      `_Dúvidas ou cancelamento? Responda AJUDA nesta conversa._`;

    return this.sendTextMessage(payload.customerPhone, text);
  }

  /**
   * Dispara notificação quando o Entregador Sai para Entrega
   */
  async notifyCourierDispatched(payload: {
    customerPhone: string;
    customerName: string;
    orderNumber: string;
    courierName: string;
    etaMinutes: number;
    orderId: string;
  }): Promise<boolean> {
    const text =
      `⚡ *BoraGás - Entregador a Caminho!*\n\n` +
      `*${payload.customerName}*, o entregador *${payload.courierName}* acabou de sair com o seu botijão!\n\n` +
      `⏱️ *Previsão de Chegada:* ~${payload.etaMinutes} minutos\n\n` +
      `🗺️ *Veja a moto se movendo no mapa ao vivo:*\n` +
      `👉 https://boragas-delta.vercel.app/#/tracking/${payload.orderId}\n\n` +
      `Tenha em mãos o seu código de entrega!`;

    return this.sendTextMessage(payload.customerPhone, text);
  }

  /**
   * Dispara notificação de Entrega Concluída
   */
  async notifyOrderDelivered(payload: {
    customerPhone: string;
    customerName: string;
    orderNumber: string;
    storeName: string;
  }): Promise<boolean> {
    const text =
      `🎉 *BoraGás - Pedido Entregue com Sucesso!*\n\n` +
      `*${payload.customerName}*, seu botijão foi entregue pela *${payload.storeName}*.\n\n` +
      `Obrigado por escolher o BoraGás! Por favor, avalie sua experiência no app com 5 estrelas ⭐⭐⭐⭐⭐.\n\n` +
      `Até a próxima troca de gás! 🔥`;

    return this.sendTextMessage(payload.customerPhone, text);
  }

  /**
   * Dispara alerta de Novo Pedido para o WhatsApp da Distribuidora
   */
  async notifyStoreNewOrder(payload: {
    storePhone: string;
    storeName: string;
    orderNumber: string;
    itemsSummary: string;
    totalAmount: number;
    deliveryAddress: string;
    customerName: string;
    customerPhone: string;
  }): Promise<boolean> {
    const text =
      `🔔 *NOVO PEDIDO BORAGÁS RECEBIDO!*\n\n` +
      `Distribuidora: *${payload.storeName}*\n` +
      `Pedido: *#${payload.orderNumber}*\n` +
      `Cliente: *${payload.customerName}* (${payload.customerPhone})\n` +
      `Endereço: *${payload.deliveryAddress}*\n\n` +
      `📦 *Itens:*\n${payload.itemsSummary}\n` +
      `💰 *Valor Total:* R$ ${payload.totalAmount.toFixed(2)}\n\n` +
      `Acesse seu Painel Lojista para despachar:\n` +
      `👉 https://boragas-delta.vercel.app/#/merchant/orders`;

    return this.sendTextMessage(payload.storePhone, text);
  }

  /**
   * Retorna status atual da conexão e QR Code
   */
  getStatus(): WhatsAppStatusInfo {
    return {
      status: this.status,
      connectedPhone: this.connectedPhone,
      qrCodeRaw: this.qrCodeRaw,
      qrCodeBase64: this.qrCodeBase64,
      lastConnectedAt: this.lastConnectedAt,
    };
  }

  /**
   * Força reinicialização / desconexão
   */
  async reconnect(): Promise<void> {
    try {
      if (this.sock) {
        this.sock.end(new Error('Manual reconnect'));
      }
    } catch (_) {}
    this.status = 'disconnected';
    this.connectedPhone = null;
    this.qrCodeRaw = null;
    this.qrCodeBase64 = null;
    await this.initialize();
  }
}

export const whatsappService = new WhatsAppService();
