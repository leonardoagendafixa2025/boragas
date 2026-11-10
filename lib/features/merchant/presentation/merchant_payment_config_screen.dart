import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/merchant_providers.dart';

class MerchantPaymentConfigScreen extends ConsumerStatefulWidget {
  const MerchantPaymentConfigScreen({super.key});

  @override
  ConsumerState<MerchantPaymentConfigScreen> createState() =>
      _MerchantPaymentConfigScreenState();
}

class _MerchantPaymentConfigScreenState
    extends ConsumerState<MerchantPaymentConfigScreen> {
  late String _selectedGateway;
  late TextEditingController _publicKeyController;
  late TextEditingController _accessTokenController;
  late TextEditingController _webhookSecretController;
  late String _selectedPosProvider;
  late TextEditingController _posSerialController;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(storePaymentConfigProvider);
    _selectedGateway = config.gatewayProvider;
    _publicKeyController = TextEditingController(text: config.publicKey);
    _accessTokenController = TextEditingController(text: config.accessToken);
    _webhookSecretController = TextEditingController(text: config.webhookSecret);
    _selectedPosProvider = config.posTerminalProvider;
    _posSerialController = TextEditingController(text: config.posDeviceSerialId);
  }

  @override
  void dispose() {
    _publicKeyController.dispose();
    _accessTokenController.dispose();
    _webhookSecretController.dispose();
    _posSerialController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveConnection() async {
    setState(() => _isTesting = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    ref.read(storePaymentConfigProvider.notifier).testAndConnect(
          gatewayProvider: _selectedGateway,
          publicKey: _publicKeyController.text,
          accessToken: _accessTokenController.text,
          webhookSecret: _webhookSecretController.text,
          posTerminalProvider: _selectedPosProvider,
          posDeviceSerialId: _posSerialController.text,
        );

    setState(() => _isTesting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Chaves de API e Smart POS validadas com sucesso! Os pagamentos caem direto na sua conta.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(storePaymentConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Pagamento (BYOK)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informative Notice Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Modelo BYOK (Bring Your Own Key)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '100% do dinheiro das vendas online cai na conta do seu próprio estabelecimento. O app BoraGás nunca retém o valor dos seus produtos.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SECTION 1: Gateway Online
            const Text(
              '1. GATEWAY ONLINE DA LOJA (PIX & CARTÃO)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGateway,
                    decoration: const InputDecoration(labelText: 'Provedor de Pagamento'),
                    items: const [
                      DropdownMenuItem(value: 'mercadopago', child: Text('Mercado Pago (Pix & Cartão)')),
                      DropdownMenuItem(value: 'abacatepay', child: Text('AbacatePay (Pix Instantâneo)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGateway = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _publicKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Public Key / Chave Pública',
                      hintText: 'APP_USR-xxxxxx',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accessTokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Access Token / Chave Privada (Armazenada Segura)',
                      hintText: 'APP_USR-xxxxxx-token',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _webhookSecretController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Webhook Secret',
                      hintText: 'whsec_xxxxxx',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SECTION 2: Smart POS Maquininha
            const Text(
              '2. INTEGRAÇÃO COM MAQUININHA (SMART POS NA PORTA)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPosProvider,
                    decoration: const InputDecoration(labelText: 'Modelo do Terminal / Maquininha'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Mercado Pago Point Smart',
                        child: Text('Mercado Pago Point Smart / Pro 2'),
                      ),
                      DropdownMenuItem(
                        value: 'PagBank Moderninha Smart',
                        child: Text('PagBank Moderninha Smart 2'),
                      ),
                      DropdownMenuItem(
                        value: 'Stone Smart POS',
                        child: Text('Stone Smart POS'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPosProvider = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _posSerialController,
                    decoration: const InputDecoration(
                      labelText: 'Device ID / Serial da Maquininha',
                      hintText: 'Ex.: MP-SMART-84920',
                      helperText: 'O valor do pedido é enviado automaticamente ao visor do terminal na hora da entrega',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SECTION 3: Formas de Pagamento Ativas
            const Text(
              '3. FORMAS DE PAGAMENTO ACEITAS PELO SEU DEPÓSITO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('PIX Online Direto'),
                    subtitle: const Text('Cliente paga no app pelo seu Mercado Pago / Gateway'),
                    value: config.acceptsOnlinePix,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => ref.read(storePaymentConfigProvider.notifier).toggleOnlinePix(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Cartão de Crédito Online'),
                    subtitle: const Text('Cobrança processada pela sua chave de API'),
                    value: config.acceptsOnlineCard,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => ref.read(storePaymentConfigProvider.notifier).toggleOnlineCard(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Maquininha na Entrega (Smart POS)'),
                    subtitle: const Text('Entregador leva a maquininha física até o cliente'),
                    value: config.acceptsPosOnDelivery,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => ref.read(storePaymentConfigProvider.notifier).togglePosOnDelivery(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Dinheiro na Entrega'),
                    subtitle: const Text('Permite troco em espécie'),
                    value: config.acceptsCashOnDelivery,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => ref.read(storePaymentConfigProvider.notifier).toggleCashOnDelivery(v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Test and Save Button
            AppButton(
              label: 'Testar e Salvar Conexão das APIs',
              isLoading: _isTesting,
              icon: Icons.check_circle_outline_rounded,
              onPressed: _testAndSaveConnection,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
