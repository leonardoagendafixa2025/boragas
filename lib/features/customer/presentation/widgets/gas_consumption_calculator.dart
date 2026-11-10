import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class GasConsumptionCalculatorSheet extends StatefulWidget {
  final VoidCallback onOrderNow;

  const GasConsumptionCalculatorSheet({super.key, required this.onOrderNow});

  @override
  State<GasConsumptionCalculatorSheet> createState() =>
      _GasConsumptionCalculatorSheetState();
}

class _GasConsumptionCalculatorSheetState
    extends State<GasConsumptionCalculatorSheet> {
  int _familySize = 3; // Pessoas na casa
  String _cookingFrequency = 'almoço e jantar'; // 'raro', 'almoço e jantar', 'intenso'
  int _daysSinceInstalled = 25; // Dias desde que comprou o último

  int _estimateTotalDays() {
    int baseDays = 55;
    if (_familySize == 1) baseDays = 85;
    if (_familySize == 2) baseDays = 65;
    if (_familySize == 3) baseDays = 48;
    if (_familySize == 4) baseDays = 38;
    if (_familySize >= 5) baseDays = 28;

    if (_cookingFrequency == 'raro') baseDays = (baseDays * 1.35).round();
    if (_cookingFrequency == 'intenso') baseDays = (baseDays * 0.75).round();

    return baseDays;
  }

  int get _remainingDays {
    final total = _estimateTotalDays();
    final rem = total - _daysSinceInstalled;
    return rem.clamp(0, total);
  }

  double get _percentageRemaining {
    final total = _estimateTotalDays();
    return (_remainingDays / total).clamp(0.0, 1.0);
  }

  Color get _statusColor {
    if (_percentageRemaining > 0.4) return AppColors.success;
    if (_percentageRemaining > 0.15) return const Color(0xFFFFAB00);
    return AppColors.error;
  }

  String get _statusText {
    if (_percentageRemaining > 0.4) return 'Nível Seguro de Gás';
    if (_percentageRemaining > 0.15) return 'Atenção: Gás na Reserva!';
    return 'Alerta Crítico: Risco de Acabar Hoje!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calculadora de Duração do Gás',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Evite ficar sem fogo no meio da refeição',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Visual Gauge / Battery
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _statusColor,
                        ),
                      ),
                      Text(
                        '${(_percentageRemaining * 100).round()}% restante',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _percentageRemaining,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dias Restantes Estimados', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '~$_remainingDays dias de uso',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _statusColor),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Duração Total Média', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '${_estimateTotalDays()} dias no seu perfil',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Controls
            const Text(
              'Quantas pessoas moram na sua residência?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1, 2, 3, 4, 5].map((qty) {
                final isSel = _familySize == qty;
                return InkWell(
                  onTap: () => setState(() => _familySize = qty),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 54,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        qty == 5 ? '5+' : '$qty',
                        style: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            const Text(
              'Com que frequência utilizam o fogão e forno?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFreqButton('Raramente', 'raro'),
                const SizedBox(width: 8),
                _buildFreqButton('Almoço & Jantar', 'almoço e jantar'),
                const SizedBox(width: 8),
                _buildFreqButton('Uso Intenso', 'intenso'),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Instalado há quantos dias?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  '$_daysSinceInstalled dias',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
            Slider(
              value: _daysSinceInstalled.toDouble(),
              min: 0,
              max: 90,
              divisions: 90,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _daysSinceInstalled = val.round()),
            ),

            const SizedBox(height: 20),

            AppButton(
              label: _remainingDays <= 10
                  ? 'Pedir Gás Agora com 1 Clique ⚡'
                  : 'Agendar Troca Preventiva',
              isFlameAccent: _remainingDays <= 10,
              icon: Icons.local_fire_department_rounded,
              onPressed: () {
                Navigator.pop(context);
                widget.onOrderNow();
              },
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/subscription-club');
                },
                icon: const Icon(Icons.loyalty_rounded, color: AppColors.accentFlame, size: 16),
                label: const Text(
                  'Automatizar no Clube BoraGás (5% OFF garantido)',
                  style: TextStyle(color: AppColors.accentFlame, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreqButton(String label, String value) {
    final isSel = _cookingFrequency == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _cookingFrequency = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSel ? Colors.white : AppColors.textPrimary,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
