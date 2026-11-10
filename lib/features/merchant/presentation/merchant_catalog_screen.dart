import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/product_model.dart';
import '../../customer/providers/customer_providers.dart';
import '../providers/merchant_providers.dart';

class MerchantCatalogScreen extends ConsumerWidget {
  const MerchantCatalogScreen({super.key});

  void _showEditProductDialog(BuildContext context, WidgetRef ref, ProductModel product) {
    final refillController =
        TextEditingController(text: product.refillPrice.toStringAsFixed(2));
    final shellController =
        TextEditingController(text: product.shellPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: refillController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Preço da Troca (Somente Carga)',
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shellController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Preço Completo (Casco + Carga)',
                prefixText: 'R\$ ',
              ),
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
              final newRefill = double.tryParse(refillController.text.replaceAll(',', '.')) ?? product.refillPrice;
              final newShell = double.tryParse(shellController.text.replaceAll(',', '.')) ?? product.shellPrice;

              final updated = product.copyWith(
                refillPrice: newRefill,
                shellPrice: newShell,
              );

              ref.read(productsProvider.notifier).update(
                    (list) => list.map((p) => p.id == product.id ? updated : p).toList(),
                  );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preço atualizado no catálogo e Home!')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(merchantProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Produtos & Estoque'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final prod = products[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      prod.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          prod.brandName,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Troca: R\$ ${prod.refillPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Casco: R\$ ${prod.shellPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () => _showEditProductDialog(context, ref, prod),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
