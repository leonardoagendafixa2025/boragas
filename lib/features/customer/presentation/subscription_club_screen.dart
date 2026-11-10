import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/customer_providers.dart';

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
  bool _isSubscribed = false;

  final List<int> _frequencies = [15, 30, 45, 60, 90];
  final List<String> _timeSlots = [
    'Sábado pela manhã (09h - 12h)',
    'Segunda-feira à tarde (14h - 17h)',
    'Quarta-feira pela manhã (09h - 12h)',
    'Horário comercial flexível',
  ];

  void _confirmSubscription() {
    setState(() {
      _isSubscribed = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('Assinatura Ativada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parabéns! Sua recorrência inteligente do Clube BoraGás está ativa.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Você receberá uma notificação preditiva 3 dias antes da data estimada com a opção de alterar a data, pular ou confirmar com 1 toque.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.discount_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Desconto de 5% garantido aplicado diretamente pelo distribuidor credenciado.',
                      style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Voltar à Home'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver Minha Assinatura'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAddress = ref.watch(currentAddressProvider);
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
            onPressed: () {
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
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            Container(
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
                            'Endereço: ${currentAddress.formatted}',
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
            ),
            const SizedBox(height: 24),

            // Plan Selector
            const Text(
              '1. Escolha o Item Recorrente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ..._plans.map((plan) {
              final isSelected = plan.id == _selectedPlanId;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlanId = plan.id;
                  });
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

            // Frequency Selector
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
                          setState(() => _selectedFrequencyDays = days);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Preferred Time Slot
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
                      setState(() => _selectedTimeSlot = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Smart Settings
            const Text(
              '4. Preferências Inteligentes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
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
                      subtitle: const Text('O BoraGás busca automaticamente a distribuidora parceira mais barata no seu bairro.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: _preferLowestPrice,
                      onChanged: (val) => setState(() => _preferLowestPrice = val),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Savings summary card
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

            // Submit Button
            AppButton(
              label: _isSubscribed ? 'Assinatura Ativa (Editar Detalhes)' : 'Ativar Assinatura com 5% OFF',
              icon: _isSubscribed ? Icons.check_circle_rounded : Icons.flash_on_rounded,
              isFlameAccent: !_isSubscribed,
              onPressed: _confirmSubscription,
            ),
            const SizedBox(height: 24),
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
