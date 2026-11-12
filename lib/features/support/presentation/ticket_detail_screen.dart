import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/support_providers.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply(SupportTicketModel ticket) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();

    _replyController.clear();

    await ref.read(supportTicketsProvider.notifier).addMessage(
          ticketId: ticket.id,
          content: text,
        );

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportTicketsProvider);
    final auth = ref.watch(authProvider);
    final currentUser = auth.user;

    final ticket = tickets.firstWhere(
      (t) => t.id == widget.ticketId,
      orElse: () => tickets.isNotEmpty
          ? tickets.first
          : SupportTicketModel(
              id: widget.ticketId,
              ticketNumber: '#SUP-0000',
              requesterId: currentUser?.id ?? '',
              requesterName: currentUser?.name ?? 'Cliente BoraGás',
              requesterRole: 'customer',
              category: 'Geral',
              subject: 'Chamado',
              status: TicketStatus.open,
              messages: const [],
              createdAt: DateTime.now(),
            ),
    );

    final statusColor = switch (ticket.status) {
      TicketStatus.resolved => const Color(0xFF059669),
      TicketStatus.inProgress => const Color(0xFF2563EB),
      TicketStatus.open => const Color(0xFFF59E0B),
    };

    final statusLabel = switch (ticket.status) {
      TicketStatus.resolved => 'RESOLVIDO',
      TicketStatus.inProgress => 'EM ATENDIMENTO',
      TicketStatus.open => 'ABERTO (AGUARDANDO ATENDENTE)',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.ticketNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              ticket.category,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          // Botão Direto para Conversar no WhatsApp do Atendimento
          IconButton(
            tooltip: 'Falar no WhatsApp Oficial',
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
            onPressed: () {
              ref.read(supportTicketsProvider.notifier).launchDirectWhatsAppSupport(
                    ticketNumber: ticket.ticketNumber,
                  );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho de Status e Informações do Protocolo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aberto em ${DateFormat("dd/MM/yyyy 'às' HH:mm").format(ticket.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Banner do Canal WhatsApp Integrado
          InkWell(
            onTap: () {
              ref.read(supportTicketsProvider.notifier).launchDirectWhatsAppSupport(
                    ticketNumber: ticket.ticketNumber,
                  );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: const Color(0xFF25D366).withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.chat_rounded, color: Color(0xFF128C7E), size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Prefere atendimento rápido? Toque aqui para continuar no WhatsApp.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF0F766E)),
                ],
              ),
            ),
          ),

          // Lista de Mensagens do Chat
          Expanded(
            child: ticket.messages.isEmpty
                ? const Center(
                    child: Text('Nenhuma mensagem registrada.', style: TextStyle(color: Color(0xFF94A3B8))),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: ticket.messages.length,
                    itemBuilder: (context, index) {
                      final msg = ticket.messages[index];
                      final isMe = msg.senderRole != 'admin';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
                            ),
                            border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe) ...[
                                    const Icon(Icons.headset_mic_rounded, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    msg.senderName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isMe ? Colors.white70 : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                msg.content,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.35,
                                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white60 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Campo de Envio de Mensagem
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem para o suporte...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendReply(ticket),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : () => _sendReply(ticket),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
