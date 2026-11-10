import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/marketing_providers.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyalty = ref.watch(loyaltyCardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartão Fidelidade BoraGás'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loyalty Physical-Style Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: AppColors.flameGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BoraGás Fidelidade VIP',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                'Sua fidelidade vale botijão mais barato',
                                style: TextStyle(color: Colors.white60, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: loyalty.isRewardReady ? AppColors.success : Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          loyalty.isRewardReady
                              ? 'PRÊMIO PRONTO! 🎉'
                              : '${loyalty.currentStamps} de ${loyalty.totalStampsRequired} Selos',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 5 Big Stamps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(loyalty.totalStampsRequired, (index) {
                      final isCollected = index < loyalty.currentStamps;
                      final isTarget = index == loyalty.totalStampsRequired - 1;

                      return Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isCollected
                                  ? AppColors.primary
                                  : (isTarget ? const Color(0xFFFEF3C7) : Colors.white.withValues(alpha: 0.08)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCollected
                                    ? AppColors.gasCyan
                                    : (isTarget ? const Color(0xFFF59E0B) : Colors.white24),
                                width: isCollected || isTarget ? 2 : 1,
                              ),
                              boxShadow: isCollected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.gasCyan.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isCollected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                                  : (isTarget
                                      ? const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD97706), size: 26)
                                      : Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        )),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isTarget ? 'R\$ 25 OFF' : 'Pedido ${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isTarget ? FontWeight.w800 : FontWeight.w600,
                              color: isCollected || isTarget ? Colors.white : Colors.white38,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),

                  // Progress Bar & Description
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loyalty.isRewardReady
                            ? 'Recompensa desbloqueada!'
                            : 'Faltam ${loyalty.remainingStamps} selos para completar',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${(loyalty.progress * 100).round()}%',
                        style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: loyalty.progress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reward Action Button
            if (loyalty.isRewardReady) ...[
              AppButton(
                label: 'Resgatar R\$ 25,00 no Carrinho Agora 🎉',
                isFlameAccent: true,
                icon: Icons.redeem_rounded,
                onPressed: () {
                  ref.read(loyaltyCardProvider.notifier).redeemReward();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 R\$ 25,00 de desconto aplicado ao seu próximo pedido!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.go('/cart');
                },
              ),
            ] else ...[
              AppButton(
                label: 'Fazer Pedido para Ganhar Selo ⚡',
                onPressed: () => context.go('/home'),
              ),
            ],

            const SizedBox(height: 24),

            // Completed Orders History
            const Text(
              'Pedidos que Pontuaram Neste Cartão',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: loyalty.completedOrders.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final orderNum = loyalty.completedOrders[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFDCFCE7),
                      child: Icon(Icons.check_rounded, color: AppColors.success, size: 16),
                    ),
                    title: Text('Pedido $orderNum Concluído', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: const Text('Entregue no endereço • +1 Selo validado', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    trailing: const Text(
                      'Selo Ativo',
                      style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Test Simulation Tool
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulador de Gamificação (Demonstração)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Simule a entrega de um novo botijão para pontuar mais 1 selo no cartão:',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Simular Entrega Concluída (+1 Selo) ⚡',
                    isSecondary: true,
                    height: 40,
                    onPressed: () {
                      final nextNum = '#BGR-${9000 + loyalty.currentStamps}';
                      ref.read(loyaltyCardProvider.notifier).addStamp(nextNum);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎉 Pedido $nextNum finalizado! +1 Selo computado com sucesso!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
