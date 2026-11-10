import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../customer/providers/customer_providers.dart';
import '../providers/merchant_providers.dart';

class MerchantCatalogScreen extends ConsumerStatefulWidget {
  const MerchantCatalogScreen({super.key});

  @override
  ConsumerState<MerchantCatalogScreen> createState() => _MerchantCatalogScreenState();
}

class _MerchantCatalogScreenState extends ConsumerState<MerchantCatalogScreen> {
  String _searchQuery = '';
  ProductCategory? _selectedCategoryFilter;

  // Diálogo para Adicionar ou Editar Produto
  void _showProductFormDialog({ProductModel? productToEdit}) {
    final isEditing = productToEdit != null;
    final currentStore = ref.read(currentMerchantStoreProvider);

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

    ProductCategory selectedCategory = productToEdit?.category ?? ProductCategory.p13;
    bool inStock = productToEdit?.inStock ?? true;
    String selectedImage = productToEdit?.imageUrl ?? 'assets/images/app_icon.png';

    final brandsList = [
      'Ultragaz (Azul)',
      'Liquigás (Verde)',
      'Copagaz',
      'Supergasbras',
      'Nacional Gás',
      'Consigaz',
      'Bonafont',
      'Lindoya Verão',
      'Aliança Reguladores',
      'Outra Marca',
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Editar Produto' : 'Cadastrar Novo Produto',
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

                // Categoria
                const Text('Categoria do Produto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProductCategory>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ProductCategory.p13,
                      child: Text('Botijão de Gás P13 (Cozinha 13kg)'),
                    ),
                    DropdownMenuItem(
                      value: ProductCategory.water20l,
                      child: Text('Água Mineral Galão 20L'),
                    ),
                    DropdownMenuItem(
                      value: ProductCategory.p45,
                      child: Text('Cilindro Industrial P45 (45kg)'),
                    ),
                    DropdownMenuItem(
                      value: ProductCategory.p20,
                      child: Text('Cilindro P20 (Empilhadeira)'),
                    ),
                    DropdownMenuItem(
                      value: ProductCategory.accessories,
                      child: Text('Reguladores, Mangueiras & Acessórios'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedCategory = val;
                        if (val == ProductCategory.water20l) {
                          selectedImage = 'assets/images/app_icon_v2.png';
                          if (!isEditing) {
                            nameController.text = 'Água Mineral Galão 20L';
                            brandController.text = 'Bonafont';
                            refillPriceController.text = '14.90';
                            shellPriceController.text = '42.00';
                          }
                        } else if (val == ProductCategory.p13) {
                          selectedImage = 'assets/images/app_icon.png';
                          if (!isEditing) {
                            nameController.text = 'Botijão de Gás P13 (13kg)';
                            brandController.text = 'Ultragaz (Azul)';
                            refillPriceController.text = '104.90';
                            shellPriceController.text = '289.00';
                          }
                        } else if (val == ProductCategory.p45) {
                          selectedImage = 'assets/images/app_icon.png';
                          if (!isEditing) {
                            nameController.text = 'Cilindro Industrial P45';
                            refillPriceController.text = '430.00';
                            shellPriceController.text = '890.00';
                          }
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Nome do Produto
                const Text('Nome Exibido no Catálogo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Botijão P13 Ultragaz com Lacre',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Marca
                const Text('Marca / Bandeira', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: brandsList.contains(brandController.text) ? brandController.text : brandsList.first,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: brandsList
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        brandController.text = val;
                        if (val.contains('Liquigás') || val.contains('Verde') || val.contains('Bonafont')) {
                          selectedImage = 'assets/images/app_icon_v2.png';
                        } else {
                          selectedImage = 'assets/images/app_icon.png';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Preços (Troca e Completo)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Preço da Troca (Recarga)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: refillPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'R\$ ',
                              hintText: '104.90',
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
                          const Text('Preço Completo (+ Casco)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: shellPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'R\$ ',
                              hintText: '289.00',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Descrição
                const Text('Descrição / Detalhes de Segurança', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Peso líquido aferido, lacre inviolável e garantia ANP.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Switch de Estoque
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: inStock ? Colors.green.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: inStock ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: inStock ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inStock ? 'Produto Disponível para Venda' : 'Produto Pausado (Esgotado)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: inStock ? Colors.green.shade800 : Colors.red.shade800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                inStock ? 'Aparecerá para clientes em seu raio' : 'Oculto na busca dos clientes',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: inStock,
                        activeThumbColor: Colors.green,
                        onChanged: (val) => setModalState(() => inStock = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, informe o nome do produto.')),
                        );
                        return;
                      }

                      final refill = double.tryParse(refillPriceController.text.replaceAll(',', '.')) ?? 100.0;
                      final shell = double.tryParse(shellPriceController.text.replaceAll(',', '.')) ?? 280.0;

                      if (isEditing) {
                        final updated = productToEdit.copyWith(
                          name: name,
                          category: selectedCategory,
                          brandName: brandController.text.trim(),
                          description: descriptionController.text.trim(),
                          refillPrice: refill,
                          shellPrice: shell,
                          inStock: inStock,
                          imageUrl: selectedImage,
                        );

                        ref.read(productsProvider.notifier).update(
                              (list) => list.map((p) => p.id == updated.id ? updated : p).toList(),
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Produto "${updated.name}" atualizado com sucesso!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        final newProduct = ProductModel(
                          id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                          storeId: currentStore.id,
                          storeName: currentStore.name,
                          category: selectedCategory,
                          name: name,
                          brandName: brandController.text.trim(),
                          description: descriptionController.text.trim(),
                          refillPrice: refill,
                          shellPrice: shell,
                          inStock: inStock,
                          imageUrl: selectedImage,
                          rating: 5.0,
                        );

                        ref.read(productsProvider.notifier).update(
                              (list) => [newProduct, ...list],
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Produto "${newProduct.name}" cadastrado no catálogo!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }

                      Navigator.pop(ctx);
                    },
                    child: Text(
                      isEditing ? 'Salvar Alterações' : 'Cadastrar no Estoque',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
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

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Produto?'),
        content: Text('Deseja remover "${product.name}" do seu catálogo de vendas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(productsProvider.notifier).update(
                    (list) => list.where((p) => p.id != product.id).toList(),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produto removido do catálogo.')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allProducts = ref.watch(merchantProductsProvider);

    // Filtros de busca e categoria
    final filteredProducts = allProducts.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brandName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategoryFilter == null || p.category == _selectedCategoryFilter;

      return matchesSearch && matchesCategory;
    }).toList();

    final activeCount = allProducts.where((p) => p.inStock).length;
    final outOfStockCount = allProducts.length - activeCount;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductFormDialog(),
        backgroundColor: const Color(0xFFFF6B00),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: const Text('Adicionar Produto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          // Header Tático de Catálogo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catálogo & Estoque • ${currentStore.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Gerencie botijões, preços e disponibilidade no depósito',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _showProductFormDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Novo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 1. Resumo Métrico do Catálogo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Total de Itens',
                      value: '${allProducts.length}',
                      icon: Icons.inventory_rounded,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Em Venda',
                      value: '$activeCount',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Pausados',
                      value: '$outOfStockCount',
                      icon: Icons.pause_circle_outline_rounded,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Barra de Busca
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, marca ou capacidade...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // 3. Chips de Categoria
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildCategoryChip(label: 'Todos', category: null),
                  const SizedBox(width: 8),
                  _buildCategoryChip(label: 'P13 Residencial', category: ProductCategory.p13),
                  const SizedBox(width: 8),
                  _buildCategoryChip(label: 'Água 20L', category: ProductCategory.water20l),
                  const SizedBox(width: 8),
                  _buildCategoryChip(label: 'P45 Industrial', category: ProductCategory.p45),
                  const SizedBox(width: 8),
                  _buildCategoryChip(label: 'P20 Empilhadeira', category: ProductCategory.p20),
                  const SizedBox(width: 8),
                  _buildCategoryChip(label: 'Acessórios & Válvulas', category: ProductCategory.accessories),
                ],
              ),
            ),
          ),

          // 4. Lista de Produtos
          if (filteredProducts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 14),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Nenhum produto encontrado para "$_searchQuery"'
                          : 'Nenhum produto cadastrado nesta categoria.',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showProductFormDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar Primeiro Produto'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prod = filteredProducts[index];
                    return _buildProductCard(prod);
                  },
                  childCount: filteredProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({required String label, required ProductCategory? category}) {
    final isSelected = _selectedCategoryFilter == category;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => setState(() => _selectedCategoryFilter = category),
    );
  }

  Widget _buildProductCard(ProductModel prod) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: prod.inStock ? AppColors.border : Colors.red.withValues(alpha: 0.3),
          width: prod.inStock ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        prod.imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (!prod.inStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'ESGOTADO',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Informações Principais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              prod.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: prod.inStock ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prod.inStock ? 'DISPONÍVEL' : 'PAUSADO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: prod.inStock ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prod.brandName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // Preços
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Troca: R\$ ${prod.refillPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Completo: R\$ ${prod.shellPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Ações Rápidas no Rodapé do Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Estoque Imediato:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Switch(
                      value: prod.inStock,
                      activeThumbColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        final updated = prod.copyWith(inStock: val);
                        ref.read(productsProvider.notifier).update(
                              (list) => list.map((p) => p.id == prod.id ? updated : p).toList(),
                            );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                      tooltip: 'Editar Produto',
                      onPressed: () => _showProductFormDialog(productToEdit: prod),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      tooltip: 'Excluir Produto',
                      onPressed: () => _confirmDeleteProduct(prod),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
