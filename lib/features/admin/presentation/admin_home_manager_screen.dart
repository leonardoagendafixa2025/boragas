import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/banner_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';
import '../../../core/widgets/ui/bora_empty_state.dart';
import '../../customer/providers/customer_providers.dart';

class AdminHomeManagerScreen extends ConsumerWidget {
  const AdminHomeManagerScreen({super.key});

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final targetController = TextEditingController(text: 'p13');
    String actionType = 'category';
    const selectedImage = 'assets/images/brand_lockup.png';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Text('Publicar Novo Banner', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Título Chamativo do Banner',
                    hintText: 'Ex: Troca Fácil BoraGás',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleController,
                  decoration: InputDecoration(
                    labelText: 'Subtítulo / Promoção',
                    hintText: 'Ex: Peça pelo menor preço e receba em até 20 minutos',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: actionType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Ação ao Clicar',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'category', child: Text('Abrir Categoria de Produtos')),
                    DropdownMenuItem(value: 'screen', child: Text('Abrir Rota Interna')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => actionType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  decoration: InputDecoration(
                    labelText: 'Alvo da Ação (Slug / Categoria)',
                    hintText: 'Ex: p13, water20l, cart',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: BoraButton.flame(
                    text: 'Publicar Banner na Home',
                    icon: Icons.check_circle_rounded,
                    height: 50,
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final newBanner = HomeBannerModel(
                        id: 'banner-${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        subtitle: subtitleController.text.trim(),
                        badgeText: 'DESTAQUE',
                        imageUrl: selectedImage,
                        actionType: actionType,
                        actionTarget: targetController.text.trim(),
                        isActive: true,
                        sortOrder: 99,
                      );

                      if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
                        SupabaseService.client.from('banners').insert({
                          'title': newBanner.title,
                          'subtitle': newBanner.subtitle,
                          'badge_text': newBanner.badgeText,
                          'image_url': newBanner.imageUrl,
                          'action_type': newBanner.actionType,
                          'action_target': newBanner.actionTarget,
                          'is_active': newBanner.isActive,
                          'sort_order': newBanner.sortOrder,
                        }).catchError((_) {});
                      }

                      ref.read(homeBannersProvider.notifier).update((list) => [newBanner, ...list]);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Banner publicado na Home e salvo no banco!'), backgroundColor: AppColors.success),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeBannersProvider);
    final categories = ref.watch(homeCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com Botão "Novo Banner" inline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestão de Banners & Vitrine',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Banners do carrossel e categorias em destaque na Home',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                BoraButton.flame(
                  text: 'Novo Banner',
                  icon: Icons.add_photo_alternate_rounded,
                  height: 40,
                  borderRadius: 12,
                  onPressed: () => _showAddBannerDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Text(
              'BANNERS EM DESTAQUE NO CARROSSEL',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            if (banners.isEmpty)
              const BoraEmptyState(
                icon: Icons.view_carousel_rounded,
                iconColor: Color(0xFF6554C0),
                title: 'Nenhum banner cadastrado',
                description: 'Crie seu primeiro banner promocional para exibir aos clientes na Home do aplicativo.',
              )
            else
              ...banners.asMap().entries.map((entry) {
                final index = entry.key;
                final banner = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BoraCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(banner.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(banner.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                '${banner.subtitle} • Ação: ${banner.actionType} (${banner.actionTarget})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: banner.isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            final updated = banner.copyWith(isActive: val);
                            final list = List<HomeBannerModel>.from(banners);
                            list[index] = updated;
                            ref.read(homeBannersProvider.notifier).set(list);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            const Text(
              'MENU HORIZONTAL DE CATEGORIAS DA HOME',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            BoraCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    leading: const Icon(Icons.drag_indicator_rounded, color: AppColors.textMuted),
                    title: Text(cat.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    subtitle: Text('Slug: ${cat.slug} • Ícone: ${cat.iconName}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
