import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/store_model.dart';
import '../../../core/services/supabase_service.dart';
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
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Reset de Dados Demo', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deseja zerar todos os dados demo locais para deixar o sistema 100% limpo para operação comercial?\n\n'
              'Para limpar também as linhas de teste do seu banco Supabase na nuvem, execute o comando abaixo no SQL Editor do Supabase:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
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
            child: const Text('Fechar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.white),
            label: const Text('Zerar em Memória Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              ref.read(storesProvider.notifier).set([]);
              ref.read(productsProvider.notifier).set([]);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lojas e produtos demo zerados com sucesso!'),
                  backgroundColor: Color(0xFF10B981),
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
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6554C0).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.store_mall_directory_rounded,
                              color: Color(0xFF6554C0), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Editar Distribuidora' : 'Cadastrar Nova Distribuidora',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Nome da Loja
                const Text('Nome Fantasia da Distribuidora',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Ultragaz Paulista Express',
                    prefixIcon: const Icon(Icons.business_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // CNPJ e WhatsApp
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CNPJ',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: cnpjController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '00.000.000/0001-00',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WhatsApp Oficial',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '(11) 98765-4321',
                              prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Endereço Completo
                const Text('Endereço Completo (com Bairro e Cidade)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Av. Paulista, 1200 - Bela Vista, São Paulo - SP',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Taxa de Comissão BoraGás (%) e Taxa de Entrega (R$)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Comissão BoraGás (%)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: commissionController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '8.0',
                              suffixText: '%',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Taxa de Entrega Base',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: deliveryFeeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tempo Estimado e Raio de Entrega
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tempo Médio (minutos)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: timeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '25',
                              suffixText: 'min',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Raio / Distância (km)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: distanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '3.5',
                              suffixText: 'km',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Seletor de Ícone / Logo
                const Text('Logo / Identidade Visual',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: logoOptions.map((opt) {
                    final isSel = selectedLogo == opt['path'];
                    return InkWell(
                      onTap: () => setModalState(() => selectedLogo = opt['path']!),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSel ? const Color(0xFF6554C0) : AppColors.border,
                            width: isSel ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSel ? const Color(0xFF6554C0).withValues(alpha: 0.08) : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(opt['path']!, width: 28, height: 28, fit: BoxFit.contain),
                            const SizedBox(width: 8),
                            Text(opt['name']!,
                                style: TextStyle(
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12,
                                  color: isSel ? const Color(0xFF6554C0) : AppColors.textPrimary,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Switches: Aberta no Momento e Suspensão
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Loja Aberta para Pedidos',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: const Text('Se desmarcado, aparecerá como fechada no app',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: isOpen,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) => setModalState(() => isOpen = val),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      SwitchListTile(
                        title: const Text('Suspensa por Inadimplência',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: const Text('Bloqueia a exibição da loja no marketplace do cliente',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: isSuspended,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.error,
                        onChanged: (val) => setModalState(() => isSuspended = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6554C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
                            'is_verified': true,
                            'lat': -23.561414,
                            'lng': -46.655881,
                            'delivery_radius_km': 10,
                            'rating': 5.0,
                          }).catchError((_) {});
                        }

                        ref.read(storesProvider.notifier).update(
                              (list) => [...list, newStore],
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Distribuidora "${newStore.name}" cadastrada no Supabase!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }

                      Navigator.pop(ctx);
                    },
                    child: Text(
                      isEditing ? 'Salvar Alterações' : 'Cadastrar Distribuidora',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteStore(StoreModel store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('Excluir Distribuidora?')),
          ],
        ),
        content: Text(
          'Deseja realmente remover a distribuidora "${store.name}" da rede BoraGás?\n\n'
          'Essa ação cancelará sua presença na plataforma.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
                SupabaseService.client.from('stores').delete().eq('id', store.id).catchError((_) {});
              }
              ref.read(storesProvider.notifier).update(
                    (list) => list.where((s) => s.id != store.id).toList(),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Distribuidora "${store.name}" removida da rede.'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: const Text('Excluir Loja'),
          ),
        ],
      ),
    );
  }

  void _toggleStoreSuspension(StoreModel store) {
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
      appBar: AppBar(
        title: const Text('Gestão de Distribuidoras & Taxas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.amber),
            tooltip: 'Zerar Dados Demo (Reset Produção)',
            onPressed: () => _showPurgeDemoDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Cadastrar Loja',
            onPressed: () => _showStoreFormDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6554C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Nova Distribuidora', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showStoreFormDialog(),
      ),
      body: Column(
        children: [
          // Header Metrics Cards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total de Lojas',
                    value: '$totalStores',
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF6554C0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Ativas',
                    value: '$activeStores',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Suspensas',
                    value: '$suspendedStores',
                    icon: Icons.block_rounded,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Comissão Média',
                    value: '${avgCommission.toStringAsFixed(1)}%',
                    icon: Icons.percent_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar distribuidora por nome, CNPJ ou bairro...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma distribuidora encontrada',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tente outro termo ou cadastre uma nova distribuidora.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final store = filtered[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: store.isSuspendedForNonPayment
                                ? AppColors.error
                                : AppColors.border,
                            width: store.isSuspendedForNonPayment ? 1.5 : 1.0,
                          ),
                        ),
                        elevation: 1,
                        child: Padding(
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
                                      width: 52,
                                      height: 52,
                                      color: AppColors.background,
                                      child: Image.asset(store.logoUrl, fit: BoxFit.contain),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          'CNPJ: ${store.cnpj}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          store.address,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 12),

                              // Detalhes Operacionais
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStoreDetail(
                                    label: 'WhatsApp',
                                    value: store.phone,
                                    icon: Icons.phone_rounded,
                                  ),
                                  _buildStoreDetail(
                                    label: 'Comissão Plataforma',
                                    value: '${store.commissionRate}%',
                                    icon: Icons.percent_rounded,
                                    isHighlight: true,
                                  ),
                                  _buildStoreDetail(
                                    label: 'Taxa Entrega',
                                    value: store.deliveryFee == 0
                                        ? 'Grátis'
                                        : 'R\$ ${store.deliveryFee.toStringAsFixed(2)}',
                                    icon: Icons.delivery_dining_rounded,
                                  ),
                                  _buildStoreDetail(
                                    label: 'Tempo Médio',
                                    value: '${store.estimatedTimeMin} min',
                                    icon: Icons.timer_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Ações: Editar, Suspender/Reativar, Excluir
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.edit_rounded, size: 15),
                                    label: const Text('Editar Dados'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _showStoreFormDialog(storeToEdit: store),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      store.isSuspendedForNonPayment
                                          ? Icons.lock_open_rounded
                                          : Icons.block_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      store.isSuspendedForNonPayment ? 'Reativar' : 'Suspender',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: store.isSuspendedForNonPayment
                                          ? AppColors.success
                                          : AppColors.error,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _toggleStoreSuspension(store),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                    tooltip: 'Remover Distribuidora',
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

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreDetail({
    required String label,
    required String value,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isHighlight ? const Color(0xFF6554C0) : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? const Color(0xFF6554C0) : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: const Color(0xFF6554C0).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? const Color(0xFF6554C0) : AppColors.textSecondary,
      ),
    );
  }
}
