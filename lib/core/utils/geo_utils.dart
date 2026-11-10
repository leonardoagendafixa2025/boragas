import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class GeoUtils {
  static const double earthRadiusMeters = 6371000.0;

  /// Retorna a distância em metros entre dois pontos geográficos usando a fórmula de Haversine.
  static double haversineDistanceMeters(LatLng p1, LatLng p2) {
    final lat1 = p1.latitude * math.pi / 180.0;
    final lat2 = p2.latitude * math.pi / 180.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180.0;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Retorna a distância formatada para o usuário (ex: "850 m" ou "2,4 km").
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
    }
  }

  /// Calcula o ângulo de azimute / bearing esférico (0° a 360°) entre dois pontos.
  static double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final dLng = (to.longitude - from.longitude) * math.pi / 180.0;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final radians = math.atan2(y, x);
    final degrees = (radians * 180.0 / math.pi + 360.0) % 360.0;

    return degrees;
  }

  /// Filtro passa-baixas para suavizar rotações de agulha e ignorar oscilações em baixas velocidades (< 4 km/h).
  static double smoothBearing({
    required double oldBearing,
    required double newBearing,
    required double speedKmh,
  }) {
    if (speedKmh < 4.0) {
      // Quando parado no semáforo ou em manobra lenta, mantém a orientação anterior
      return oldBearing;
    }

    // Calcular menor diferença angular considerando o ciclo de 360 graus
    double diff = (newBearing - oldBearing) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;

    // Fator de suavização (alfa = 0.35)
    return (oldBearing + (diff * 0.35) + 360.0) % 360.0;
  }

  /// Interpolação linear entre duas coordenadas para animação fluída sem saltos.
  static LatLng interpolatePosition(LatLng start, LatLng end, double fraction) {
    final clampedFraction = fraction.clamp(0.0, 1.0);
    final lat = start.latitude + (end.latitude - start.latitude) * clampedFraction;
    final lng = start.longitude + (end.longitude - start.longitude) * clampedFraction;
    return LatLng(lat, lng);
  }

  /// Verifica se o entregador desviou da rota planejada em mais de [thresholdMeters].
  static bool hasDeviatedFromRoute({
    required LatLng currentPos,
    required List<LatLng> routePoints,
    double thresholdMeters = 65.0,
  }) {
    if (routePoints.isEmpty) return false;

    double minDistance = double.infinity;
    for (int i = 0; i < routePoints.length - 1; i++) {
      final dist = distanceToSegment(currentPos, routePoints[i], routePoints[i + 1]);
      if (dist < minDistance) {
        minDistance = dist;
      }
      if (minDistance <= thresholdMeters) {
        return false; // Ainda está próximo de pelo menos um segmento
      }
    }

    return minDistance > thresholdMeters;
  }

  /// Calcula a menor distância perpendicular de um ponto até um segmento de reta (start-end).
  static double distanceToSegment(LatLng p, LatLng start, LatLng end) {
    final l2 = haversineDistanceMeters(start, end);
    if (l2 == 0) return haversineDistanceMeters(p, start);

    final t = ((p.latitude - start.latitude) * (end.latitude - start.latitude) +
            (p.longitude - start.longitude) * (end.longitude - start.longitude)) /
        ((end.latitude - start.latitude) * (end.latitude - start.latitude) +
            (end.longitude - start.longitude) * (end.longitude - start.longitude));

    final clampedT = t.clamp(0.0, 1.0);
    final projection = LatLng(
      start.latitude + clampedT * (end.latitude - start.latitude),
      start.longitude + clampedT * (end.longitude - start.longitude),
    );

    return haversineDistanceMeters(p, projection);
  }
}
