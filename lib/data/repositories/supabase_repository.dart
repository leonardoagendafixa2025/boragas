import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/models/product_model.dart';
import '../../core/services/supabase_service.dart';
import '../mock_database.dart';

class SupabaseRepository {
  // 1. Busca Geoespacial e Comparador de Preços via RPC no Postgres
  static Future<List<ProductModel>> getNearbyProductsWithStores({
    required double lat,
    required double lng,
    String? categorySlug,
  }) async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) {
      return MockDatabase.initialProducts;
    }

    try {
      final response = await SupabaseService.client.rpc(
        'get_nearby_stores_and_products',
        params: {
          'user_lat': lat,
          'user_lng': lng,
          'category_slug_filter': categorySlug == 'all' ? null : categorySlug,
          'max_distance_km': 15.0,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        return ProductModel(
          id: item['product_id'],
          storeId: item['store_id'],
          storeName: item['store_name'],
          category: _mapSlugToCategory(item['category_slug']),
          name: item['product_name'],
          brandName: item['brand_name'] ?? 'Marca Certificada',
          description: 'Distância da loja: ${item['store_distance_km']} km',
          refillPrice: (item['refill_price'] as num).toDouble(),
          shellPrice: (item['shell_price'] as num).toDouble(),
          imageUrl: item['product_image_url'] ?? 'assets/images/app_icon.png',
          rating: (item['store_rating'] as num?)?.toDouble() ?? 5.0,
        );
      }).toList();
    } catch (e) {
      debugPrint('Erro ao chamar RPC get_nearby_stores_and_products: $e');
      return MockDatabase.initialProducts;
    }
  }

  // 2. Chamar Edge Function de Checkout Direto (BYOK Mercado Pago / Point)
  static Future<Map<String, dynamic>> createStoreDirectPayment({
    required String orderId,
    required String paymentMethod, // 'pix' | 'card' | 'smart_pos_push'
    String? cardToken,
    String? payerEmail,
  }) async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) {
      return {
        'success': true,
        'mode': paymentMethod,
        'qr_code':
            '00020126580014br.gov.bcb.pix0136boragas-loja@direct.com520400005303986540699.905802BR5915BoraGas Admin6009Sao Paulo62070503***6304',
        'message': 'Simulação BYOK Local Concluída',
      };
    }

    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-store-direct-payment',
        body: {
          'order_id': orderId,
          'payment_method': paymentMethod,
          'card_token': cardToken,
          'payer_email': payerEmail,
        },
      );

      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erro ao invocar Edge Function create-store-direct-payment: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 3. Inscrição em Tempo Real (Supabase Realtime) para Atualizações de Pedido
  static Stream<Map<String, dynamic>> listenToOrderUpdates(String orderId) {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) {
      // Stream simulada local
      return const Stream.empty();
    }

    return SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) => rows.isNotEmpty ? rows.first : <String, dynamic>{});
  }

  // 4. Inscrição em Tempo Real para Banners e Remote Config
  static Stream<List<Map<String, dynamic>>> listenToBanners() {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) {
      return const Stream.empty();
    }

    return SupabaseService.client
        .from('home_banners')
        .stream(primaryKey: ['id'])
        .order('sort_order');
  }

  static ProductCategory _mapSlugToCategory(String slug) {
    switch (slug) {
      case 'p13':
        return ProductCategory.p13;
      case 'p20':
        return ProductCategory.p20;
      case 'p45':
        return ProductCategory.p45;
      case 'water20l':
        return ProductCategory.water20l;
      default:
        return ProductCategory.accessories;
    }
  }
}
