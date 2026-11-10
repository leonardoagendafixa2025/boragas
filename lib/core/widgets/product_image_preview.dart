import 'package:flutter/material.dart';

/// Componente seguro para exibição de fotos de produtos do BoraGás.
/// Suporta URLs remotas (HTTP/HTTPS) e assets locais do app com fallback automático.
class ProductImagePreview extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const ProductImagePreview({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    final isNetwork = trimmed.startsWith('http://') || trimmed.startsWith('https://');

    Widget imageWidget;
    if (isNetwork) {
      imageWidget = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      imageWidget = Image.asset(
        trimmed.isNotEmpty ? trimmed : 'assets/images/app_icon.png',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }
    return imageWidget;
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
