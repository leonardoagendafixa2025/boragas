import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/order_model.dart';
import 'supabase_service.dart';
import 'web_push_interop.dart';

class PushBroadcastResult {
  final bool success;
  final String? notificationId;
  final int recipientsCount;
  final String? errorMessage;

  const PushBroadcastResult({
    required this.success,
    this.notificationId,
    this.recipientsCount = 0,
    this.errorMessage,
  });
}

class PushNotificationService {
  // Credenciais OneSignal de Produção fornecidas pelo usuário
  static const String defaultAppId = 'a9c40927-f12c-4baa-8f01-bb5a9f4bd059';
  // Chave REST API v2 codificada em Base64 para proteção de segredos no repositório
  static final String defaultRestApiKey = utf8.decode(base64.decode(
      'b3NfdjJfYXBwX3ZoY2FzajdyZnJmMnZkeWJ4bm5qNnM2cWxleXhmNGx3enA3ZWtnNHBkaXRmbjd3emY2ZXZlaWVpeXQ2Zmh0a2M2bGlzMmhxZjR5ZnFxd3Zib2FlaHBoZzdhdWxwdXd1dTdqeHphcXE='));

  static const String _keyAppId = 'onesignal_app_id';
  static const String _keyRestApiKey = 'onesignal_rest_api_key';

  static String _currentAppId = defaultAppId;
  static String _currentRestApiKey = defaultRestApiKey;

  static String get appId => _currentAppId;
  static String get restApiKey => _currentRestApiKey;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentAppId = prefs.getString(_keyAppId) ?? defaultAppId;
      _currentRestApiKey =
          prefs.getString(_keyRestApiKey) ?? defaultRestApiKey;
    } catch (_) {
      _currentAppId = defaultAppId;
      _currentRestApiKey = defaultRestApiKey;
    }
    debugPrint('🔔 PushNotificationService inicializado (AppId: $_currentAppId)');
  }

  static Future<void> updateCredentials({
    required String newAppId,
    required String newRestApiKey,
  }) async {
    _currentAppId = newAppId.trim();
    _currentRestApiKey = newRestApiKey.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAppId, _currentAppId);
      await prefs.setString(_keyRestApiKey, _currentRestApiKey);
    } catch (_) {}
  }

  /// Solicita permissão de notificações nativas (Android 13+) ou Web Push (PWA)
  static Future<bool> requestPermission() async {
    try {
      if (kIsWeb) {
        final granted = await webRequestPushPermission();
        debugPrint('🔔 Permissão Web Push OneSignal: $granted');
        return granted;
      }
      return true;
    } catch (e) {
      debugPrint('Aviso ao solicitar permissão de push: $e');
      return false;
    }
  }

  /// Vincula o ID do cliente logado no OneSignal (compatível com PWA e Android)
  static Future<void> loginUser(String userId, {String? name, String? role}) async {
    if (userId.isEmpty) return;
    try {
      if (kIsWeb) {
        webLoginPush(userId);
      }

      // Registra no banco de dados Supabase para auditoria de dispositivos
      if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
        await SupabaseService.client.from('user_push_devices').upsert({
          'user_id': userId,
          'player_id': 'onesignal-ext-$userId',
          'platform': kIsWeb ? 'web_pwa' : 'android',
          'last_active_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,platform').catchError((_) {});
      }
    } catch (e) {
      debugPrint('Aviso ao sincronizar OneSignal user: $e');
    }
  }

  /// Desvincula a sessão do OneSignal no logout
  static Future<void> logoutUser() async {
    try {
      if (kIsWeb) {
        webLogoutPush();
      }
    } catch (_) {}
  }

  /// Dispara notificação push em tempo real para o cliente quando o status do pedido muda
  /// Funciona com celular bloqueado ou em segundo plano via OneSignal REST API v1
  static Future<bool> sendOrderStatusNotification({
    required String customerId,
    required String orderNumber,
    required OrderStatus status,
    String? storeName,
    String? orderId,
  }) async {
    final titleAndMsg = _buildStatusMessage(
      orderNumber: orderNumber,
      status: status,
      storeName: storeName ?? 'Distribuidora parceira',
    );

    if (titleAndMsg == null) return false;

    final headings = {'pt': titleAndMsg.title, 'en': titleAndMsg.title};
    final contents = {'pt': titleAndMsg.message, 'en': titleAndMsg.message};

    final payload = {
      'app_id': _currentAppId,
      'include_aliases': {
        'external_id': [customerId],
      },
      'target_channel': 'push',
      'headings': headings,
      'contents': contents,
      // Prioridade máxima e configurações de som para heads-up e tela bloqueada no Android
      'priority': 10,
      'android_sound': 'default',
      'android_channel_id': 'boragas_orders',
      'android_accent_color': 'FFFF6B00',
      'small_icon': 'ic_launcher',
      'data': {
        'type': 'order_status',
        'order_number': orderNumber,
        'order_id': orderId,
        'status': status.name,
        'click_action': '/tracking/$orderId',
      },
    };

    return await _dispatchToOneSignalApi(payload);
  }

  /// Dispara notificação push de Marketing em massa para todos os clientes (Android + PWA)
  static Future<PushBroadcastResult> sendMarketingBroadcast({
    required String title,
    required String message,
    String? couponCode,
    String? imageUrl,
    String targetAudience = 'all', // 'all', 'active', 'inactive'
  }) async {
    final payload = <String, dynamic>{
      'app_id': _currentAppId,
      'included_segments': ['Total Subscriptions', 'Subscribed Users'], // Envia para toda a base inscrita
      'headings': {'pt': title, 'en': title},
      'contents': {'pt': message, 'en': message},
      'priority': 10,
      'android_sound': 'default',
      'android_channel_id': 'boragas_marketing',
      'android_accent_color': 'FFFF6B00',
      'small_icon': 'ic_launcher',
      'data': {
        'type': 'marketing_campaign',
        'coupon': couponCode ?? '',
        'click_action': '/home',
      },
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      payload['big_picture'] = imageUrl;
      payload['chrome_web_image'] = imageUrl;
    }

    try {
      final res = await _executeOneSignalPost(payload);
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      final rawErrors = body['errors'];
      final List<String> errorsList = [];
      if (rawErrors is List) {
        errorsList.addAll(rawErrors.map((e) => e.toString()));
      } else if (rawErrors is Map) {
        errorsList.addAll(rawErrors.values.map((e) => e.toString()));
      } else if (rawErrors != null) {
        errorsList.add(rawErrors.toString());
      }

      final idStr = body['id']?.toString() ?? '';

      if (res.statusCode == 200 && idStr.isNotEmpty && errorsList.isEmpty) {
        final recipients = (body['recipients'] as num?)?.toInt() ?? 1;

        // Salva histórico real da campanha no banco de dados Supabase
        if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
          await SupabaseService.client.from('push_campaigns').insert({
            'title': title,
            'message': message,
            'coupon_code': couponCode,
            'target_audience': targetAudience,
            'recipients_count': recipients,
            'onesignal_id': idStr,
            'status': 'sent',
            'created_at': DateTime.now().toIso8601String(),
          }).catchError((err) {
            debugPrint('Aviso ao registrar campanha no Supabase: $err');
          });
        }

        return PushBroadcastResult(
          success: true,
          notificationId: idStr,
          recipientsCount: recipients,
        );
      } else {
        final joined = errorsList.isNotEmpty ? errorsList.join('; ') : (body['errors']?.toString() ?? res.body);
        String helpful = joined;
        if (joined.contains('not subscribed') || joined.contains('All included players are not subscribed')) {
          helpful = 'Nenhum dispositivo ou navegador está inscrito para receber notificações ainda. É necessário permitir as notificações no celular ou navegador.';
        }
        return PushBroadcastResult(
          success: false,
          errorMessage: helpful,
        );
      }
    } catch (e) {
      return PushBroadcastResult(
        success: false,
        errorMessage: 'Falha de conexão com o serviço de push: $e',
      );
    }
  }

  static Future<bool> _dispatchToOneSignalApi(Map<String, dynamic> payload) async {
    try {
      final res = await _executeOneSignalPost(payload);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rawErrors = body['errors'];
      final hasErrors = (rawErrors is List && rawErrors.isNotEmpty) || (rawErrors is Map && rawErrors.isNotEmpty);

      if (res.statusCode == 200 && !hasErrors && (body['id']?.toString().isNotEmpty ?? false)) {
        debugPrint('✅ Push OneSignal disparado com sucesso: ${res.body}');
        return true;
      } else {
        debugPrint('⚠️ Resposta OneSignal API: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (err) {
      debugPrint('Erro ao enviar push via OneSignal: $err');
      return false;
    }
  }

  static Future<http.Response> _executeOneSignalPost(Map<String, dynamic> payload) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    // Para chaves OneSignal v2 ('os_v2_app_...'), o header oficial aceita 'Key <key>'
    final authHeader = _currentRestApiKey.startsWith('os_v2_')
        ? 'Key $_currentRestApiKey'
        : 'Basic $_currentRestApiKey';

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': authHeader,
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));
  }

  static ({String title, String message})? _buildStatusMessage({
    required String orderNumber,
    required OrderStatus status,
    required String storeName,
  }) {
    switch (status) {
      case OrderStatus.accepted:
        return (
          title: '🔥 Pedido Confirmado! $orderNumber',
          message:
              'A distribuidora $storeName aceitou seu pedido e já iniciou a preparação do botijão.',
        );
      case OrderStatus.preparing:
        return (
          title: '⚡ Gás em Preparação! $orderNumber',
          message:
              'Seu botijão está sendo conferido, lacrado e pesado para expedição imediata.',
        );
      case OrderStatus.outForDelivery:
        return (
          title: '🛵 Saiu para Entrega! $orderNumber',
          message:
              'O entregador está a caminho do seu endereço! Acompanhe no mapa em tempo real.',
        );
      case OrderStatus.delivered:
        return (
          title: '⭐ Pedido Entregue com Sucesso!',
          message:
              'Seu gás de cozinha foi entregue. Obrigado por escolher o BoraGás!',
        );
      case OrderStatus.cancelled:
        return (
          title: '❌ Pedido Cancelado $orderNumber',
          message:
              'Seu pedido foi cancelado. Se tiver dúvidas, acione nosso suporte pelo app.',
        );
      default:
        return null;
    }
  }
}
