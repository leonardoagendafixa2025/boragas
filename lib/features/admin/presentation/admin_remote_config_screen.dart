import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/widgets/app_button.dart';

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
        content: Text('Configurações remotas publicadas! Sincronizadas instantaneamente com os apps.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Remote Config (Flags Visuais)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Preview of Current Header Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PREVIEW DO AVISO NO HEADER DO CLIENTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: config.seasonalAccentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
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

            const SizedBox(height: 20),

            // Form inputs
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _bannerTextController,
                      decoration: const InputDecoration(
                        labelText: 'Texto do Banner de Alerta / Feriado / Notícia',
                        hintText: 'Ex.: Operação especial de feriado com entrega em 20 min',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      title: const Text('Exibir Banner de Alerta na Home'),
                      subtitle: const Text('Ativa ou oculta a faixa de comunicado no topo do app'),
                      value: config.showAnnouncementBanner,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        ref.read(remoteConfigProvider.notifier).toggleAnnouncement();
                      },
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: _commissionController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Taxa de Comissão Padrão da Plataforma (%)',
                        suffixText: '%',
                        helperText: 'Aplicada como padrão para novas distribuidoras cadastradas',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _deliveryMinutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tempo Médio Global Estimado (Minutos)',
                        suffixText: 'min',
                      ),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      title: const Text('Modo Manutenção'),
                      subtitle: const Text('Bloqueia a realização de novos pedidos temporariamente'),
                      value: config.isMaintenanceMode,
                      activeThumbColor: AppColors.error,
                      onChanged: (val) {
                        ref.read(remoteConfigProvider.notifier).toggleMaintenance();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            AppButton(
              label: 'Publicar Alterações no Remote Config',
              icon: Icons.cloud_upload_rounded,
              onPressed: _saveRemoteConfig,
            ),
          ],
        ),
      ),
    );
  }
}
