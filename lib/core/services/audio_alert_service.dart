import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioAlertService {
  static void playNewOrderAlert() {
    try {
      // Haptic feedback & System chime
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      debugPrint('🔔 [AudioAlertService] Alerta sonoro de novo pedido BoraGás emitido!');
    } catch (e) {
      debugPrint('Erro ao reproduzir alerta sonoro: $e');
    }
  }
}
