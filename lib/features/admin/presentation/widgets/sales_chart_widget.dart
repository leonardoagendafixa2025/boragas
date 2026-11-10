import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class DailyMetric {
  final String dayName;
  final double gmv;
  final double commission;
  final int ordersCount;

  const DailyMetric({
    required this.dayName,
    required this.gmv,
    required this.commission,
    required this.ordersCount,
  });
}

class SalesChartWidget extends StatefulWidget {
  const SalesChartWidget({super.key});

  @override
  State<SalesChartWidget> createState() => _SalesChartWidgetState();
}

class _SalesChartWidgetState extends State<SalesChartWidget> {
  int _selectedPeriodIndex = 0; // 0: 7 dias, 1: 15 dias, 2: 30 dias
  int? _hoveredBarIndex;

  final List<DailyMetric> _last7Days = const [
    DailyMetric(dayName: 'Seg', gmv: 4200.0, commission: 336.0, ordersCount: 40),
    DailyMetric(dayName: 'Ter', gmv: 5100.0, commission: 408.0, ordersCount: 48),
    DailyMetric(dayName: 'Qua', gmv: 6300.0, commission: 504.0, ordersCount: 60),
    DailyMetric(dayName: 'Qui', gmv: 5800.0, commission: 464.0, ordersCount: 55),
    DailyMetric(dayName: 'Sex', gmv: 7400.0, commission: 592.0, ordersCount: 71),
    DailyMetric(dayName: 'Sáb', gmv: 9800.0, commission: 784.0, ordersCount: 94),
    DailyMetric(dayName: 'Dom', gmv: 8200.0, commission: 656.0, ordersCount: 78),
  ];

  @override
  Widget build(BuildContext context) {
    final maxGmv = _last7Days.map((d) => d.gmv).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Period Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURVA DE VENDAS & COMISSÕES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Evolução dos Últimos 7 Dias',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildPeriodBtn('7D', 0),
                    _buildPeriodBtn('15D', 1),
                    _buildPeriodBtn('30D', 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Canvas
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_last7Days.length, (index) {
                final item = _last7Days[index];
                final heightFactor = item.gmv / maxGmv;
                final isSelected = _hoveredBarIndex == index;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _hoveredBarIndex = isSelected ? null : index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'R\$${(item.gmv / 1000).toStringAsFixed(1)}k',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // GMV Bar
                              Container(
                                width: double.infinity,
                                height: 130 * heightFactor,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              // Commission segment (8%)
                              Container(
                                width: double.infinity,
                                height: (130 * heightFactor) * 0.25,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accentFlame
                                      : AppColors.accentFlame.withValues(alpha: 0.7),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.dayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),

          // Legend and Summary Insights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('GMV Total Lojas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.accentFlame,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Comissão BoraGás (8%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const Text(
                'Pico: Sábado (94 ped.)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Peak Hours & Mix mini-grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Horários de Maior Demanda',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Pico 1: 10h45 às 13h15 (Almoço) • Pico 2: 17h30 às 20h00 (Jantar)',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'GLP 13kg (68%)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBtn(String label, int index) {
    final isSelected = _selectedPeriodIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriodIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
