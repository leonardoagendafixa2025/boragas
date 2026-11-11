import 'package:flutter/material.dart';

/// Componente seguro para exibição de fotos oficiais dos produtos do BoraGás.
/// Utiliza exclusivamente os 11 ícones oficiais: 13kg, 20kg, 45kg (Dourado, Prata, Verde),
/// Água 20L e Kit Gás (regulador/mangueira).
class ProductImagePreview extends StatelessWidget {
  final String imageUrl;
  final String? productName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Color? backgroundColor;

  const ProductImagePreview({
    super.key,
    required this.imageUrl,
    this.productName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 12,
    this.backgroundColor,
  });

  static String resolveAsset(String url, {String? productName}) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('assets/images/products/')) {
      return trimmed;
    }
    final lower = '${productName ?? ''} $trimmed'.toLowerCase();
    if (lower.contains('água') || lower.contains('agua') || (lower.contains('20l') && !lower.contains('gás') && !lower.contains('gas'))) {
      return 'assets/images/products/agua_20l.png';
    }
    if (lower.contains('kit') || lower.contains('regulador') || lower.contains('mangueira') || lower.contains('acessório') || lower.contains('acessorio')) {
      return 'assets/images/products/kit_gas.png';
    }
    if (lower.contains('45') || lower.contains('p45')) {
      if (lower.contains('verde') || lower.contains('liquigás') || lower.contains('liquigas')) {
        return 'assets/images/products/gas_45kg_green.png';
      }
      if (lower.contains('prata') || lower.contains('cinza')) {
        return 'assets/images/products/gas_45kg_silver.png';
      }
      return 'assets/images/products/gas_45kg_gold.png';
    }
    if (lower.contains('20') || lower.contains('p20')) {
      if (lower.contains('verde') || lower.contains('liquigás') || lower.contains('liquigas')) {
        return 'assets/images/products/gas_20kg_green.png';
      }
      if (lower.contains('prata') || lower.contains('cinza')) {
        return 'assets/images/products/gas_20kg_silver.png';
      }
      return 'assets/images/products/gas_20kg_gold.png';
    }
    // Default P13
    if (lower.contains('verde') || lower.contains('liquigás') || lower.contains('liquigas')) {
      return 'assets/images/products/gas_13kg_green.png';
    }
    if (lower.contains('prata') || lower.contains('cinza')) {
      return 'assets/images/products/gas_13kg_silver.png';
    }
    return 'assets/images/products/gas_13kg_gold.png';
  }

  @override
  Widget build(BuildContext context) {
    final effectivePath = resolveAsset(imageUrl, productName: productName);
    final isNetwork = effectivePath.startsWith('http://') || effectivePath.startsWith('https://');

    Widget imageWidget;
    if (isNetwork) {
      imageWidget = Image.network(
        effectivePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFFFF6B00),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      imageWidget = Image.asset(
        effectivePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    final containerWidget = Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.white,
      padding: const EdgeInsets.all(4),
      child: Center(child: imageWidget),
    );

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: containerWidget,
      );
    }
    return containerWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF0F172A),
      child: Center(
        child: Icon(
          Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6B00),
          size: (width != null && width! < 40) ? 18 : 26,
        ),
      ),
    );
  }
}
