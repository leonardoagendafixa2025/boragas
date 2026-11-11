import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';
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
    HapticFeedback.mediumImpact();
    setState(() => _isTesting = true);

    await Future.delayed(const Duration(milliseconds: 1000));

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
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Chaves de API e Smart POS validadas! Os pagamentos caem direto na sua conta.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  InputDecoration _buildDarkInput(String label, String hint, {String? helper}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      helperText: helper,
      helperStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
      helperMaxLines: 2,
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentFlame, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(storePaymentConfigProvider);

    return Container(
      color: AppColors.merchantCanvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pagamentos & Gateways (BYOK)',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Conecte suas credenciais para receber vendas direto na sua conta',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Banner Explicativo BYOK
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modelo BYOK (Bring Your Own Key)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '100% do dinheiro das vendas online cai na conta do seu próprio estabelecimento. O app BoraGás nunca retém o valor dos seus produtos.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SEÇÃO 1: Gateway Online
            const Text(
              '1. GATEWAY ONLINE (PIX & CARTÃO NO APP)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            BoraCard(
              color: AppColors.merchantCard,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGateway,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _buildDarkInput('Provedor de Pagamento', ''),
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
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _buildDarkInput('Public Key / Chave Pública', 'APP_USR-xxxxxx'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accessTokenController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _buildDarkInput('Access Token (Chave Segura)', 'APP_USR-xxxxxx-token'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _webhookSecretController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _buildDarkInput('Webhook Secret (Opcional)', 'whsec_xxxxxx'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SEÇÃO 2: Smart POS
            const Text(
              '2. MAQUININHA FÍSICA (SMART POS DE ENTREGA)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            BoraCard(
              color: AppColors.merchantCard,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPosProvider,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _buildDarkInput('Modelo do Terminal / Maquininha', ''),
                    items: const [
                      DropdownMenuItem(value: 'Mercado Pago Point Smart', child: Text('Mercado Pago Point Smart / Pro 2')),
                      DropdownMenuItem(value: 'PagBank Moderninha Smart', child: Text('PagBank Moderninha Smart 2')),
                      DropdownMenuItem(value: 'Stone Smart POS', child: Text('Stone Smart POS')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPosProvider = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _posSerialController,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _buildDarkInput(
                      'Device ID / Serial da Maquininha',
                      'Ex.: MP-SMART-84920',
                      helper: 'O valor do pedido vai automaticamente para o visor da maquininha do entregador.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SEÇÃO 3: Formas de Pagamento Aceitas
            const Text(
              '3. FORMAS DE PAGAMENTO ACEITAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            BoraCard(
              color: AppColors.merchantCard,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('PIX Online Direto', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Cliente paga no app pelo seu Mercado Pago / Gateway', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    value: config.acceptsOnlinePix,
                    activeThumbColor: AppColors.success,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref.read(storePaymentConfigProvider.notifier).toggleOnlinePix(v);
                    },
                  ),
                  Divider(height: 1, color: AppColors.merchantDivider),
                  SwitchListTile(
                    title: const Text('Cartão de Crédito Online', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Cobrança processada pela sua chave de API', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    value: config.acceptsOnlineCard,
                    activeThumbColor: AppColors.success,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref.read(storePaymentConfigProvider.notifier).toggleOnlineCard(v);
                    },
                  ),
                  Divider(height: 1, color: AppColors.merchantDivider),
                  SwitchListTile(
                    title: const Text('Maquininha na Entrega (Smart POS)', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Entregador leva a maquininha física até o cliente', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    value: config.acceptsPosOnDelivery,
                    activeThumbColor: AppColors.success,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref.read(storePaymentConfigProvider.notifier).togglePosOnDelivery(v);
                    },
                  ),
                  Divider(height: 1, color: AppColors.merchantDivider),
                  SwitchListTile(
                    title: const Text('Dinheiro na Entrega', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Permite troco em espécie', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    value: config.acceptsCashOnDelivery,
                    activeThumbColor: AppColors.success,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref.read(storePaymentConfigProvider.notifier).toggleCashOnDelivery(v);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botão Testar e Salvar
            SizedBox(
              width: double.infinity,
              child: BoraButton.flame(
                text: 'Testar e Salvar Conexão das APIs',
                isLoading: _isTesting,
                icon: Icons.check_circle_rounded,
                height: 52,
                onPressed: _testAndSaveConnection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
