import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/models/store_model.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/product_image_preview.dart';
import '../../providers/cart_provider.dart';

class ProductBottomSheet extends ConsumerStatefulWidget {
  final ProductModel product;
  final StoreModel store;

  const ProductBottomSheet({
    super.key,
    required this.product,
    required this.store,
  });

  @override
  ConsumerState<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends ConsumerState<ProductBottomSheet> {
  bool _isRefillOnly = true; // true = Troca (tem vasilhame), false = Comprar Casco
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _unitPrice => _isRefillOnly
      ? widget.product.refillPrice
      : widget.product.shellPrice;

  double get _totalPrice => _unitPrice * _quantity;

  void _addToCart() {
    final success = ref.read(cartProvider.notifier).addItem(
          product: widget.product,
          store: widget.store,
          quantity: _quantity,
          isRefillOnly: _isRefillOnly,
        );

    if (!success) {
      // Conflict with another store
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limpar sacola atual?'),
          content: Text(
            'Sua sacola já contém itens de outra loja. Deseja esvaziar a sacola para adicionar itens de "${widget.store.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(cartProvider.notifier).clearCart();
                ref.read(cartProvider.notifier).addItem(
                      product: widget.product,
                      store: widget.store,
                      quantity: _quantity,
                      isRefillOnly: _isRefillOnly,
                    );
                Navigator.pop(context);
                context.push('/cart');
              },
              child: const Text('Sim, esvaziar e adicionar'),
            ),
          ],
        ),
      );
      return;
    }

    if (_notesController.text.trim().isNotEmpty) {
      ref.read(cartProvider.notifier).setNotes(_notesController.text.trim());
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${widget.product.name} adicionado à sacola!',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1800),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Product & Store
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductImagePreview(
                          imageUrl: widget.product.imageUrl,
                          productName: widget.product.name,
                          width: 80,
                          height: 80,
                          borderRadius: 14,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: AppTypography.titleLarge.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vendido e entregue por ${widget.store.name}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.product.description,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Mandatory Option Selection
                    Text(
                      'SELECIONE A MODALIDADE (OBRIGATÓRIO):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Option 1: Troca (Tem Vasilhame)
                    _buildOptionCard(
                      title: 'Troca de Vasilhame (Já tenho o botijão/galão vazio)',
                      subtitle:
                          'Entregue seu casco vazio na mesma capacidade e pague apenas o conteúdo.',
                      price: widget.product.refillPrice,
                      isSelected: _isRefillOnly,
                      badge: 'MAIS ECONÔMICO',
                      badgeColor: AppColors.success,
                      onTap: () => setState(() => _isRefillOnly = true),
                    ),

                    const SizedBox(height: 10),

                    // Option 2: Comprar Casco Novo Completo
                    _buildOptionCard(
                      title: 'Comprar Casco Completo (Não tenho vasilhame)',
                      subtitle:
                          'Receba o vasilhame lacrado + a carga inicial de gás/água para começar.',
                      price: widget.product.shellPrice,
                      isSelected: !_isRefillOnly,
                      badge: 'CASCO + CARGA',
                      badgeColor: AppColors.primary,
                      onTap: () => setState(() => _isRefillOnly = false),
                    ),

                    const SizedBox(height: 20),

                    // Quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantidade',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                icon: const Icon(Icons.remove, size: 18),
                              ),
                              Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _quantity++),
                                icon: const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Courier Notes
                    const Text(
                      'Observações para a entrega (opcional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Ex.: Tocar o interfone 82, subida por escada, deixar na portaria...',
                        hintStyle: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'R\$ ${_totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: AppTypography.priceHighlight.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AppButton(
                      label: 'Adicionar à Sacola',
                      isFlameAccent: true,
                      icon: Icons.shopping_bag_rounded,
                      onPressed: _addToCart,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required double price,
    required bool isSelected,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
