import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/support_ticket_model.dart';
import '../providers/support_providers.dart';
import 'new_ticket_dialog.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Ajuda & Suporte'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Novo Chamado'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const NewTicketDialog(),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fast Channels Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atendimento BoraGás',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Tempo médio de resposta: 3 minutos',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Open Tickets Section
            const Text(
              'MEUS CHAMADOS EM ANDAMENTO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            if (tickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'Você não possui chamados abertos no momento.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...tickets.map((t) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    onTap: () => context.push('/support/ticket/${t.id}'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.status == TicketStatus.resolved
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        t.status == TicketStatus.resolved ? Icons.check_circle_rounded : Icons.chat_rounded,
                        color: t.status == TicketStatus.resolved ? AppColors.success : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('${t.ticketNumber} • ${t.category}', style: AppTypography.bodySmall),
                    trailing: const Icon(Icons.chevron_right_rounded),
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
                  'Na opção "Troca de Vasilhame", você entrega seu botijão vazio (de qualquer marca reconhecida pela ANP) na mesma capacidade (ex: P13) e recebe o novo lacrado, pagando apenas pelo gás.',
            ),
            _buildFaqTile(
              question: 'Como o pagamento vai direto para a distribuidora?',
              answer:
                  'Utilizamos o modelo BYOK (Bring Your Own Key). A distribuidora integra a própria chave da API do Mercado Pago/Asaas ou maquininha Smart POS. O valor cai direto na conta bancária dela, sem intermediação do BoraGás.',
            ),
            _buildFaqTile(
              question: 'O que é o código de confirmação de entrega?',
              answer:
                  'É um PIN de segurança de 4 dígitos gerado no momento do pedido. Você só deve informá-lo ao entregador após verificar que o botijão ou galão está lacrado e sem vazamentos.',
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Text(
            answer,
            style: AppTypography.bodySmall.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
