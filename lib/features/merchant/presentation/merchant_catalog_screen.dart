import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/product_image_preview.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';
import '../../../core/widgets/ui/bora_empty_state.dart';
import '../../../core/widgets/ui/bora_kpi_card.dart';
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

  bool _isGasItem(ProductModel prod) {
    if (prod.category == ProductCategory.p13 ||
        prod.category == ProductCategory.p45 ||
        prod.category == ProductCategory.p20) {
      return true;
    }
    final lower = prod.name.toLowerCase();
    return lower.contains('gás') || lower.contains('gas') || lower.contains('p13') || lower.contains('p45') || lower.contains('glp');
  }

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
    bool showPhotoPicker = true;
    final customUrlController = TextEditingController(text: selectedImage.startsWith('http') ? selectedImage : '');

    final photoPresets = [
      {'title': 'Ultragaz (Azul)', 'category': 'Botijão P13', 'url': 'assets/images/app_icon.png'},
      {'title': 'Liquigás (Verde)', 'category': 'Botijão P13', 'url': 'assets/images/app_icon_v2.png'},
      {'title': 'Supergasbras', 'category': 'Botijão P13', 'url': 'assets/images/brand_lockup.png'},
      {'title': 'Água Mineral 20L', 'category': 'Galão 20L', 'url': 'assets/images/app_icon_v2.png'},
      {'title': 'Cilindro P45', 'category': 'Cilindro 45kg', 'url': 'assets/images/app_icon.png'},
      {'title': 'Regulador & Válvula', 'category': 'Acessórios', 'url': 'assets/images/brand_lockup.png'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
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
                // Handle Bar
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
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
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: AppColors.primaryLight, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Editar Produto' : 'Cadastrar Novo Produto',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Seção de Foto do Produto
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                                ),
                                child: ProductImagePreview(
                                  imageUrl: selectedImage,
                                  width: 68,
                                  height: 68,
                                  borderRadius: 12,
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentFlame,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.photo_camera_rounded, size: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Foto de Catálogo',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedImage.startsWith('http') ? 'Foto personalizada via Web' : 'Foto oficial ativa',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () {
                                    setModalState(() => showPhotoPicker = !showPhotoPicker);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentFlame.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.accentFlame.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(showPhotoPicker ? Icons.expand_less_rounded : Icons.photo_library_rounded,
                                            size: 13, color: AppColors.accentFlame),
                                        const SizedBox(width: 4),
                                        Text(
                                          showPhotoPicker ? 'Recolher Opções' : 'Trocar Foto Oficial',
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.accentFlame),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (showPhotoPicker) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0x1AFFFFFF)),
                        const SizedBox(height: 10),
                        const Text(
                          'Escolha um preset oficial ou insira uma URL:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: photoPresets.map((preset) {
                              final isSelected = selectedImage == preset['url'];
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedImage = preset['url']!;
                                    customUrlController.clear();
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.accentFlame.withValues(alpha: 0.15) : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.accentFlame : const Color(0xFF334155),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      ProductImagePreview(
                                        imageUrl: preset['url']!,
                                        width: 44,
                                        height: 44,
                                        borderRadius: 8,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        preset['title']!,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? AppColors.accentFlame : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nome do Produto
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: _buildInputDecoration('Nome do Produto', 'Ex: Botijão de Gás P13'),
                ),
                const SizedBox(height: 10),

                // Marca / Distribuidora
                TextField(
                  controller: brandController,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: _buildInputDecoration('Marca / Selo', 'Ex: Ultragaz, Liquigás, Bonafont'),
                ),
                const SizedBox(height: 10),

                // Preços: Recarga e Completo
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: refillPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                        decoration: _buildInputDecoration('Preço Recarga (R\$)', 'Ex: 104.90'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: shellPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                        decoration: _buildInputDecoration('Preço Completo (R\$)', 'Ex: 289.00'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Categoria
                DropdownButtonFormField<ProductCategory>(
                  initialValue: selectedCategory,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: _buildInputDecoration('Categoria', ''),
                  items: const [
                    DropdownMenuItem(value: ProductCategory.p13, child: Text('Botijão P13 (Residencial)')),
                    DropdownMenuItem(value: ProductCategory.water20l, child: Text('Água Mineral 20L')),
                    DropdownMenuItem(value: ProductCategory.p45, child: Text('Cilindro P45 (Comercial)')),
                    DropdownMenuItem(value: ProductCategory.p20, child: Text('Cilindro P20 (Empilhadeira)')),
                    DropdownMenuItem(value: ProductCategory.accessories, child: Text('Acessórios (Válvula / Mangueira)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),

                // Switch de Estoque
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Disponível para Venda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('Se desligado, aparecerá como esgotado aos clientes', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                        ],
                      ),
                      Switch(
                        value: inStock,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) => setModalState(() => inStock = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Botão Salvar Fixo
                SizedBox(
                  width: double.infinity,
                  child: BoraButton.flame(
                    text: isEditing ? 'Salvar Alterações' : 'Cadastrar no Depósito',
                    icon: Icons.check_circle_rounded,
                    height: 50,
                    onPressed: () {
                      final name = nameController.text.trim();
                      final brand = brandController.text.trim();
                      final refill = double.tryParse(refillPriceController.text.replaceAll(',', '.')) ?? 0.0;
                      final shell = double.tryParse(shellPriceController.text.replaceAll(',', '.')) ?? 0.0;

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Informe o nome do produto.')),
                        );
                        return;
                      }

                      final newProd = ProductModel(
                        id: productToEdit?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
                        storeId: currentStore.id,
                        storeName: currentStore.name,
                        name: name,
                        brandName: brand.isNotEmpty ? brand : 'BoraGás',
                        category: selectedCategory,
                        refillPrice: refill,
                        shellPrice: shell,
                        imageUrl: selectedImage,
                        description: descriptionController.text.trim(),
                        inStock: inStock,
                      );

                      if (isEditing) {
                        ref.read(productsProvider.notifier).update(
                              (list) => list.map((p) => p.id == newProd.id ? newProd : p).toList(),
                            );
                      } else {
                        ref.read(productsProvider.notifier).update((list) => [newProd, ...list]);
                      }

                      if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
                        SupabaseService.client.from('products').upsert({
                          'id': newProd.id,
                          'store_id': newProd.storeId,
                          'name': newProd.name,
                          'brand_name': newProd.brandName,
                          'category': newProd.category.name,
                          'refill_price': newProd.refillPrice,
                          'shell_price': newProd.shellPrice,
                          'image_url': newProd.imageUrl,
                          'description': newProd.description,
                          'in_stock': newProd.inStock,
                        }).catchError((_) {});
                      }

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Produto atualizado com sucesso!' : 'Produto cadastrado com sucesso!'),
                          backgroundColor: AppColors.success,
                        ),
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

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
    );
  }

  void _confirmDeleteProduct(ProductModel prod) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Produto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Deseja excluir "${prod.name}" do seu catálogo?', style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(productsProvider.notifier).update((list) => list.where((p) => p.id != prod.id).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${prod.name}" removido.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allProducts = ref.watch(productsProvider).where((p) => p.storeId == currentStore.id).toList();

    final filteredProducts = allProducts.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brandName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategoryFilter == null || p.category == _selectedCategoryFilter;
      return matchesSearch && matchesCat;
    }).toList();

    final activeCount = allProducts.where((p) => p.inStock).length;
    final outOfStockCount = allProducts.where((p) => !p.inStock).length;

    return Container(
      color: AppColors.merchantCanvas,
      child: CustomScrollView(
        slivers: [
          // Header (Responsivo Mobile-First)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 500;
                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catálogo & Depósito',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentStore.name} • ${allProducts.length} itens cadastrados',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: BoraButton.flame(
                            text: 'Adicionar Produto ao Catálogo',
                            icon: Icons.add_rounded,
                            height: 44,
                            borderRadius: 12,
                            onPressed: () => _showProductFormDialog(),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catálogo & Depósito',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentStore.name} • ${allProducts.length} itens cadastrados',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      BoraButton.flame(
                        text: 'Novo Item',
                        icon: Icons.add_rounded,
                        height: 40,
                        borderRadius: 12,
                        onPressed: () => _showProductFormDialog(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Resumo Métrico Horizontal
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  BoraKpiCard(
                    label: 'Total de Itens',
                    value: '${allProducts.length}',
                    icon: Icons.inventory_2_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    subtitle: 'Itens no sistema',
                  ),
                  const SizedBox(width: 10),
                  BoraKpiCard(
                    label: 'Em Venda',
                    value: '$activeCount',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                    subtitle: 'Visíveis no app',
                  ),
                  const SizedBox(width: 10),
                  BoraKpiCard(
                    label: 'Pausados',
                    value: '$outOfStockCount',
                    icon: Icons.pause_circle_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    subtitle: 'Esgotados/Pausa',
                  ),
                ],
              ),
            ),
          ),

          // Barra de Busca
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Buscar botijão, galão de água, marca...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.merchantCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentFlame, width: 1.5)),
                ),
              ),
            ),
          ),

          // Chips de Categoria
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildCategoryFilterChip('Todos', null),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip('Gás P13', ProductCategory.p13),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip('Água 20L', ProductCategory.water20l),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip('Cilindro P45', ProductCategory.p45),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip('P20 Empilhadeira', ProductCategory.p20),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip('Acessórios', ProductCategory.accessories),
                ],
              ),
            ),
          ),

          // Lista de Produtos
          if (filteredProducts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: BoraEmptyState(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.accentFlame,
                title: _searchQuery.isNotEmpty ? 'Nenhum item encontrado' : 'Nenhum produto cadastrado',
                description: _searchQuery.isNotEmpty
                    ? 'Tente outro termo de busca ou limpe o filtro de categoria.'
                    : 'Cadastre seu primeiro botijão ou galão de água para começar a vender.',
                buttonText: _searchQuery.isEmpty ? 'Cadastrar Primeiro Produto' : null,
                onButtonPressed: _searchQuery.isEmpty ? () => _showProductFormDialog() : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
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

  Widget _buildCategoryFilterChip(String label, ProductCategory? category) {
    final isSelected = _selectedCategoryFilter == category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategoryFilter = category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentFlame : AppColors.merchantCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentFlame : AppColors.merchantCardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel prod) {
    final isGas = _isGasItem(prod);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BoraCard(
        color: AppColors.merchantCard,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem com preview
                Stack(
                  children: [
                    ProductImagePreview(
                      imageUrl: prod.imageUrl,
                      width: 68,
                      height: 68,
                      borderRadius: 14,
                    ),
                    if (!prod.inStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'PAUSADO',
                              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Dados
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
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge Semântico Gás x Água
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isGas ? AppColors.gasTagBgDark : AppColors.waterTagBgDark,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isGas ? AppColors.accentFlame.withValues(alpha: 0.3) : const Color(0xFF0284C7).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isGas ? 'GÁS' : 'ÁGUA',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: isGas ? AppColors.accentFlame : const Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prod.brandName,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // Preços
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Troca: R\$ ${prod.refillPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF38BDF8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Completo: R\$ ${prod.shellPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: AppColors.merchantDivider),
            const SizedBox(height: 8),

            // Ações de Rodapé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Estoque Imediato:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    Switch(
                      value: prod.inStock,
                      activeThumbColor: AppColors.success,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        final updated = prod.copyWith(inStock: val);
                        ref.read(productsProvider.notifier).update(
                              (list) => list.map((p) => p.id == prod.id ? updated : p).toList(),
                            );
                        if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
                          SupabaseService.client
                              .from('products')
                              .update({'in_stock': val})
                              .eq('id', prod.id)
                              .catchError((_) {});
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 19),
                      tooltip: 'Editar Produto',
                      onPressed: () => _showProductFormDialog(productToEdit: prod),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 19),
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
