import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';

class AdminRemoteConfigScreen extends ConsumerStatefulWidget {
  const AdminRemoteConfigScreen({super.key});

  @override
  ConsumerState<AdminRemoteConfigScreen> createState() =>
      _AdminRemoteConfigScreenState();
}

class _AdminRemoteConfigScreenState
    extends ConsumerState<AdminRemoteConfigScreen> {
  late TextEditingController _bannerTextController;
  late TextEditingController _commissionController;
  late TextEditingController _deliveryMinutesController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(remoteConfigProvider);
    _bannerTextController =
        TextEditingController(text: config.announcementBannerText);
    _commissionController = TextEditingController(
        text: config.defaultPlatformCommissionPercent.toString());
    _deliveryMinutesController = TextEditingController(
        text: config.estimatedAverageDeliveryMinutes.toString());
  }

  @override
  void dispose() {
    _bannerTextController.dispose();
    _commissionController.dispose();
    _deliveryMinutesController.dispose();
    super.dispose();
  }

  void _saveRemoteConfig() {
    HapticFeedback.mediumImpact();
    final newText = _bannerTextController.text.trim();
    final newComm = double.tryParse(_commissionController.text) ?? 8.0;
    final newTime = int.tryParse(_deliveryMinutesController.text) ?? 25;

    ref.read(remoteConfigProvider.notifier).updateConfig(
          announcementBannerText: newText,
          defaultPlatformCommissionPercent: newComm,
          estimatedAverageDeliveryMinutes: newTime,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações remotas publicadas com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Ajustes & Remote Config',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Configurações operacionais e avisos globais sincronizados em tempo real',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Live Preview do Banner de Alerta
            BoraCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PREVIEW DO AVISO NO TOPO DO CLIENTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: config.seasonalAccentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: config.seasonalAccentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, size: 18, color: AppColors.accentFlame),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            config.announcementBannerText,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Formulário de Configurações
            BoraCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _bannerTextController,
                    decoration: InputDecoration(
                      labelText: 'Texto do Banner de Comunicado / Alerta',
                      hintText: 'Ex.: Operação especial de entrega turbo em até 20 min',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Exibir Banner de Alerta na Home', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: const Text('Ativa ou oculta a faixa de comunicado no topo do app', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: config.showAnnouncementBanner,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      ref.read(remoteConfigProvider.notifier).toggleAnnouncement();
                    },
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  TextField(
                    controller: _commissionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Taxa de Comissão Padrão (%)',
                      suffixText: '%',
                      helperText: 'Aplicada para novas distribuidoras cadastradas',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deliveryMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Tempo Médio Global Estimado (Minutos)',
                      suffixText: 'min',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  SwitchListTile(
                    title: const Text('Modo Manutenção Geral', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: const Text('Bloqueia novos pedidos temporariamente em caso de contingência', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: config.isMaintenanceMode,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.error,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      ref.read(remoteConfigProvider.notifier).toggleMaintenance();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: BoraButton.flame(
                text: 'Publicar Alterações no Sistema',
                icon: Icons.cloud_upload_rounded,
                height: 50,
                onPressed: _saveRemoteConfig,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
