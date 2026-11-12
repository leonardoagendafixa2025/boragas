import { Request, Response } from 'express';
import { supportService } from '../services/support.service.js';

export async function listSupportTickets(req: Request, res: Response) {
  try {
    const requesterId = req.query.requester_id as string | undefined;
    const role = req.query.role as string | undefined;

    const tickets = await supportService.listTickets(requesterId, role);
    return res.json({
      success: true,
      data: tickets,
    });
  } catch (err: any) {
    return res.status(500).json({
      success: false,
      error: 'Erro ao listar chamados de suporte',
      details: err.message,
    });
  }
}

export async function createSupportTicket(req: Request, res: Response) {
  try {
    const {
      category,
      subject,
      initialMessage,
      requesterId,
      requesterName,
      requesterPhone,
      requesterEmail,
      requesterRole,
      relatedOrderId,
    } = req.body;

    if (!category || !subject || !initialMessage) {
      return res.status(400).json({
        success: false,
        error: 'category, subject e initialMessage são campos obrigatórios.',
      });
    }

    const ticket = await supportService.createTicket({
      category,
      subject,
      initialMessage,
      requesterId: requesterId || `usr-${Date.now()}`,
      requesterName: requesterName || 'Cliente BoraGás',
      requesterPhone,
      requesterEmail,
      requesterRole: requesterRole || 'customer',
      relatedOrderId,
    });

    return res.status(201).json({
      success: true,
      data: ticket,
    });
  } catch (err: any) {
    return res.status(500).json({
      success: false,
      error: 'Erro ao criar chamado de suporte',
      details: err.message,
    });
  }
}

export async function addSupportMessage(req: Request, res: Response) {
  try {
    const ticketId = (Array.isArray(req.params.ticketId) ? req.params.ticketId[0] : req.params.ticketId) as string;
    const { content, senderId, senderName, senderRole } = req.body;

    if (!ticketId || !content) {
      return res.status(400).json({
        success: false,
        error: 'ticketId e content são campos obrigatórios.',
      });
    }

    const updated = await supportService.addMessage({
      ticketId,
      content,
      senderId: senderId || `usr-${Date.now()}`,
      senderName: senderName || 'Usuário',
      senderRole: senderRole || 'customer',
    });

    if (!updated) {
      return res.status(404).json({
        success: false,
        error: 'Chamado não encontrado.',
      });
    }

    return res.json({
      success: true,
      data: updated,
    });
  } catch (err: any) {
    return res.status(500).json({
      success: false,
      error: 'Erro ao adicionar mensagem no chamado',
      details: err.message,
    });
  }
}

export async function updateSupportTicketStatus(req: Request, res: Response) {
  try {
    const ticketId = (Array.isArray(req.params.ticketId) ? req.params.ticketId[0] : req.params.ticketId) as string;
    const { status } = req.body;

    if (!ticketId || !status || !['open', 'in_progress', 'resolved'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: "status deve ser 'open', 'in_progress' ou 'resolved'.",
      });
    }

    const updated = await supportService.updateStatus(ticketId, status);
    if (!updated) {
      return res.status(404).json({
        success: false,
        error: 'Chamado não encontrado.',
      });
    }

    return res.json({
      success: true,
      data: updated,
    });
  } catch (err: any) {
    return res.status(500).json({
      success: false,
      error: 'Erro ao atualizar status do chamado',
      details: err.message,
    });
  }
}
