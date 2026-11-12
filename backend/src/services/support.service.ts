import fs from 'fs';
import path from 'path';
import { getSupabase } from './supabase.service.js';
import { whatsappService } from './whatsapp.service.js';

export interface SupportMessage {
  id: string;
  ticketId: string;
  senderId: string;
  senderName: string;
  senderRole: string;
  content: string;
  sentAt: string;
}

export interface SupportTicket {
  id: string;
  ticketNumber: string;
  requesterId: string;
  requesterName: string;
  requesterPhone: string;
  requesterEmail: string;
  requesterRole: string;
  category: string;
  subject: string;
  status: 'open' | 'in_progress' | 'resolved';
  relatedOrderId?: string | null;
  createdAt: string;
  updatedAt: string;
  messages: SupportMessage[];
}

class SupportService {
  private tickets: Map<string, SupportTicket> = new Map();
  private dataFilePath: string;

  constructor() {
    const dataDir = path.resolve(process.cwd(), 'data');
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }
    this.dataFilePath = path.join(dataDir, 'support_tickets.json');
    this.loadPersistedTickets();
  }

  private loadPersistedTickets(): void {
    try {
      if (fs.existsSync(this.dataFilePath)) {
        const raw = fs.readFileSync(this.dataFilePath, 'utf-8');
        const list: SupportTicket[] = JSON.parse(raw);
        for (const ticket of list) {
          this.tickets.set(ticket.id, ticket);
        }
        console.log(`📋 [SupportService] ${list.length} chamados de suporte carregados do disco.`);
      }
    } catch (err) {
      console.warn('[SupportService] Falha ao ler tickets do disco:', err);
    }
  }

  private persistTickets(): void {
    try {
      const list = Array.from(this.tickets.values());
      fs.writeFileSync(this.dataFilePath, JSON.stringify(list, null, 2), 'utf-8');
    } catch (err) {
      console.error('[SupportService] Falha ao persistir tickets no disco:', err);
    }
  }

  /**
   * Lista todos os chamados ou filtra por solicitante
   */
  async listTickets(requesterId?: string, role?: string): Promise<SupportTicket[]> {
    let list = Array.from(this.tickets.values());

    // Se for cliente e não for admin, filtra apenas os chamados dele
    if (requesterId && role !== 'admin') {
      list = list.filter((t) => t.requesterId === requesterId);
    }

    // Ordena do mais recente para o mais antigo
    list.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
    return list;
  }

  /**
   * Obtém um chamado por ID
   */
  async getTicketById(ticketId: string): Promise<SupportTicket | null> {
    return this.tickets.get(ticketId) || null;
  }

  /**
   * Criação de chamado de suporte
   */
  async createTicket(data: {
    category: string;
    subject: string;
    initialMessage: string;
    requesterId: string;
    requesterName: string;
    requesterPhone?: string;
    requesterEmail?: string;
    requesterRole?: string;
    relatedOrderId?: string | null;
  }): Promise<SupportTicket> {
    const now = new Date().toISOString();
    const year = new Date().getFullYear();
    const seq = Math.floor(1000 + Math.random() * 9000);
    const protocol = `#SUP-${year}-${seq}`;
    const ticketId = `tkt-${Date.now()}`;

    const initialMsg: SupportMessage = {
      id: `msg-${Date.now()}`,
      ticketId,
      senderId: data.requesterId,
      senderName: data.requesterName || 'Cliente BoraGás',
      senderRole: data.requesterRole || 'customer',
      content: data.initialMessage,
      sentAt: now,
    };

    const newTicket: SupportTicket = {
      id: ticketId,
      ticketNumber: protocol,
      requesterId: data.requesterId,
      requesterName: data.requesterName || 'Cliente BoraGás',
      requesterPhone: data.requesterPhone || '',
      requesterEmail: data.requesterEmail || '',
      requesterRole: data.requesterRole || 'customer',
      category: data.category,
      subject: data.subject,
      status: 'open',
      relatedOrderId: data.relatedOrderId || null,
      createdAt: now,
      updatedAt: now,
      messages: [initialMsg],
    };

    this.tickets.set(ticketId, newTicket);
    this.persistTickets();

    // Tenta sincronizar com Supabase se a tabela existir
    try {
      const supabase = getSupabase();
      await supabase.from('support_tickets').insert({
        id: ticketId,
        ticket_number: protocol,
        requester_id: data.requesterId,
        requester_name: newTicket.requesterName,
        requester_phone: newTicket.requesterPhone,
        requester_email: newTicket.requesterEmail,
        category: data.category,
        subject: data.subject,
        status: 'open',
        order_id: data.relatedOrderId || null,
        created_at: now,
        updated_at: now,
      });
    } catch (_) {}

    // Dispara notificação no WhatsApp do Admin conectado via Baileys
    this.notifyAdminOnWhatsApp(newTicket, data.initialMessage, false).catch((err) => {
      console.warn('[SupportService] Falha ao notificar WhatsApp do Admin:', err.message);
    });

    console.log(`✅ [SupportService] Chamado criado: ${protocol} (${newTicket.requesterName})`);
    return newTicket;
  }

  /**
   * Adiciona mensagem ao chamado (Admin ou Cliente)
   */
  async addMessage(data: {
    ticketId: string;
    content: string;
    senderId: string;
    senderName: string;
    senderRole: string;
  }): Promise<SupportTicket | null> {
    const ticket = this.tickets.get(data.ticketId);
    if (!ticket) return null;

    const now = new Date().toISOString();
    const newMsg: SupportMessage = {
      id: `msg-${Date.now()}`,
      ticketId: data.ticketId,
      senderId: data.senderId,
      senderName: data.senderRole === 'admin' ? 'Suporte Oficial BoraGás' : data.senderName,
      senderRole: data.senderRole,
      content: data.content,
      sentAt: now,
    };

    const nextStatus =
      data.senderRole === 'admin' && ticket.status === 'open' ? 'in_progress' : ticket.status;

    ticket.status = nextStatus;
    ticket.updatedAt = now;
    ticket.messages.push(newMsg);

    this.tickets.set(data.ticketId, ticket);
    this.persistTickets();

    // Se a mensagem partiu de cliente, avisa admin no WhatsApp
    if (data.senderRole !== 'admin') {
      this.notifyAdminOnWhatsApp(ticket, data.content, true).catch(() => {});
    }

    console.log(`💬 [SupportService] Mensagem adicionada em ${ticket.ticketNumber} por ${data.senderName}`);
    return ticket;
  }

  /**
   * Atualiza status do chamado
   */
  async updateStatus(ticketId: string, status: 'open' | 'in_progress' | 'resolved'): Promise<SupportTicket | null> {
    const ticket = this.tickets.get(ticketId);
    if (!ticket) return null;

    ticket.status = status;
    ticket.updatedAt = new Date().toISOString();
    this.tickets.set(ticketId, ticket);
    this.persistTickets();

    console.log(`🔄 [SupportService] Chamado ${ticket.ticketNumber} atualizado para ${status}`);
    return ticket;
  }

  /**
   * Envia notificação formatada para o WhatsApp do Admin conectado
   */
  private async notifyAdminOnWhatsApp(ticket: SupportTicket, messageText: string, isUpdate: boolean): Promise<void> {
    const status = whatsappService.getStatus();
    const connectedPhone = status.connectedPhone;
    if (!connectedPhone) {
      console.log('ℹ️ [SupportService] WhatsApp do admin não conectado para receber aviso direto.');
      return;
    }

    const title = isUpdate
      ? '💬 *NOVA MENSAGEM NO SUPORTE - BORAGÁS*'
      : '🚨 *NOVO CHAMADO DE SUPORTE ABERTO - BORAGÁS*';

    const clientInfo = ticket.requesterPhone
      ? `${ticket.requesterName} (${ticket.requesterPhone})`
      : ticket.requesterName;

    const body = `
${title}

📋 *Protocolo:* ${ticket.ticketNumber}
👤 *Cliente:* ${clientInfo}
✉️ *E-mail:* ${ticket.requesterEmail || 'Não informado'}
📂 *Categoria:* ${ticket.category}
📝 *Assunto:* ${ticket.subject}
${ticket.relatedOrderId ? `📦 *Pedido Relacionado:* ${ticket.relatedOrderId}\n` : ''}
💬 *Mensagem:*
"${messageText}"

⏱️ *Data/Hora:* ${new Date(ticket.createdAt).toLocaleString('pt-BR')}
━━━━━━━━━━━━━━━━━━━━
👉 Acesse o Painel do Super Admin > Helpdesk para responder em tempo real.
`.trim();

    await whatsappService.sendTextMessage(connectedPhone, body);
  }
}

export const supportService = new SupportService();
