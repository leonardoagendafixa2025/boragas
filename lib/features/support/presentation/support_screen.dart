import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/support_providers.dart';
import 'new_ticket_dialog.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportTicketsProvider.notifier).refreshTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportTicketsProvider);
    final auth = ref.watch(authProvider);
    final currentUser = auth.user;

    // Filtra os chamados do usuário logado (ou todos caso seja admin)
    final myTickets = (currentUser != null && currentUser.role != UserRole.admin)
        ? tickets.where((t) => t.requesterId == currentUser.id).toList()
        : tickets;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Central de Ajuda & Suporte', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar Chamados',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(supportTicketsProvider.notifier).refreshTickets();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Novo Chamado', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () {
          HapticFeedback.lightImpact();
          showDialog(
            context: context,
            builder: (context) => const NewTicketDialog(),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(supportTicketsProvider.notifier).refreshTickets();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card WhatsApp Oficial de Atendimento com o Admin
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF065F46)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suporte Oficial BoraGás no WhatsApp',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Atendimento prioritário direto com nossa equipe',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(supportTicketsProvider.notifier).launchDirectWhatsAppSupport();
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text(
                        'Falar no WhatsApp com o Suporte Oficial',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Seção de Chamados Abertos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MEUS CHAMADOS EM ANDAMENTO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${myTickets.length} chamado(s)',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (myTickets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Você não possui chamados abertos no momento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Precisa de ajuda com uma entrega, pagamento ou botijão? Toque em "Novo Chamado".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ...myTickets.map((t) {
                final statusColor = switch (t.status) {
                  TicketStatus.resolved => const Color(0xFF059669),
                  TicketStatus.inProgress => const Color(0xFF2563EB),
                  TicketStatus.open => const Color(0xFFF59E0B),
                };

                final statusLabel = switch (t.status) {
                  TicketStatus.resolved => 'RESOLVIDO',
                  TicketStatus.inProgress => 'EM ATENDIMENTO',
                  TicketStatus.open => 'ABERTO',
                };

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/support/ticket/${t.id}');
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        t.status == TicketStatus.resolved ? Icons.check_circle_rounded : Icons.chat_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          t.ticketNumber,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 3),
                        Text(
                          t.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${t.category} • ${DateFormat("dd/MM 'às' HH:mm").format(t.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // FAQ Section
            const Text(
              'PERGUNTAS FREQUENTES (FAQ)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            _buildFaqTile(
              question: 'Como funciona a troca de botijão vazio?',
              answer:
                  'Na entrega, você deve entregar o seu botijão vazio correspondente (P13 residencial ou P45) da mesma capacidade ao entregador. Caso você não tenha um casco vazio para troca, certifique-se de escolher a opção "Comprar Botijão Completo (Com vasilhame)" no momento da compra.',
            ),
            _buildFaqTile(
              question: 'Qual é o prazo médio de entrega?',
              answer:
                  'Nosso prazo médio de entrega expressa é de aproximadamente 20 a 35 minutos após a confirmação do pedido pelo lojista, variando conforme a distância da distribuidora e o tráfego da sua região.',
            ),
            _buildFaqTile(
              question: 'Quais formas de pagamento são aceitas?',
              answer:
                  'Aceitamos Pix Online diretamente no aplicativo (com confirmação instantânea), além de Cartão de Crédito, Cartão de Débito e Dinheiro com troco informado no ato da entrega.',
            ),
            _buildFaqTile(
              question: 'Como funciona o desconto do Clube BoraGás?',
              answer:
                  'Membros ativos do Clube BoraGás têm 5% OFF garantido em todos os botijões e galões de água, além de prioridade total na fila de despacho de pedidos.',
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        shape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 18),
        ),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
          ),
        ],
      ),
    );
  }
}
