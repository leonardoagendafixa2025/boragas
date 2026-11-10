import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/store_model.dart';
import '../../customer/providers/customer_providers.dart';

class AdminStoresScreen extends ConsumerWidget {
  const AdminStoresScreen({super.key});

  void _editCommissionDialog(BuildContext context, WidgetRef ref, StoreModel store) {
    final controller = TextEditingController(text: store.commissionRate.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Taxa de Comissão: ${store.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Defina a porcentagem de comissão que o Super Admin recebe sobre os pedidos entregues desta loja:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Comissão da Loja (%)',
                suffixText: '%',
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
              final newRate = double.tryParse(controller.text) ?? store.commissionRate;
              final updated = store.copyWith(commissionRate: newRate);

              ref.read(storesProvider.notifier).update(
                    (list) => list.map((s) => s.id == store.id ? updated : s).toList(),
                  );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Taxa da loja alterada para $newRate%')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _toggleStoreSuspension(BuildContext context, WidgetRef ref, StoreModel store) {
    final updated = store.copyWith(
      isSuspendedForNonPayment: !store.isSuspendedForNonPayment,
    );

    ref.read(storesProvider.notifier).update(
          (list) => list.map((s) => s.id == store.id ? updated : s).toList(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated.isSuspendedForNonPayment
            ? 'Loja ${store.name} suspensa! Não aparecerá mais na Home do cliente.'
            : 'Loja ${store.name} reativada com sucesso!'),
        backgroundColor: updated.isSuspendedForNonPayment ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Distribuidoras & Taxas'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: store.isSuspendedForNonPayment ? AppColors.error : AppColors.border,
                width: store.isSuspendedForNonPayment ? 1.5 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(store.logoUrl, width: 48, height: 48, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            Text(
                              'CNPJ: ${store.cnpj} • ${store.phone}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: store.isSuspendedForNonPayment
                              ? AppColors.error.withValues(alpha: 0.15)
                              : AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          store.isSuspendedForNonPayment ? 'SUSPENSA' : 'ATIVA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: store.isSuspendedForNonPayment
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Comissão Atual', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '${store.commissionRate}% sobre vendas',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _editCommissionDialog(context, ref, store),
                            icon: const Icon(Icons.percent_rounded, size: 14),
                            label: const Text('Ajustar Taxa'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              store.isSuspendedForNonPayment ? Icons.lock_open_rounded : Icons.block_rounded,
                              color: store.isSuspendedForNonPayment ? AppColors.success : AppColors.error,
                            ),
                            tooltip: store.isSuspendedForNonPayment
                                ? 'Reativar Loja'
                                : 'Suspender Loja por Inadimplência',
                            onPressed: () => _toggleStoreSuspension(context, ref, store),
                          ),
                        ],
                      ),
                    ],
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
