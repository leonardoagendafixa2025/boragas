import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://boragas-placeholder.supabase.co',
  );

  static const String defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock-key',
  );

  static bool _isInitialized = false;

  static bool get isConfigured =>
      defaultUrl != 'https://boragas-placeholder.supabase.co' &&
      !defaultUrl.contains('placeholder');

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      if (defaultUrl.isNotEmpty && defaultAnonKey.isNotEmpty) {
        await Supabase.initialize(
          url: defaultUrl,
          publishableKey: defaultAnonKey,
          debug: kDebugMode,
        );
        _isInitialized = true;
        debugPrint('✅ Supabase inicializado com sucesso em $defaultUrl');
      }
    } catch (e) {
      debugPrint('ℹ️ Supabase em modo Local Mock: $e');
    }
  }

  static bool get isInitialized => _isInitialized;
}
