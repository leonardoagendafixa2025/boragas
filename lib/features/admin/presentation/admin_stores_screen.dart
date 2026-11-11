import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/store_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';
import '../../../core/widgets/ui/bora_empty_state.dart';
import '../../../core/widgets/ui/bora_kpi_card.dart';
import '../../customer/providers/customer_providers.dart';

class AdminStoresScreen extends ConsumerStatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  ConsumerState<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends ConsumerState<AdminStoresScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'suspended'

  void _showPurgeDemoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Reset de Dados Demo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deseja zerar todos os dados demo locais para deixar o sistema 100% limpo para operação comercial?\n\n'
              'Para limpar também as linhas de teste do seu banco Supabase na nuvem, execute o comando abaixo no SQL Editor do Supabase:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: const SelectableText(
                'TRUNCATE public.orders, public.products, public.stores, public.store_payment_configs, public.commission_invoices, public.support_tickets CASCADE;',
                style: TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.white),
            label: const Text('Zerar em Memória Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              ref.read(storesProvider.notifier).set([]);
              ref.read(productsProvider.notifier).set([]);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lojas e produtos demo zerados com sucesso!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showStoreFormDialog({StoreModel? storeToEdit}) {
    final isEditing = storeToEdit != null;

    final nameController = TextEditingController(text: storeToEdit?.name ?? '');
    final cnpjController = TextEditingController(text: storeToEdit?.cnpj ?? '');
    final phoneController = TextEditingController(text: storeToEdit?.phone ?? '');
    final addressController = TextEditingController(text: storeToEdit?.address ?? '');
    final distanceController = TextEditingController(
      text: storeToEdit != null ? storeToEdit.distanceKm.toStringAsFixed(1) : '3.5',
    );
    final deliveryFeeController = TextEditingController(
      text: storeToEdit != null ? storeToEdit.deliveryFee.toStringAsFixed(2) : '0.00',
    );
    final timeController = TextEditingController(
      text: storeToEdit != null ? storeToEdit.estimatedTimeMin.toString() : '25',
    );
    final commissionController = TextEditingController(
      text: storeToEdit != null ? storeToEdit.commissionRate.toStringAsFixed(1) : '8.0',
    );

    bool isOpen = storeToEdit?.isOpen ?? true;
    bool isSuspended = storeToEdit?.isSuspendedForNonPayment ?? false;
    String selectedLogo = storeToEdit?.logoUrl ?? 'assets/images/app_icon.png';

    final logoOptions = [
      {'name': 'BoraGás Padrão', 'path': 'assets/images/app_icon.png'},
      {'name': 'Brand Lockup', 'path': 'assets/images/brand_lockup.png'},
    ];

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
                // Handle bar
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

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6554C0).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFF6554C0), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Editar Distribuidora' : 'Cadastrar Distribuidora',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nome da Loja
                const Text('Nome Fantasia da Distribuidora', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Ultragaz Paulistana Express',
                    prefixIcon: const Icon(Icons.business_rounded, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 12),

                // CNPJ e WhatsApp
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CNPJ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: cnpjController,
                            decoration: InputDecoration(
                              hintText: '00.000.000/0001-00',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WhatsApp Oficial', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '(11) 98765-4321',
                              prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Endereço Completo
                const Text('Endereço Completo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Av. Paulista, 1200 - Bela Vista, São Paulo - SP',
                    prefixIcon: const Icon(Icons.location_on_rounded, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 12),

                // Taxa de Comissão BoraGás (%) e Taxa de Entrega
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Comissão BoraGás (%)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: commissionController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '8.0',
                              suffixText: '%',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Taxa de Entrega', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: deliveryFeeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixText: 'R\$ ',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tempo Estimado e Raio de Entrega
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tempo Médio', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: timeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '25',
                              suffixText: 'min',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Raio / Distância (km)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: distanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '3.5',
                              suffixText: 'km',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Logo da Distribuidora
                const Text('Logo / Ícone', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                Row(
                  children: logoOptions.map((opt) {
                    final isSel = selectedLogo == opt['path'];
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedLogo = opt['path']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF6554C0).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? const Color(0xFF6554C0) : AppColors.border,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(opt['path']!, width: 24, height: 24, fit: BoxFit.contain),
                            const SizedBox(width: 6),
                            Text(
                              opt['name']!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel ? const Color(0xFF6554C0) : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Switches
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Loja Aberta para Vendas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: const Text('Se desmarcado, aparecerá como fechada no app', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        value: isOpen,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) => setModalState(() => isOpen = val),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      SwitchListTile(
                        title: const Text('Suspensa por Inadimplência', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: const Text('Bloqueia a exibição da loja no marketplace do cliente', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        value: isSuspended,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.error,
                        onChanged: (val) => setModalState(() => isSuspended = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  child: BoraButton.flame(
                    text: isEditing ? 'Salvar Alterações' : 'Cadastrar Distribuidora',
                    icon: Icons.check_circle_rounded,
                    height: 50,
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, informe o nome da distribuidora')),
                        );
                        return;
                      }

                      final cnpj = cnpjController.text.trim().isNotEmpty
                          ? cnpjController.text.trim()
                          : '00.000.000/0001-00';
                      final phone = phoneController.text.trim().isNotEmpty
                          ? phoneController.text.trim()
                          : '(11) 98765-4321';
                      final address = addressController.text.trim().isNotEmpty
                          ? addressController.text.trim()
                          : 'São Paulo - SP';
                      final distance = double.tryParse(distanceController.text.replaceAll(',', '.')) ?? 3.5;
                      final deliveryFee = double.tryParse(deliveryFeeController.text.replaceAll(',', '.')) ?? 0.0;
                      final estTime = int.tryParse(timeController.text) ?? 25;
                      final commissionRate = double.tryParse(commissionController.text.replaceAll(',', '.')) ?? 8.0;

                      if (isEditing) {
                        final updated = storeToEdit.copyWith(
                          name: name,
                          cnpj: cnpj,
                          phone: phone,
                          address: address,
                          distanceKm: distance,
                          deliveryFee: deliveryFee,
                          estimatedTimeMin: estTime,
                          commissionRate: commissionRate,
                          isOpen: isOpen,
                          isSuspendedForNonPayment: isSuspended,
                          logoUrl: selectedLogo,
                        );

                        if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
                          SupabaseService.client.from('stores').update({
                            'name': name,
                            'cnpj': cnpj,
                            'phone': phone,
                            'address': address,
                            'is_open': isOpen,
                            'status': isSuspended ? 'suspended' : 'active',
                            'base_delivery_fee': deliveryFee,
                            'estimated_time_min': estTime,
                            'commission_rate': commissionRate,
                          }).eq('id', storeToEdit.id).catchError((_) {});
                        }

                        ref.read(storesProvider.notifier).update(
                              (list) => list.map((s) => s.id == storeToEdit.id ? updated : s).toList(),
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Distribuidora "${updated.name}" atualizada com sucesso!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        final newStoreId = 'store-${DateTime.now().millisecondsSinceEpoch}';
                        final newStore = StoreModel(
                          id: newStoreId,
                          name: name,
                          cnpj: cnpj,
                          phone: phone,
                          logoUrl: selectedLogo,
                          coverUrl: 'assets/images/brand_lockup.png',
                          address: address,
                          distanceKm: distance,
                          rating: 5.0,
                          reviewsCount: 1,
                          estimatedTimeMin: estTime,
                          deliveryFee: deliveryFee,
                          isVerified: true,
                          isOpen: isOpen,
                          commissionRate: commissionRate,
                          isSuspendedForNonPayment: isSuspended,
                        );

                        if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
                          SupabaseService.client.from('stores').insert({
                            'name': name,
                            'cnpj': cnpj,
                            'phone': phone,
                            'address': address,
                            'is_open': isOpen,
                            'status': isSuspended ? 'suspended' : 'active',
                            'base_delivery_fee': deliveryFee,
                            'estimated_time_min': estTime,
                            'commission_rate': commissionRate,
                          }).catchError((_) {});
                        }

                        ref.read(storesProvider.notifier).update((list) => [newStore, ...list]);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Distribuidora "${newStore.name}" cadastrada com sucesso!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }

                      Navigator.pop(ctx);
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

  void _confirmDeleteStore(StoreModel store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Distribuidora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Deseja excluir "${store.name}" da plataforma? Todos os vínculos serão desativados.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Definitivamente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
        SupabaseService.client.from('stores').delete().eq('id', store.id).catchError((_) {});
      }
      ref.read(storesProvider.notifier).update((list) => list.where((s) => s.id != store.id).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Distribuidora "${store.name}" removida.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _toggleStoreSuspension(StoreModel store) {
    HapticFeedback.lightImpact();
    final updated = store.copyWith(
      isSuspendedForNonPayment: !store.isSuspendedForNonPayment,
    );

    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      SupabaseService.client.from('stores').update({
        'status': updated.isSuspendedForNonPayment ? 'suspended' : 'active',
      }).eq('id', store.id).catchError((_) {});
    }

    ref.read(storesProvider.notifier).update(
          (list) => list.map((s) => s.id == store.id ? updated : s).toList(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated.isSuspendedForNonPayment
            ? 'Loja ${store.name} suspensa! Bloqueada no marketplace do cliente.'
            : 'Loja ${store.name} reativada com sucesso!'),
        backgroundColor: updated.isSuspendedForNonPayment ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider);

    // Filter
    final filtered = stores.where((s) {
      if (_statusFilter == 'active' && s.isSuspendedForNonPayment) return false;
      if (_statusFilter == 'suspended' && !s.isSuspendedForNonPayment) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = s.name.toLowerCase().contains(q);
        final matchCnpj = s.cnpj.toLowerCase().contains(q);
        final matchAddr = s.address.toLowerCase().contains(q);
        return matchName || matchCnpj || matchAddr;
      }
      return true;
    }).toList();

    final totalStores = stores.length;
    final activeStores = stores.where((s) => !s.isSuspendedForNonPayment).length;
    final suspendedStores = stores.where((s) => s.isSuspendedForNonPayment).length;
    final avgCommission = stores.isEmpty
        ? 0.0
        : stores.fold<double>(0.0, (acc, s) => acc + s.commissionRate) / stores.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header com Título e Botão "Nova Distribuidora" (Fixo no topo, NUNCA sobrepondo cards!)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestão de Distribuidoras',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.3),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Controle de parceiros, comissões e repasses',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.cleaning_services_rounded, color: Colors.amber, size: 20),
                          tooltip: 'Zerar Dados Demo',
                          onPressed: () => _showPurgeDemoDialog(),
                        ),
                        const SizedBox(width: 4),
                        BoraButton.flame(
                          text: 'Nova Loja',
                          icon: Icons.add_business_rounded,
                          height: 40,
                          borderRadius: 12,
                          onPressed: () => _showStoreFormDialog(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // KPIs em Carrossel Horizontal (Zero Truncamento garantido em qualquer aparelho móvel)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  BoraKpiCard(
                    label: 'Total de Lojas',
                    value: '$totalStores',
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFF6554C0),
                    subtitle: 'Lojas registradas',
                  ),
                  const SizedBox(width: 10),
                  BoraKpiCard(
                    label: 'Lojas Ativas',
                    value: '$activeStores',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                    subtitle: 'Recebendo pedidos',
                  ),
                  const SizedBox(width: 10),
                  BoraKpiCard(
                    label: 'Suspensas',
                    value: '$suspendedStores',
                    icon: Icons.block_rounded,
                    iconColor: AppColors.error,
                    subtitle: 'Bloqueadas por débito',
                  ),
                  const SizedBox(width: 10),
                  BoraKpiCard(
                    label: 'Comissão Média',
                    value: '${avgCommission.toStringAsFixed(1)}%',
                    icon: Icons.percent_rounded,
                    iconColor: AppColors.primary,
                    subtitle: 'Taxa sobre vendas',
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar distribuidora por nome, CNPJ ou bairro...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todas as Distribuidoras', 'all', totalStores),
                      const SizedBox(width: 8),
                      _buildFilterChip('Apenas Ativas', 'active', activeStores),
                      const SizedBox(width: 8),
                      _buildFilterChip('Apenas Suspensas', 'suspended', suspendedStores),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stores List
          Expanded(
            child: filtered.isEmpty
                ? const BoraEmptyState(
                    icon: Icons.storefront_rounded,
                    iconColor: Color(0xFF6554C0),
                    title: 'Nenhuma distribuidora encontrada',
                    description: 'Tente outro termo na busca ou cadastre uma nova distribuidora parceira.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final store = filtered[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BoraCard(
                          borderColor: store.isSuspendedForNonPayment
                              ? AppColors.error.withValues(alpha: 0.4)
                              : AppColors.border,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColors.surfaceVariant,
                                      child: Image.asset(store.logoUrl, fit: BoxFit.contain),
                                    ),
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
                                                store.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: store.isSuspendedForNonPayment
                                                    ? AppColors.error.withValues(alpha: 0.12)
                                                    : AppColors.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                store.isSuspendedForNonPayment ? 'SUSPENSA' : 'ATIVA',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  color: store.isSuspendedForNonPayment ? AppColors.error : AppColors.success,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'CNPJ: ${store.cnpj}',
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          store.address,
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 10),

                              // Grid de Metadados Operacionais
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStoreDetail(
                                            label: 'WhatsApp',
                                            value: store.phone.isNotEmpty ? store.phone : 'Não informado',
                                            icon: Icons.phone_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildStoreDetail(
                                            label: 'Comissão',
                                            value: '${store.commissionRate}% por venda',
                                            icon: Icons.percent_rounded,
                                            isHighlight: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStoreDetail(
                                            label: 'Taxa Entrega',
                                            value: store.deliveryFee == 0
                                                ? 'Grátis'
                                                : 'R\$ ${store.deliveryFee.toStringAsFixed(2)}',
                                            icon: Icons.two_wheeler_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildStoreDetail(
                                            label: 'Tempo Médio',
                                            value: '~${store.estimatedTimeMin} min',
                                            icon: Icons.timer_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Ações: Editar, Suspender/Reativar, Excluir (Dispostas com folga, sem sobreposição)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.edit_rounded, size: 14),
                                    label: const Text('Editar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textPrimary,
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(0, 34),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _showStoreFormDialog(storeToEdit: store),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      store.isSuspendedForNonPayment ? Icons.lock_open_rounded : Icons.block_rounded,
                                      size: 14,
                                    ),
                                    label: Text(
                                      store.isSuspendedForNonPayment ? 'Reativar' : 'Suspender',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: store.isSuspendedForNonPayment ? AppColors.success : AppColors.error,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(0, 34),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _toggleStoreSuspension(store),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                    tooltip: 'Remover Distribuidora',
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                      minimumSize: const Size(34, 34),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _confirmDeleteStore(store),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _statusFilter = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6554C0) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6554C0) : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStoreDetail({
    required String label,
    required String value,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isHighlight ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isHighlight ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
