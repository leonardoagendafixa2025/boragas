import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/order_model.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confetti_celebration.dart';
import '../../../core/widgets/product_image_preview.dart';
import '../../../core/widgets/slide_to_action.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_providers.dart';
import '../providers/marketing_providers.dart';

class CartCheckoutScreen extends ConsumerStatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  ConsumerState<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends ConsumerState<CartCheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _changeController = TextEditingController();
  bool _isProcessing = false;
  bool _showConfetti = false;

  @override
  void dispose() {
    _couponController.dispose();
    _changeController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final success = ref.read(cartProvider.notifier).applyCoupon(_couponController.text);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cupom aplicado com sucesso! R\$ 10 OFF'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cupom inválido. Tente BORAGAS10'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submitOrder() async {
    if (_isProcessing) return; // Trava imediata anti-duplo clique
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || cart.store == null) return;

    final address = ref.read(currentAddressProvider);

    setState(() => _isProcessing = true);

    // Simulate direct store API processing
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    if (cart.selectedPaymentMode == PaymentMode.cashOnDelivery &&
        _changeController.text.isNotEmpty) {
      final changeAmount = double.tryParse(_changeController.text.replaceAll(',', '.'));
      ref.read(cartProvider.notifier).setChangeForAmount(changeAmount);
    }

    final createdOrder = ref.read(cartProvider.notifier).checkout(address.formatted);

    setState(() {
      _isProcessing = false;
      _showConfetti = true;
    });
    HapticFeedback.heavyImpact();

    // If online PIX, show dynamic QR code modal before routing
    if (createdOrder.paymentMode == PaymentMode.onlinePix) {
      if (mounted) {
        await _showPixQrCodeDialog(createdOrder);
      }
    }

    if (mounted) {
      context.go('/tracking/${createdOrder.id}');
    }
  }

  Future<void> _showPixQrCodeDialog(OrderModel order) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.gasCyan.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'PIX Direto para a Loja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'O valor de R\$ ${order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')} vai 100% direto para ${order.storeName} via Mercado Pago / API:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 160, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(
                  text: '00020126580014br.gov.bcb.pix0136boragas-loja@direct.com520400005303986',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código PIX Copia e Cola copiado!')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copiar Chave PIX'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Já Efetuei o Pagamento'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final address = ref.watch(currentAddressProvider);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sacola')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 70, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Sua sacola está vazia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escolha botijões de gás ou galões de água na Home.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Explorar Lojas & Preços',
                width: 240,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Sacola • ${cart.store?.name ?? ""}'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
            },
            child: const Text('Limpar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Entregar em ${address.label}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '⚡ ~25 min',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentFlame,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          address.formatted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cart Items
            const Text(
              'ITENS DO PEDIDO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            ...cart.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ProductImagePreview(
                      imageUrl: item.product.imageUrl,
                      productName: item.product.name,
                      width: 50,
                      height: 50,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            item.isRefillOnly
                                ? 'Troca de Vasilhame Vazio'
                                : 'Comprar Casco Completo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.isRefillOnly ? AppColors.success : AppColors.primary,
                            ),
                          ),
                          Text(
                            'R\$ ${item.unitPrice.toStringAsFixed(2).replaceAll('.', ',')} cada',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    // Quantity controls
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () => ref
                              .read(cartProvider.notifier)
                              .updateQuantity(index, item.quantity - 1),
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => ref
                              .read(cartProvider.notifier)
                              .updateQuantity(index, item.quantity + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Referral Wallet Credits Redemption Strip
            Consumer(
              builder: (context, ref, child) {
                final wallet = ref.watch(referralWalletProvider);
                if (wallet.creditBalance <= 0 || cart.discount > 0) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD8B4FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF7E22CE), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Você tem R\$ ${wallet.creditBalance.toStringAsFixed(2).replaceAll('.', ',')} em créditos!',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF581C87)),
                            ),
                            const Text(
                              'Abata no pedido usando saldo de indicações',
                              style: TextStyle(fontSize: 10, color: Color(0xFF7E22CE)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7E22CE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          ref.read(cartProvider.notifier).applyCoupon('BORAGAS10');
                          ref.read(referralWalletProvider.notifier).applyCredits(10.0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 R\$ 10,00 de créditos aplicados ao pedido!'),
                              backgroundColor: Color(0xFF7E22CE),
                            ),
                          );
                        },
                        child: const Text('Usar R\$ 10', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Coupon Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_num_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: const InputDecoration(
                        hintText: 'Cupom (ex: BORAGAS10)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Mode Section (Direct to Store BYOK & Smart POS)
            const Text(
              'FORMA DE PAGAMENTO (100% DIRETO PARA A LOJA)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Group 1: Pagar Online Agora
            _buildPaymentOption(
              mode: PaymentMode.onlinePix,
              title: 'PIX Online (Direto p/ Loja via API)',
              subtitle: 'Aprovação imediata com QR Code dinâmico',
              icon: Icons.pix_rounded,
              currentMode: cart.selectedPaymentMode,
              badge: 'MAIS RÁPIDO',
            ),
            _buildPaymentOption(
              mode: PaymentMode.onlineCard,
              title: 'Cartão de Crédito Online',
              subtitle: 'Processado pela API própria da distribuidora',
              icon: Icons.credit_card_rounded,
              currentMode: cart.selectedPaymentMode,
            ),

            // Group 2: Pagar na Entrega
            const SizedBox(height: 8),
            _buildPaymentOption(
              mode: PaymentMode.posOnDelivery,
              title: 'Maquininha na Entrega (Smart POS)',
              subtitle: 'Débito, Crédito ou PIX no visor da maquininha',
              icon: Icons.point_of_sale_rounded,
              currentMode: cart.selectedPaymentMode,
            ),
            _buildPaymentOption(
              mode: PaymentMode.cashOnDelivery,
              title: 'Dinheiro na Entrega',
              subtitle: 'Pague ao entregador em espécie',
              icon: Icons.attach_money_rounded,
              currentMode: cart.selectedPaymentMode,
            ),

            if (cart.selectedPaymentMode == PaymentMode.cashOnDelivery) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _changeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Precisa de troco para quanto? (Ex: 150,00)',
                  hintText: 'Deixe em branco se tiver o valor exato',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Financial Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal dos Itens', cart.subtotal),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Taxa de Entrega',
                    cart.deliveryFee,
                    isFree: cart.deliveryFee == 0,
                  ),
                  if (cart.discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow('Desconto do Cupom', -cart.discount, isDiscount: true),
                  ],
                  if (cart.clubDiscount > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow('Clube BoraGás (5% OFF)', -cart.clubDiscount, isDiscount: true),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total a Pagar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'R\$ ${cart.total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: AppTypography.priceHighlight.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Slide to Action (Swipe to Confirm)
            SlideToActionWidget(
              label: 'Deslize para Fazer Pedido',
              icon: Icons.local_fire_department_rounded,
              isLoading: _isProcessing,
              activeTrackColor: AppColors.accentFlame,
              onCompleted: _submitOrder,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      if (_showConfetti)
        ConfettiCelebrationOverlay(
          onFinished: () {
            if (mounted) setState(() => _showConfetti = false);
          },
        ),
    ],
  ),
);
  }

  Widget _buildPaymentOption({
    required PaymentMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required PaymentMode currentMode,
    String? badge,
  }) {
    final isSelected = mode == currentMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => ref.read(cartProvider.notifier).setPaymentMode(mode),
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
        trailing: Container(
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
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value,
      {bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          isFree
              ? 'Grátis'
              : '${isDiscount ? "- " : ""}R\$ ${value.abs().toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isFree || isDiscount ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
