import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class AdminWhatsAppScreen extends ConsumerStatefulWidget {
  const AdminWhatsAppScreen({super.key});

  @override
  ConsumerState<AdminWhatsAppScreen> createState() => _AdminWhatsAppScreenState();
}

class _AdminWhatsAppScreenState extends ConsumerState<AdminWhatsAppScreen> {
  Timer? _pollTimer;
  bool _isLoading = true;
  String _status = 'connecting'; // 'connected', 'qr_ready', 'connecting', 'disconnected'
  String? _connectedPhone;
  String? _qrCodeBase64;
  String? _errorMessage;

  // Test form
  final _testPhoneController = TextEditingController();
  final _testMessageController = TextEditingController(
    text: 'Olá! Esta é uma mensagem de teste do BoraGás via Baileys WhatsApp 🚀',
  );
  bool _isSendingTest = false;
  String? _testResult;

  final String _backendBaseUrl = 'http://localhost:10000';

  @override
  void initState() {
    super.initState();
    _fetchWhatsAppStatus();
    // Polling a cada 3 segundos enquanto na tela
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _fetchWhatsAppStatus();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _testPhoneController.dispose();
    _testMessageController.dispose();
    super.dispose();
  }

  Future<void> _fetchWhatsAppStatus() async {
    try {
      final res = await http.get(Uri.parse('$_backendBaseUrl/api/v1/whatsapp/status'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          if (mounted) {
            setState(() {
              _status = data['status'] ?? 'disconnected';
              _connectedPhone = data['connectedPhone'];
              _qrCodeBase64 = data['qrCodeBase64'];
              _isLoading = false;
              _errorMessage = null;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _status = 'disconnected';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'disconnected';
          _errorMessage = 'Backend offline ou não acessível em $_backendBaseUrl';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestNewQrCode() async {
    setState(() => _isLoading = true);
    try {
      await http.post(Uri.parse('$_backendBaseUrl/api/v1/whatsapp/reconnect'));
      await Future.delayed(const Duration(milliseconds: 1500));
      await _fetchWhatsAppStatus();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendTestMessage() async {
    final phone = _testPhoneController.text.trim();
    final msg = _testMessageController.text.trim();
    if (phone.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o telefone com DDD e a mensagem.')),
      );
      return;
    }

    setState(() {
      _isSendingTest = true;
      _testResult = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_backendBaseUrl/api/v1/whatsapp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'message': msg}),
      );

      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() => _testResult = '✅ Mensagem enviada com sucesso para $phone!');
      } else {
        setState(() => _testResult = '❌ Falha: ${body['error'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      setState(() => _testResult = '❌ Erro de conexão com o backend: $e');
    } finally {
      if (mounted) setState(() => _isSendingTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text('Conexão Baileys WhatsApp'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar Status',
            onPressed: _fetchWhatsAppStatus,
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () => launchUrl(
              Uri.parse('$_backendBaseUrl/whatsapp'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Abrir QR no Navegador', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card Hero
            _buildStatusHeaderCard(),

            const SizedBox(height: 24),

            // QR Code Scanner Box (Quando aguardando conexão)
            if (_status == 'qr_ready') _buildQrScannerBox(),

            // Card Conectado (Quando já pareado)
            if (_status == 'connected') _buildConnectedBox(),

            // Card Conectando / Carregando
            if (_status == 'connecting' || _isLoading) _buildConnectingBox(),

            // Card Erro / Desconectado
            if (_status == 'disconnected' && !_isLoading) _buildDisconnectedBox(),

            const SizedBox(height: 28),

            // Formulário de Teste de Disparo
            _buildTestSenderCard(),

            const SizedBox(height: 28),

            // Modelos de Mensagens Ativos
            _buildTemplatesPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeaderCard() {
    Color badgeColor;
    String statusTitle;
    IconData badgeIcon;

    if (_status == 'connected') {
      badgeColor = const Color(0xFF25D366);
      statusTitle = 'ONLINE & CONECTADO';
      badgeIcon = Icons.check_circle_rounded;
    } else if (_status == 'qr_ready') {
      badgeColor = const Color(0xFFF59E0B);
      statusTitle = 'AGUARDANDO LEITURA DO QR CODE';
      badgeIcon = Icons.qr_code_scanner_rounded;
    } else if (_status == 'connecting') {
      badgeColor = const Color(0xFF3B82F6);
      statusTitle = 'INICIANDO SOCKET BAILEYS...';
      badgeIcon = Icons.sync_rounded;
    } else {
      badgeColor = AppColors.error;
      statusTitle = 'DESCONECTADO';
      badgeIcon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _status == 'connected'
                      ? 'WhatsApp Oficial do BoraGás Pareado'
                      : 'Notificações Automáticas de Pedidos via Baileys',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_connectedPhone != null)
                  Text(
                    'Número: +$_connectedPhone',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: _requestNewQrCode,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reiniciar Bot', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildQrScannerBox() {
    ImageProvider? qrImage;
    if (_qrCodeBase64 != null && _qrCodeBase64!.contains(',')) {
      try {
        final rawBase64 = _qrCodeBase64!.split(',')[1];
        qrImage = MemoryImage(base64Decode(rawBase64));
      } catch (_) {}
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Escaneie o QR Code abaixo com seu WhatsApp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'O código é atualizado automaticamente a cada poucos segundos.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Imagem do QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: qrImage != null
                  ? Image(image: qrImage, width: 240, height: 240, fit: BoxFit.contain)
                  : const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
            const SizedBox(height: 20),

            // Instruções de Escaneamento
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Como conectar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildStepRow('1', 'Abra o WhatsApp no seu celular'),
                  _buildStepRow('2', 'Toque em Configurações (ou 3 pontinhos) ➔ Aparelhos Conectados'),
                  _buildStepRow('3', 'Toque em "Conectar um Aparelho"'),
                  _buildStepRow('4', 'Aponte a câmera para o QR Code acima'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF25D366),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildConnectedBox() {
    return Card(
      color: const Color(0xFFECFDF5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFA7F3D0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 54),
            const SizedBox(height: 12),
            const Text(
              'WhatsApp Baileys Operacional 🚀',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
            const SizedBox(height: 6),
            Text(
              'Sessão ativa e persistida. Sempre que um pedido for criado ou despachado, mensagens transacionais serão enviadas automaticamente para o cliente e lojista.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.green.shade800),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
              onPressed: _requestNewQrCode,
              icon: const Icon(Icons.link_off_rounded, size: 16),
              label: const Text('Desconectar / Trocar de Número'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingBox() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Iniciando conexão com os servidores do WhatsApp...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'O QR Code aparecerá aqui em alguns segundos.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectedBox() {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Text(
                  'Serviço Baileys em espera',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Clique no botão abaixo para inicializar o socket e gerar um novo QR Code.',
              style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _requestNewQrCode,
              child: const Text('Iniciar Conexão'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSenderCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 20),
                SizedBox(width: 8),
                Text('Testar Disparo de Mensagem WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Envie uma mensagem direta para qualquer número para comprovar o funcionamento do Baileys:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefone do Destinatário com DDD',
                hintText: '11987654321',
                prefixIcon: const Icon(Icons.phone_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _testMessageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Mensagem de Teste',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_testResult != null)
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  )
                else
                  const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isSendingTest ? null : _sendTestMessage,
                  icon: _isSendingTest
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Enviar WhatsApp Teste', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesPreviewCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Modelos de Mensagens Transacionais Ativas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            _buildTemplateTile(
              title: '📦 Novo Pedido Criado',
              body: '🔥 BoraGás - Pedido Confirmado!\nPedido #BG-8310\nCódigo PIN de Entrega: 8310 (Informe ao entregador)',
            ),
            const SizedBox(height: 8),
            _buildTemplateTile(
              title: '🛵 Pedido Saiu para Entrega',
              body: '🛵 Seu pedido está a caminho!\nEntregador: Marcos Oliveira (Moto 160)\nRastreie no mapa ao vivo...',
            ),
            const SizedBox(height: 8),
            _buildTemplateTile(
              title: '✅ Entrega Concluída',
              body: '✅ Entrega Realizada com Sucesso!\nObrigado por comprar com a BoraGás.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateTile({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
