import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../support/providers/support_providers.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  String _statusFilter = 'all'; // 'all', 'open', 'in_progress', 'resolved'
  String? _selectedTicketId;
  final TextEditingController _adminReplyController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isSendingReply = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportTicketsProvider.notifier).refreshTickets();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        ref.read(supportTicketsProvider.notifier).refreshTickets();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _adminReplyController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendAdminReply(String ticketId) async {
    final text = _adminReplyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingReply = true);
    HapticFeedback.lightImpact();

    _adminReplyController.clear();

    await ref.read(supportTicketsProvider.notifier).addMessage(
          ticketId: ticketId,
          content: text,
        );

    if (mounted) {
      setState(() => _isSendingReply = false);
      _scrollToBottom();
    }
  }

  Future<void> _openCustomerWhatsApp(String phone, String ticketNumber) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone do cliente não disponível.')),
      );
      return;
    }

    final formatted = cleanPhone.startsWith('55') ? cleanPhone : '55$cleanPhone';
    final text = Uri.encodeComponent(
      'Olá! Aqui é o Suporte Oficial do BoraGás. Estamos entrando em contato referente ao seu chamado protocolo $ticketNumber.',
    );

    final appUri = Uri.parse('whatsapp://send?phone=$formatted&text=$text');
    final webUri = Uri.parse('https://wa.me/$formatted?text=$text');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportTicketsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    final openCount = tickets.where((t) => t.status == TicketStatus.open).length;
    final inProgressCount = tickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolvedCount = tickets.where((t) => t.status == TicketStatus.resolved).length;

    final filteredTickets = tickets.where((t) {
      if (_statusFilter == 'open') return t.status == TicketStatus.open;
      if (_statusFilter == 'in_progress') return t.status == TicketStatus.inProgress;
      if (_statusFilter == 'resolved') return t.status == TicketStatus.resolved;
      return true;
    }).toList();

    // Se nenhum ticket selecionado na tela wide, seleciona o primeiro
    if (isWide && _selectedTicketId == null && filteredTickets.isNotEmpty) {
      _selectedTicketId = filteredTickets.first.id;
    }

    SupportTicketModel? activeTicket;
    if (_selectedTicketId != null) {
      try {
        activeTicket = tickets.firstWhere((t) => t.id == _selectedTicketId);
      } catch (_) {
        activeTicket = filteredTickets.isNotEmpty ? filteredTickets.first : null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Column(
        children: [
          // Header de Indicadores do Helpdesk
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.headset_mic_rounded, color: Color(0xFF8B5CF6), size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Helpdesk & Suporte',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Indicador de alerta WhatsApp
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Baileys Hub',
                            style: TextStyle(
                              color: Color(0xFF25D366),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Cards de Métricas com scroll horizontal responsivo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildKpiCard('Total Chamados', '${tickets.length}', const Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      _buildKpiCard('Abertos', '$openCount', const Color(0xFFF59E0B), isUrgent: openCount > 0),
                      const SizedBox(width: 10),
                      _buildKpiCard('Em Atendimento', '$inProgressCount', const Color(0xFF38BDF8)),
                      const SizedBox(width: 10),
                      _buildKpiCard('Resolvidos', '$resolvedCount', const Color(0xFF10B981)),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Filtro por Status
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Todos (${tickets.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('open', 'Abertos ($openCount)', badgeColor: const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _buildFilterChip('in_progress', 'Em Atendimento ($inProgressCount)', badgeColor: const Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      _buildFilterChip('resolved', 'Resolvidos ($resolvedCount)', badgeColor: const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Corpo Principal (Dividido em lista e painel de chat na tela ampla)
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      // Coluna da Lista de Chamados
                      SizedBox(
                        width: 380,
                        child: _buildTicketsList(filteredTickets),
                      ),
                      const VerticalDivider(width: 1, color: Color(0xFF1E293B)),
                      // Painel de Chat e Resposta do Ticket Selecionado
                      Expanded(
                        child: activeTicket != null
                            ? _buildActiveTicketPanel(activeTicket)
                            : const Center(
                                child: Text('Selecione um chamado ao lado', style: TextStyle(color: Color(0xFF64748B))),
                              ),
                      ),
                    ],
                  )
                : _buildTicketsList(filteredTickets),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color, {bool isUrgent = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 125),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: isUrgent ? const Color(0xFFF59E0B) : Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? badgeColor}) {
    final isSelected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFFA78BFA) : const Color(0xFF334155)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList(List<SupportTicketModel> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum chamado neste filtro.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final ticket = list[index];
        final isSelected = ticket.id == _selectedTicketId;

        final statusColor = switch (ticket.status) {
          TicketStatus.resolved => const Color(0xFF10B981),
          TicketStatus.inProgress => const Color(0xFF38BDF8),
          TicketStatus.open => const Color(0xFFF59E0B),
        };

        return Card(
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF111827),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1F2937),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            onTap: () {
              HapticFeedback.selectionClick();
              final isWide = MediaQuery.of(context).size.width > 900;
              if (isWide) {
                setState(() => _selectedTicketId = ticket.id);
              } else {
                _openMobileTicketSheet(ticket);
              }
            },
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ticket.ticketNumber,
                  style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w900, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    ticket.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  ticket.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ticket.requesterName} • ${DateFormat("dd/MM HH:mm").format(ticket.createdAt)}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTicketPanel(SupportTicketModel ticket) {
    return Column(
      children: [
        // Topo com Detalhes do Cliente e Ações Rápidas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ticket.ticketNumber,
                          style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${ticket.category}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: ${ticket.requesterName} • ${ticket.requesterPhone ?? "Sem telefone"} • ${ticket.requesterEmail ?? ""}',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Botão Chamar no WhatsApp
              if (ticket.requesterPhone != null && ticket.requesterPhone!.isNotEmpty) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _openCustomerWhatsApp(ticket.requesterPhone!, ticket.ticketNumber),
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(width: 8),
              ],

              // Dropdown para Alterar Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TicketStatus>(
                    value: ticket.status,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    items: const [
                      DropdownMenuItem(value: TicketStatus.open, child: Text('Aberto')),
                      DropdownMenuItem(value: TicketStatus.inProgress, child: Text('Em Atendimento')),
                      DropdownMenuItem(value: TicketStatus.resolved, child: Text('Resolvido')),
                    ],
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        ref.read(supportTicketsProvider.notifier).updateTicketStatus(ticket.id, newStatus);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista de Mensagens do Chat
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: ticket.messages.length,
            itemBuilder: (context, index) {
              final msg = ticket.messages[index];
              final isAdmin = msg.senderRole == 'admin';

              return Align(
                alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isAdmin ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isAdmin ? const Radius.circular(2) : const Radius.circular(16),
                      bottomLeft: isAdmin ? const Radius.circular(16) : const Radius.circular(2),
                    ),
                    border: Border.all(
                      color: isAdmin ? const Color(0xFFA78BFA) : const Color(0xFF334155),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.senderName,
                        style: TextStyle(
                          color: isAdmin ? Colors.white70 : const Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        msg.content,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat("HH:mm").format(msg.sentAt),
                        style: TextStyle(
                          color: isAdmin ? Colors.white60 : const Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Campo de Resposta do Super Admin
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _adminReplyController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Responder como Suporte Oficial BoraGás...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                  onSubmitted: (_) => _sendAdminReply(ticket.id),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: _isSendingReply ? null : () => _sendAdminReply(ticket.id),
                child: _isSendingReply
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row(
                        children: [
                          Icon(Icons.send_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Responder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openMobileTicketSheet(SupportTicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B0F19),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: _buildActiveTicketPanel(ticket),
        ),
      ),
    );
  }
}
