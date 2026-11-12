import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/store_model.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';
import '../providers/merchant_providers.dart';

class MerchantDeliveryConfigScreen extends ConsumerStatefulWidget {
  const MerchantDeliveryConfigScreen({super.key});

  @override
  ConsumerState<MerchantDeliveryConfigScreen> createState() =>
      _MerchantDeliveryConfigScreenState();
}

class _MerchantDeliveryConfigScreenState
    extends ConsumerState<MerchantDeliveryConfigScreen> {
  late TextEditingController _baseFeeController;
  late TextEditingController _feePerKmController;
  late TextEditingController _maxRadiusController;
  late TextEditingController _freeThresholdController;

  // Gerenciamento de bairros
  late TextEditingController _newNeighborhoodNameController;
  late TextEditingController _newNeighborhoodFeeController;
  late Map<String, double> _neighborhoodFees;
  late bool _isNeighborhoodPricingEnabled;

  // Simulador de teste ao vivo
  final TextEditingController _simNeighborhoodController =
      TextEditingController();
  final TextEditingController _simKmController =
      TextEditingController(text: '3.5');
  final TextEditingController _simSubtotalController =
      TextEditingController(text: '120.00');
  DeliveryFeeResult? _simulationResult;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final store = ref.read(currentMerchantStoreProvider);
    _baseFeeController = TextEditingController(
      text: store.deliveryFee.toStringAsFixed(2),
    );
    _feePerKmController = TextEditingController(
      text: store.feePerKm.toStringAsFixed(2),
    );
    _maxRadiusController = TextEditingController(
      text: store.maxDeliveryRadiusKm.toStringAsFixed(1),
    );
    _freeThresholdController = TextEditingController(
      text: store.freeDeliveryThreshold != null
          ? store.freeDeliveryThreshold!.toStringAsFixed(2)
          : '',
    );

    _neighborhoodFees = Map.from(store.neighborhoodFees);
    _isNeighborhoodPricingEnabled = store.isNeighborhoodPricingEnabled;

    _newNeighborhoodNameController = TextEditingController();
    _newNeighborhoodFeeController = TextEditingController(text: '5.00');

    _runSimulation();
  }

  @override
  void dispose() {
    _baseFeeController.dispose();
    _feePerKmController.dispose();
    _maxRadiusController.dispose();
    _freeThresholdController.dispose();
    _newNeighborhoodNameController.dispose();
    _newNeighborhoodFeeController.dispose();
    _simNeighborhoodController.dispose();
    _simKmController.dispose();
    _simSubtotalController.dispose();
    super.dispose();
  }

  void _addOrUpdateNeighborhood() {
    final name = _newNeighborhoodNameController.text.trim();
    final feeText =
        _newNeighborhoodFeeController.text.replaceAll(',', '.').trim();
    final fee = double.tryParse(feeText);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do bairro atendido.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (fee == null || fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor de frete válido para o bairro.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _neighborhoodFees[name] = fee;
      _newNeighborhoodNameController.clear();
      _newNeighborhoodFeeController.text = '5.00';
    });

    _runSimulation();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bairro "$name" configurado com frete de R\$ ${fee.toStringAsFixed(2).replaceAll('.', ',')}',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeNeighborhood(String name) {
    HapticFeedback.mediumImpact();
    setState(() {
      _neighborhoodFees.remove(name);
    });
    _runSimulation();
  }

  void _runSimulation() {
    final baseFee = double.tryParse(
            _baseFeeController.text.replaceAll(',', '.').trim()) ??
        0.0;
    final feePerKm = double.tryParse(
            _feePerKmController.text.replaceAll(',', '.').trim()) ??
        1.50;
    final maxRadius = double.tryParse(
            _maxRadiusController.text.replaceAll(',', '.').trim()) ??
        15.0;
    final freeThreshold = double.tryParse(
        _freeThresholdController.text.replaceAll(',', '.').trim());

    final tempStore = StoreModel(
      id: 'preview',
      name: 'Preview',
      cnpj: '00',
      phone: '',
      logoUrl: '',
      coverUrl: '',
      address: '',
      distanceKm: 2.0,
      rating: 5.0,
      reviewsCount: 1,
      estimatedTimeMin: 25,
      deliveryFee: baseFee,
      feePerKm: feePerKm,
      maxDeliveryRadiusKm: maxRadius,
      freeDeliveryThreshold: freeThreshold,
      neighborhoodFees: _neighborhoodFees,
      isNeighborhoodPricingEnabled: _isNeighborhoodPricingEnabled,
    );

    final simKm = double.tryParse(
            _simKmController.text.replaceAll(',', '.').trim()) ??
        3.5;
    final simSubtotal = double.tryParse(
            _simSubtotalController.text.replaceAll(',', '.').trim()) ??
        120.00;
    final simNeighborhood = _simNeighborhoodController.text.trim();

    setState(() {
      _simulationResult = tempStore.calculateDeliveryFee(
        neighborhood: simNeighborhood.isNotEmpty ? simNeighborhood : null,
        clientDistanceKm: simKm,
        subtotal: simSubtotal,
      );
    });
  }

  Future<void> _saveDeliveryRules() async {
    final baseFee = double.tryParse(
            _baseFeeController.text.replaceAll(',', '.').trim()) ??
        0.0;
    final feePerKm = double.tryParse(
            _feePerKmController.text.replaceAll(',', '.').trim()) ??
        1.50;
    final maxRadius = double.tryParse(
            _maxRadiusController.text.replaceAll(',', '.').trim()) ??
        15.0;
    final freeThreshold = double.tryParse(
        _freeThresholdController.text.replaceAll(',', '.').trim());

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final success = await ref
        .read(currentMerchantStoreProvider.notifier)
        .updateDeliveryConfig(
          baseDeliveryFee: baseFee,
          feePerKm: feePerKm,
          maxDeliveryRadiusKm: maxRadius,
          freeDeliveryThreshold: freeThreshold,
          neighborhoodFees: _neighborhoodFees,
          isNeighborhoodPricingEnabled: _isNeighborhoodPricingEnabled,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  success
                      ? '✅ Regras de frete e bairros salvas com sucesso no banco de dados!'
                      : 'Regras atualizadas localmente.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: success ? AppColors.success : AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(currentMerchantStoreProvider);

    return Scaffold(
      backgroundColor: AppColors.merchantCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentFlame.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: AppColors.accentFlame,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gestão de Frete da Distribuidora',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  store.name,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                BoraButton.flame(
                  text: _isSaving ? 'Salvando...' : 'Salvar Regras',
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  height: 44,
                  onPressed: _isSaving ? null : _saveDeliveryRules,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Banner explicativo de autonomia da Distribuidora
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.store_mall_directory_rounded,
                    color: AppColors.accentFlame,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sua Distribuidora tem controle total do frete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Defina taxas personalizadas por bairro atendido e regras dinâmicas por KM rodado com raio máximo de cobertura. Quando o cliente digitar o endereço ou CEP, a plataforma calculará exatamente conforme os seus valores.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card 1: Configuração por KM e Raio
            BoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '1. Precificação por Distância (KM)',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 600;
                    if (isSmall) {
                      return Column(
                        children: [
                          _buildTextField(
                            controller: _baseFeeController,
                            label: 'Taxa Base de Saída (R\$)',
                            hint: 'Ex: 0.00 ou 5.00',
                            onChanged: (_) => _runSimulation(),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _feePerKmController,
                            label: 'Valor Adicional por KM (R\$/km)',
                            hint: 'Ex: 1.50',
                            onChanged: (_) => _runSimulation(),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _maxRadiusController,
                            label: 'Raio Máximo de Entrega (KM)',
                            hint: 'Ex: 15.0',
                            onChanged: (_) => _runSimulation(),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _freeThresholdController,
                            label: 'Frete Grátis a partir de (R\$)',
                            hint: 'Opcional (ex: 150.00)',
                            onChanged: (_) => _runSimulation(),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _baseFeeController,
                                label: 'Taxa Base de Saída (R\$)',
                                hint: 'Ex: 0.00 ou 5.00',
                                onChanged: (_) => _runSimulation(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _feePerKmController,
                                label: 'Valor Adicional por KM (R\$/km)',
                                hint: 'Ex: 1.50',
                                onChanged: (_) => _runSimulation(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _maxRadiusController,
                                label: 'Raio Máximo de Atendimento (KM)',
                                hint: 'Ex: 15.0',
                                onChanged: (_) => _runSimulation(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _freeThresholdController,
                                label: 'Frete Grátis em Pedidos Acima de (R\$)',
                                hint: 'Deixe vazio para desativar (ex: 150.00)',
                                onChanged: (_) => _runSimulation(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card 2: Tabela de Frete por Bairros Atendidos
            BoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_city_rounded,
                              color: AppColors.accentFlame, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '2. Tabela de Frete Fixo por Bairro',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            _isNeighborhoodPricingEnabled
                                ? 'Prioridade Ativada'
                                : 'Desativada',
                            style: TextStyle(
                              color: _isNeighborhoodPricingEnabled
                                  ? AppColors.success
                                  : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _isNeighborhoodPricingEnabled,
                            activeThumbColor: AppColors.accentFlame,
                            onChanged: (val) {
                              setState(() => _isNeighborhoodPricingEnabled = val);
                              _runSimulation();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se o cliente for de um bairro cadastrado nesta tabela, o valor fixo será aplicado prioritariamente. Bairros não listados utilizarão o cálculo automático por KM.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Adicionar Novo Bairro
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 600;
                      if (isSmall) {
                        return Column(
                          children: [
                            _buildTextField(
                              controller: _newNeighborhoodNameController,
                              label: 'Nome do Bairro',
                              hint: 'Ex: Centro, Funcionários, Savassi...',
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _newNeighborhoodFeeController,
                              label: 'Taxa de Entrega (R\$)',
                              hint: 'Ex: 5.00 (0 para grátis)',
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: BoraButton(
                                text: 'Adicionar Bairro',
                                icon: Icons.add_location_alt_rounded,
                                height: 44,
                                variant: BoraButtonVariant.primaryRoyal,
                                onPressed: _addOrUpdateNeighborhood,
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              controller: _newNeighborhoodNameController,
                              label: 'Nome do Bairro',
                              hint: 'Ex: Centro, Funcionários, Savassi...',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _newNeighborhoodFeeController,
                              label: 'Taxa de Entrega (R\$)',
                              hint: 'Ex: 5.00 (0 para grátis)',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: BoraButton(
                              text: 'Adicionar Bairro',
                              icon: Icons.add_location_alt_rounded,
                              height: 44,
                              variant: BoraButtonVariant.primaryRoyal,
                              onPressed: _addOrUpdateNeighborhood,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Lista de Bairros Cadastrados
                  if (_neighborhoodFees.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF334155),
                            style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.map_rounded,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 40),
                          const SizedBox(height: 8),
                          const Text(
                            'Nenhum bairro cadastrado ainda.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Adicione os bairros principais onde sua distribuidora atua com taxa fixa.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_neighborhoodFees.length} Bairros Atendidos Configurados:',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _neighborhoodFees.entries.map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFF475569)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 16, color: AppColors.accentFlame),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: entry.value == 0
                                          ? AppColors.success.withValues(alpha: 0.2)
                                          : AppColors.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry.value == 0
                                          ? 'GRÁTIS'
                                          : 'R\$ ${entry.value.toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: TextStyle(
                                        color: entry.value == 0
                                            ? AppColors.success
                                            : AppColors.gasCyan,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16, color: Colors.white60),
                                    splashRadius: 16,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _removeNeighborhood(entry.key),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card 3: Simulador em Tempo Real para o Lojista testar
            BoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate_rounded,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '3. Simulador de Frete em Tempo Real (Teste sua Regra)',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digite um bairro ou distância para testar exatamente como o cliente verá o cálculo ao finalizar o pedido:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 600;
                    if (isSmall) {
                      return Column(
                        children: [
                          _buildTextField(
                            controller: _simNeighborhoodController,
                            label: 'Simular Bairro',
                            hint: 'Digite um bairro para testar',
                            onChanged: (_) => _runSimulation(),
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _simKmController,
                            label: 'Simular Distância (KM)',
                            hint: 'Ex: 4.2',
                            onChanged: (_) => _runSimulation(),
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _simSubtotalController,
                            label: 'Valor do Pedido (R\$)',
                            hint: 'Ex: 110.00',
                            onChanged: (_) => _runSimulation(),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _simNeighborhoodController,
                            label: 'Simular Bairro do Cliente',
                            hint: 'Digite um bairro para testar',
                            onChanged: (_) => _runSimulation(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _simKmController,
                            label: 'Simular Distância (KM)',
                            hint: 'Ex: 4.2',
                            onChanged: (_) => _runSimulation(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _simSubtotalController,
                            label: 'Valor do Pedido (R\$)',
                            hint: 'Ex: 110.00',
                            onChanged: (_) => _runSimulation(),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),

                  // Resultado da Simulação
                  if (_simulationResult != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _simulationResult!.isOutOfRange
                            ? AppColors.error.withValues(alpha: 0.15)
                            : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _simulationResult!.isOutOfRange
                              ? AppColors.error
                              : AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _simulationResult!.isOutOfRange
                                ? Icons.warning_rounded
                                : Icons.check_circle_rounded,
                            color: _simulationResult!.isOutOfRange
                                ? AppColors.error
                                : AppColors.success,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _simulationResult!.isOutOfRange
                                          ? 'FORA DA ÁREA DE ATENDIMENTO'
                                          : _simulationResult!.isFree
                                              ? 'FRETE GRÁTIS'
                                              : 'VALOR DO FRETE: R\$ ${_simulationResult!.fee.toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: TextStyle(
                                        color: _simulationResult!.isOutOfRange
                                            ? AppColors.error
                                            : _simulationResult!.isFree
                                                ? AppColors.success
                                                : Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF334155),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Método: ${_simulationResult!.pricingMethod}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _simulationResult!.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accentFlame),
            ),
          ),
        ),
      ],
    );
  }
}
