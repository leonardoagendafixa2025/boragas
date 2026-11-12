import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';

class PushCampaignRecord {
  final String id;
  final String title;
  final String message;
  final String? coupon;
  final String target;
  final int recipients;
  final DateTime sentAt;
  final String status;

  const PushCampaignRecord({
    required this.id,
    required this.title,
    required this.message,
    this.coupon,
    required this.target,
    required this.recipients,
    required this.sentAt,
    required this.status,
  });
}

class AdminPushMarketingScreen extends ConsumerStatefulWidget {
  const AdminPushMarketingScreen({super.key});

  @override
  ConsumerState<AdminPushMarketingScreen> createState() =>
      _AdminPushMarketingScreenState();
}

class _AdminPushMarketingScreenState
    extends ConsumerState<AdminPushMarketingScreen> {
  final TextEditingController _titleController = TextEditingController(
    text: '🔥 Quinta do Gás: R\$ 15 OFF no seu Botijão!',
  );
  final TextEditingController _messageController = TextEditingController(
    text:
        'Aproveite a entrega turbo de gás de cozinha e água mineral no seu portão. Use o cupom BORA10.',
  );
  final TextEditingController _couponController =
      TextEditingController(text: 'BORA10');

  String _selectedTarget = 'all';
  bool _isSending = false;

  final List<PushCampaignRecord> _campaignHistory = [
    PushCampaignRecord(
      id: 'camp-01',
      title: '⚡ Entrega Turbo Ativada na sua Região!',
      message:
          'Seu botijão P13 entregue em até 25 minutos pelas melhores distribuidoras parceiras.',
      coupon: 'BORAGAS10',
      target: 'Todos os Usuários',
      recipients: 1420,
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: 'Entregue',
    ),
    PushCampaignRecord(
      id: 'camp-02',
      title: '💧 Chegou Água Mineral 20L Lacrada',
      message:
          'Galões retornáveis higienizados e lacrados direto da fonte com preço de atacado.',
      coupon: null,
      target: 'Clientes Ativos',
      recipients: 890,
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Entregue',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCampaignHistoryFromSupabase();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaignHistoryFromSupabase() async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) return;
    try {
      final res = await SupabaseService.client
          .from('push_campaigns')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);

      if (res.isNotEmpty && mounted) {
        final list = res.map((item) {
          return PushCampaignRecord(
            id: item['id'].toString(),
            title: item['title'] ?? '',
            message: item['message'] ?? '',
            coupon: item['coupon_code'],
            target: item['target_audience'] == 'all'
                ? 'Todos os Usuários'
                : item['target_audience'] ?? 'Geral',
            recipients: (item['recipients_count'] as num?)?.toInt() ?? 0,
            sentAt: DateTime.tryParse(item['created_at'].toString()) ??
                DateTime.now(),
            status: item['status'] == 'sent' ? 'Entregue' : 'Falha',
          );
        }).toList();

        setState(() {
          _campaignHistory.clear();
          _campaignHistory.addAll(list);
        });
      }
    } catch (_) {}
  }

  Future<void> _sendBroadcastNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final coupon = _couponController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o título e a mensagem da notificação.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Modal de Confirmação antes do Disparo em Massa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: AppColors.accentFlame),
            SizedBox(width: 8),
            Text(
              'Confirmar Disparo em Massa',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta notificação push será transmitida via OneSignal para TODOS os celulares Android e navegadores PWA inscritos na plataforma BoraGás.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentFlame,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Disparar Agora',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    final result = await PushNotificationService.sendMarketingBroadcast(
      title: title,
      message: message,
      couponCode: coupon.isNotEmpty ? coupon : null,
      targetAudience: _selectedTarget,
    );

    setState(() => _isSending = false);

    if (!mounted) return;

    if (result.success) {
      final newRecord = PushCampaignRecord(
        id: result.notificationId ?? 'camp-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        coupon: coupon.isNotEmpty ? coupon : null,
        target: _selectedTarget == 'all'
            ? 'Todos os Usuários'
            : _selectedTarget,
        recipients: result.recipientsCount > 0 ? result.recipientsCount : 1,
        sentAt: DateTime.now(),
        status: 'Entregue',
      );

      setState(() {
        _campaignHistory.insert(0, newRecord);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Notificação push disparada com sucesso via OneSignal! (ID: ${result.notificationId})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result.errorMessage ?? 'Falha ao conectar com OneSignal.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.flameGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentFlame.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Central de Push & Marketing',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Disparo de notificações nativas no Android (tela bloqueada) e PWA',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_tethering_rounded,
                          color: AppColors.success, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'OneSignal Conectado & Operante',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Card com Credenciais Ativas do OneSignal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.key_rounded,
                        color: AppColors.gasCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OneSignal App ID Oficial Ativo',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        SizedBox(height: 2),
                        SelectableText(
                          PushNotificationService.defaultAppId,
                          style: TextStyle(
                            color: AppColors.gasCyan,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: const Text(
                      'REST API Key v2 Ativa',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Layout Principal: Formulário à Esquerda + Preview Tela Bloqueada à Direita
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildFormCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildPreviewCard()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildPreviewCard(),
                ],
              );
            }),

            const SizedBox(height: 32),

            // Histórico de Notificações Enviadas
            BoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Histórico de Campanhas Enviadas',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Atualizar Histórico',
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white70, size: 18),
                        onPressed: _loadCampaignHistoryFromSupabase,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_campaignHistory.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: const Text(
                        'Nenhuma campanha enviada ainda.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _campaignHistory.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFF334155), height: 16),
                      itemBuilder: (context, index) {
                        final item = _campaignHistory[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentFlame
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.campaign_rounded,
                                  color: AppColors.accentFlame, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.success
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.status,
                                          style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.message,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Text(
                                        'Público: ${item.target}',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11),
                                      ),
                                      if (item.coupon != null)
                                        Text(
                                          '• Cupom: ${item.coupon}',
                                          style: const TextStyle(
                                              color: AppColors.accentFlame,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      Text(
                                        '• ${item.recipients} destinatários',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return BoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_notifications_rounded,
                  color: AppColors.accentFlame, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nova Campanha de Marketing Push',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _titleController,
            label: 'Título da Notificação',
            hint: 'Ex: 🔥 Super Promoção BoraGás!',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _messageController,
            label: 'Mensagem da Notificação',
            hint: 'Ex: Seu botijão com R\$ 10 OFF entregue em 20 minutos.',
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 450;
            if (isSmall) {
              return Column(
                children: [
                  _buildTextField(
                    controller: _couponController,
                    label: 'Cupom de Desconto (Opcional)',
                    hint: 'Ex: BORA10',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _buildTargetAudienceDropdown(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _couponController,
                    label: 'Cupom de Desconto (Opcional)',
                    hint: 'Ex: BORA10',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTargetAudienceDropdown(),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: BoraButton.flame(
              text: _isSending
                  ? 'Disparando via OneSignal...'
                  : 'Disparar Push Notification em Massa',
              icon: Icons.send_rounded,
              isLoading: _isSending,
              height: 48,
              onPressed: _isSending ? null : _sendBroadcastNotification,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAudienceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Público-Alvo',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTarget,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Todos os Usuários (Android + PWA)'),
                ),
                DropdownMenuItem(
                  value: 'active',
                  child: Text('Clientes Ativos (Últimos 30 dias)'),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Text('Clientes Inativos (+ 30 dias)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTarget = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return BoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_android_rounded,
                  color: AppColors.gasCyan, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preview na Tela Bloqueada do Cliente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mockup de Tela Bloqueada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF020617)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                // Barra de status mock
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10:45',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Icon(Icons.wifi, color: Colors.white70, size: 12),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full, color: Colors.white70, size: 12),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card da Notificação Push no Celular
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF475569)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: AppColors.flameGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'BoraGás',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Agora',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _titleController.text.isNotEmpty
                            ? _titleController.text
                            : 'Título da notificação',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _messageController.text.isNotEmpty
                            ? _messageController.text
                            : 'Mensagem descritiva da notificação push.',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      if (_couponController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentFlame.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accentFlame),
                          ),
                          child: Text(
                            'Cupom: ${_couponController.text.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.accentFlame,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aparece na tela bloqueada e no painel do Android/PWA com alerta sonoro',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
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
          maxLines: maxLines,
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
