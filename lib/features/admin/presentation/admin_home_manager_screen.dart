import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/banner_model.dart';
import '../../customer/providers/customer_providers.dart';

class AdminHomeManagerScreen extends ConsumerWidget {
  const AdminHomeManagerScreen({super.key});

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final promoCodeController = TextEditingController(text: 'BORAGAS15');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Novo Banner Promocional'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título do Banner (Ex: Super Promoção)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: subtitleController,
              decoration: const InputDecoration(labelText: 'Subtítulo / Descrição'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: promoCodeController,
              decoration: const InputDecoration(labelText: 'Código do Cupom de Desconto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;

              final newBanner = HomeBannerModel(
                id: 'banner-${DateTime.now().millisecondsSinceEpoch}',
                title: titleController.text.trim(),
                subtitle: subtitleController.text.trim(),
                badgeText: 'NOVO CUPOM',
                imageUrl: 'assets/images/app_icon.png',
                actionType: 'promo_code',
                actionTarget: promoCodeController.text.trim(),
                isActive: true,
                sortOrder: 1,
              );

              ref.read(homeBannersProvider.notifier).update((list) => [newBanner, ...list]);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Banner publicado na Home do cliente!')),
              );
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeBannersProvider);
    final categories = ref.watch(homeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor da Home (Banners & Menus)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Novo Banner'),
        onPressed: () => _showAddBannerDialog(context, ref),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BANNERS EM DESTAQUE NO CARROSSEL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            ...banners.asMap().entries.map((entry) {
              final index = entry.key;
              final banner = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(banner.imageUrl, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  title: Text(banner.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${banner.subtitle} • Ação: ${banner.actionType} (${banner.actionTarget})',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Switch(
                    value: banner.isActive,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      final updated = banner.copyWith(isActive: val);
                      final list = List<HomeBannerModel>.from(banners);
                      list[index] = updated;
                      ref.read(homeBannersProvider.notifier).set(list);
                    },
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            const Text(
              'MENU HORIZONTAL DE CATEGORIAS DA HOME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    leading: const Icon(Icons.drag_indicator_rounded, color: AppColors.textMuted),
                    title: Text(cat.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('Slug: ${cat.slug} • Ícone: ${cat.iconName}', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  );
                },
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
