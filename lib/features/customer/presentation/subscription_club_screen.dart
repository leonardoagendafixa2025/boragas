import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/customer_providers.dart';
import '../providers/subscription_provider.dart';

class SubscriptionPlanItem {
  final String id;
  final String title;
  final String subtitle;
  final double originalPrice;
  final double discountedPrice;
  final IconData icon;
  final String intervalDefault;

  const SubscriptionPlanItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.originalPrice,
    required this.discountedPrice,
    required this.icon,
    required this.intervalDefault,
  });
}

class SubscriptionClubScreen extends ConsumerStatefulWidget {
  const SubscriptionClubScreen({super.key});

  @override
  ConsumerState<SubscriptionClubScreen> createState() => _SubscriptionClubScreenState();
}

class _SubscriptionClubScreenState extends ConsumerState<SubscriptionClubScreen> {
  final List<SubscriptionPlanItem> _plans = const [
    SubscriptionPlanItem(
      id: 'gas-p13',
      title: 'Botijão GLP 13kg (Troca)',
      subtitle: 'Gás de cozinha tradicional das melhores marcas (Ultragaz, Liquigás, Nacional)',
      originalPrice: 105.00,
      discountedPrice: 99.75,
      icon: Icons.propane_tank_rounded,
      intervalDefault: '45 dias',
    ),
    SubscriptionPlanItem(
      id: 'water-combo',
      title: 'Galão Água Mineral 20L (2x)',
      subtitle: '2 Galões retornáveis de 20L entregues no mesmo pedido',
      originalPrice: 32.00,
      discountedPrice: 28.80,
      icon: Icons.water_drop_rounded,
      intervalDefault: '15 dias',
    ),
    SubscriptionPlanItem(
      id: 'combo-total',
      title: 'Combo Residencial (Gás P13 + 1 Galão 20L)',
      subtitle: 'Tudo o que sua cozinha precisa com prioridade no agendamento',
      originalPrice: 121.00,
      discountedPrice: 112.50,
      icon: Icons.all_inclusive_rounded,
      intervalDefault: '45 dias',
    ),
  ];

  String _selectedPlanId = 'gas-p13';
  int _selectedFrequencyDays = 45;
  String _selectedTimeSlot = 'Sábado pela manhã (09h - 12h)';
  bool _requireConfirmation = true;
  bool _preferLowestPrice = true;

  final List<int> _frequencies = [15, 30, 45, 60, 90];
  final List<String> _timeSlots = [
    'Sábado pela manhã (09h - 12h)',
    'Segunda-feira à tarde (14h - 17h)',
    'Quarta-feira pela manhã (09h - 12h)',
    'Horário comercial flexível',
  ];

  Future<void> _handleActivate() async {
    HapticFeedback.mediumImpact();
    final currentAddress = ref.read(currentAddressProvider);
    final selectedPlan = _plans.firstWhere((p) => p.id == _selectedPlanId);

    await ref.read(subscriptionProvider.notifier).activateSubscription(
          planId: selectedPlan.id,
          planTitle: selectedPlan.title,
          planPrice: selectedPlan.discountedPrice,
          frequencyDays: _selectedFrequencyDays,
          timeSlot: _selectedTimeSlot,
          deliveryAddress: currentAddress.formatted,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Bem-vindo ao Clube BoraGás! Recorrência ativa com 5% OFF garantido.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _confirmCancel() async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar Assinatura', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text(
          'Deseja realmente cancelar sua assinatura do Clube BoraGás? Você perderá o desconto fixo de 5% e a prioridade de entrega.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter Assinatura', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar Clube', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(subscriptionProvider.notifier).cancelSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assinatura do Clube BoraGás cancelada com sucesso.'),
            backgroundColor: Color(0xFF1E293B),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    final currentAddress = ref.watch(currentAddressProvider);
    final isSubscribed = subscription != null && subscription.isActive;

    final selectedPlan = _plans.firstWhere((p) => p.id == _selectedPlanId);
    final annualSavings = (selectedPlan.originalPrice - selectedPlan.discountedPrice) *
        (365 / _selectedFrequencyDays);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clube BoraGás'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Como funciona',
            onPressed: _showHowItWorksModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Se já for assinante ativo, exibe o Cockpit do Assinante em primeiro lugar
            if (isSubscribed) ...[
              _buildActiveSubscriptionCockpit(subscription),
              const SizedBox(height: 24),
              const Text(
                'Personalizar ou Alterar Meu Plano',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
            ] else ...[
              // Banner de Apresentação / Vantagens
              _buildIntroHero(currentAddress.formatted),
              const SizedBox(height: 24),
              const Text(
                '1. Escolha o Item Recorrente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
            ],

            // Seletor de Planos
            ..._plans.map((plan) {
              final isSelected = plan.id == _selectedPlanId;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPlanId = plan.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          plan.icon,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan.subtitle,
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'De R\$ ${plan.originalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Por R\$ ${plan.discountedPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '5% OFF',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 2,
                          ),
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.check, size: 16, color: Colors.white),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Periodicidade
            const Text(
              '2. Periodicidade Desejada',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Dica: Um botijão P13 dura em média 45 a 60 dias para uma família padrão.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _frequencies.map((days) {
                  final isSelected = days == _selectedFrequencyDays;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('A cada $days dias'),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                      onSelected: (val) {
                        if (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFrequencyDays = days);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Janela de Horário
            const Text(
              '3. Janela de Entrega Preferida',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeSlot,
                  isExpanded: true,
                  items: _timeSlots
                      .map((slot) => DropdownMenuItem(
                            value: slot,
                            child: Text(slot, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTimeSlot = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preferências Inteligentes
            const Text(
              '4. Preferências Inteligentes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primary,
                      title: const Text('Notificação Preditiva (Recomendado)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Avisa 3 dias antes por Push. Você pode confirmar, adiar ou cancelar sem custo.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: _requireConfirmation,
                      onChanged: (val) => setState(() => _requireConfirmation = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primary,
                      title: const Text('Sempre o Menor Preço da Região', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('O BoraGás busca automaticamente a distribuidora parceira credenciada mais próxima.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: _preferLowestPrice,
                      onChanged: (val) => setState(() => _preferLowestPrice = val),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Economia Anual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sua Economia Anual Estimada:',
                          style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'R\$ ${annualSavings.toStringAsFixed(2)} / ano',
                          style: const TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          '+ Frete prioritário e atendimento VIP',
                          style: TextStyle(color: Color(0xFF166534), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Botão de Ação
            AppButton(
              label: isSubscribed ? 'Salvar Alterações do Plano' : 'Ativar Assinatura com 5% OFF',
              icon: isSubscribed ? Icons.check_circle_rounded : Icons.flash_on_rounded,
              isFlameAccent: !isSubscribed,
              onPressed: _handleActivate,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Painel de Controle do Assinante Ativo
  Widget _buildActiveSubscriptionCockpit(SubscriptionClubModel subscription) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: subscription.isPaused ? const Color(0xFFF59E0B) : AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      subscription.isPaused ? Icons.pause_circle_rounded : Icons.verified_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      subscription.isPaused ? 'ASSINATURA PAUSADA' : 'CLUBE BORAGÁS ATIVO',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '5% OFF FIXO',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subscription.planTitle,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${subscription.planPrice.toStringAsFixed(2)} por entrega • A cada ${subscription.frequencyDays} dias',
            style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.accentFlame, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subscription.daysUntilNextDelivery == 0
                          ? 'Próxima entrega programada para HOJE!'
                          : 'Próxima entrega estimada em ${subscription.daysUntilNextDelivery} dia(s) (${_formatDate(subscription.nextDeliveryDate)})',
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      subscription.timeSlot,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subscription.deliveryAddress.isNotEmpty
                            ? subscription.deliveryAddress
                            : 'Endereço cadastrado na conta',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Botões de Ação Rápida do Assinante
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await ref.read(subscriptionProvider.notifier).advanceNextDeliveryToToday();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚡ Entrega antecipada para hoje com 5% de desconto!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.electric_bolt_rounded, size: 16, color: Color(0xFFFACC15)),
                label: const Text('Adiantar p/ Hoje', style: TextStyle(fontSize: 11.5)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await ref.read(subscriptionProvider.notifier).postponeNextDelivery(15);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📅 Próxima entrega adiada em +15 dias.'),
                        backgroundColor: Color(0xFF1E293B),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.update_rounded, size: 16),
                label: const Text('Adiar +15 dias', style: TextStyle(fontSize: 11.5)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: subscription.isPaused ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                  side: BorderSide(
                    color: subscription.isPaused ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await ref.read(subscriptionProvider.notifier).togglePause();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(subscription.isPaused
                            ? '▶️ Assinatura retomada com sucesso!'
                            : '⏸️ Assinatura pausada temporariamente.'),
                        backgroundColor: const Color(0xFF1E293B),
                      ),
                    );
                  }
                },
                icon: Icon(subscription.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 16),
                label: Text(subscription.isPaused ? 'Retomar Clube' : 'Pausar', style: const TextStyle(fontSize: 11.5)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: _confirmCancel,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Cancelar Clube', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroHero(String addressFormatted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.flameGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'ECONOMIA & CONFORTO',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.verified_user_rounded, color: AppColors.gasCyan, size: 18),
              const SizedBox(width: 4),
              const Text(
                'Sem Fidelidade',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Abastecimento Automático BoraGás',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Defina a periodicidade ideal e receba seu gás e água com 5% de desconto garantido e prioridade na rota do entregador.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.accentFlame, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Endereço: $addressFormatted',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHowItWorksModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Como funciona o Clube BoraGás?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _buildFaqItem(
              Icons.alarm_on_rounded,
              'Sem surpresas',
              'Nunca mais fique sem gás no domingo ou sem água durante uma festa.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              Icons.percent_rounded,
              'Preço mais barato sempre',
              'Assinantes têm desconto direto de 5% sobre a melhor cotação da região.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              Icons.cancel_outlined,
              'Cancelamento a qualquer momento',
              'Sem fidelidade, multas ou pegadinhas. Pause ou cancele quando quiser.',
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Entendi, fechar',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
