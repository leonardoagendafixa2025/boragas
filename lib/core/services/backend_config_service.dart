import 'package:shared_preferences/shared_preferences.dart';

class BackendConfigService {
  static const String defaultUrl = 'https://boragas-backend.onrender.com';
  static const String prefKey = 'boragas_backend_url';

  static String _currentUrl = defaultUrl;

  static String get baseUrl => _currentUrl;

  static Future<String> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _currentUrl = saved.trim().replaceAll(RegExp(r'/+$'), '');
      } else {
        _currentUrl = defaultUrl;
        await prefs.setString(prefKey, defaultUrl);
      }
    } catch (_) {
      _currentUrl = defaultUrl;
    }
    return _currentUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    _currentUrl = clean.isNotEmpty ? clean : defaultUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, _currentUrl);
    } catch (_) {}
  }
}
