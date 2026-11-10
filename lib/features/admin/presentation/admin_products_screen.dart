import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../customer/providers/customer_providers.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _searchQuery = '';
  String? _selectedStoreId;
  ProductCategory? _selectedCategory;

  void _showProductDialog({ProductModel? productToEdit}) {
    final isEditing = productToEdit != null;
    final stores = ref.read(storesProvider);

    String storeId = productToEdit?.storeId ?? (stores.isNotEmpty ? stores.first.id : 'store-1');
    final nameController = TextEditingController(text: productToEdit?.name ?? '');
    final brandController = TextEditingController(text: productToEdit?.brandName ?? 'Ultragaz (Azul)');
    final descriptionController = TextEditingController(
      text: productToEdit?.description ?? 'Botijão com lacre holográfico aferido pelo INMETRO.',
    );
    final refillPriceController = TextEditingController(
      text: productToEdit != null ? productToEdit.refillPrice.toStringAsFixed(2) : '104.90',
    );
    final shellPriceController = TextEditingController(
      text: productToEdit != null ? productToEdit.shellPrice.toStringAsFixed(2) : '289.00',
    );

    ProductCategory category = productToEdit?.category ?? ProductCategory.p13;
    bool inStock = productToEdit?.inStock ?? true;

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
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6554C0), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Editar Produto (Super Admin)' : 'Cadastrar Produto no Marketplace',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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

                // Distribuidora Responsável
                const Text('Distribuidora / Loja', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: stores.any((s) => s.id == storeId) ? storeId : stores.firstOrNull?.id,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: stores
                      .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.address.split('-')[0]})')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => storeId = val);
                  },
                ),
                const SizedBox(height: 14),

                // Categoria
                const Text('Categoria', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<ProductCategory>(
                  initialValue: category,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: ProductCategory.p13, child: Text('Botijão P13 (13kg)')),
                    DropdownMenuItem(value: ProductCategory.water20l, child: Text('Água Mineral Galão 20L')),
                    DropdownMenuItem(value: ProductCategory.p45, child: Text('Cilindro Industrial P45')),
                    DropdownMenuItem(value: ProductCategory.p20, child: Text('Cilindro P20 (Empilhadeira)')),
                    DropdownMenuItem(value: ProductCategory.accessories, child: Text('Reguladores & Acessórios')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 14),

                // Nome e Marca
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nome do Produto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Ex: Botijão P13',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Marca', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: brandController,
                            decoration: InputDecoration(
                              hintText: 'Ex: Ultragaz',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Preços
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Preço Troca (R\$)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: refillPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'R\$ ',
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
                          const Text('Preço Completo (R\$)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: shellPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
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

                // Switch de Disponibilidade
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Disponível na Vitrine Pública', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: const Text('Se desativado, o produto fica oculto no aplicativo dos clientes'),
                  value: inStock,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setModalState(() => inStock = val),
                ),
                const SizedBox(height: 20),

                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6554C0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final targetStore = stores.firstWhere((s) => s.id == storeId, orElse: () => stores.first);
                      final refill = double.tryParse(refillPriceController.text.replaceAll(',', '.')) ?? 100.0;
                      final shell = double.tryParse(shellPriceController.text.replaceAll(',', '.')) ?? 280.0;

                      if (isEditing) {
                        final updated = productToEdit.copyWith(
                          name: name,
                          brandName: brandController.text.trim(),
                          category: category,
                          refillPrice: refill,
                          shellPrice: shell,
                          inStock: inStock,
                          storeId: storeId,
                          storeName: targetStore.name,
                        );

                        ref.read(productsProvider.notifier).update(
                              (list) => list.map((p) => p.id == updated.id ? updated : p).toList(),
                            );
                      } else {
                        final newProd = ProductModel(
                          id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                          storeId: storeId,
                          storeName: targetStore.name,
                          category: category,
                          name: name,
                          brandName: brandController.text.trim(),
                          description: descriptionController.text.trim(),
                          refillPrice: refill,
                          shellPrice: shell,
                          inStock: inStock,
                          imageUrl: category == ProductCategory.water20l
                              ? 'assets/images/app_icon_v2.png'
                              : 'assets/images/app_icon.png',
                          rating: 5.0,
                        );

                        ref.read(productsProvider.notifier).update((list) => [newProd, ...list]);
                      }

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Produto ${isEditing ? "atualizado" : "cadastrado"} com sucesso!')),
                      );
                    },
                    child: Text(
                      isEditing ? 'Salvar Alterações' : 'Cadastrar no Marketplace',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider);
    final stores = ref.watch(storesProvider);

    final filtered = allProducts.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brandName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.storeName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStore = _selectedStoreId == null || p.storeId == _selectedStoreId;
      final matchesCat = _selectedCategory == null || p.category == _selectedCategory;

      return matchesSearch && matchesStore && matchesCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo Global do Marketplace'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar Produto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6554C0),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: const Color(0xFF6554C0),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: const Text('Novo Produto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, marca ou distribuidora...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedStoreId,
                        decoration: InputDecoration(
                          labelText: 'Filtrar por Loja',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todas as Distribuidoras')),
                          ...stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedStoreId = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<ProductCategory?>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Filtrar Categoria',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todas as Categorias')),
                          DropdownMenuItem(value: ProductCategory.p13, child: Text('P13')),
                          DropdownMenuItem(value: ProductCategory.water20l, child: Text('Água 20L')),
                          DropdownMenuItem(value: ProductCategory.p45, child: Text('P45')),
                          DropdownMenuItem(value: ProductCategory.accessories, child: Text('Acessórios')),
                        ],
                        onChanged: (val) => setState(() => _selectedCategory = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Nenhum produto encontrado com os filtros aplicados.', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(p.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Loja: ${p.storeName} • Marca: ${p.brandName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Recarga: R\$ ${p.refillPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Completo: R\$ ${p.shellPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: p.inStock,
                                activeThumbColor: Colors.green,
                                onChanged: (val) {
                                  final updated = p.copyWith(inStock: val);
                                  ref.read(productsProvider.notifier).update(
                                        (list) => list.map((item) => item.id == p.id ? updated : item).toList(),
                                      );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                onPressed: () => _showProductDialog(productToEdit: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  ref.read(productsProvider.notifier).update(
                                        (list) => list.where((item) => item.id != p.id).toList(),
                                      );
                                },
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
}
