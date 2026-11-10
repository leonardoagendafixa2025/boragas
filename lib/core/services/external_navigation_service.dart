import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Serviço para iniciar aplicativos de navegação GPS externa (Waze e Google Maps)
/// mantendo a captura do BoraGás ativa em segundo plano via Foreground Service.
class ExternalNavigationService {
  /// Abre o Waze direcionado às coordenadas de destino
  static Future<bool> openWaze({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Tentar URI nativo do Waze
    final wazeUri = Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');
    // 2. Fallback Web do Waze
    final fallbackUri = Uri.parse('https://waze.com/ul?ll=$latitude,$longitude&navigate=yes');

    try {
      if (await canLaunchUrl(wazeUri)) {
        return await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[ExternalNavigationService] Erro ao abrir Waze: $e');
      try {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  /// Abre o Google Maps direcionado às coordenadas de destino
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Tentar URI nativo de navegação do Google Maps
    final googleMapsUri = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
    // 2. Fallback Universal Web
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        return await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[ExternalNavigationService] Erro ao abrir Google Maps: $e');
      try {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }
}
