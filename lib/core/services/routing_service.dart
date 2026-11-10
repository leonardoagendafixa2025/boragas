import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/tracking_models.dart';
import '../utils/geo_utils.dart';

abstract class RoutingService {
  Future<RouteInfo> calculateRoute({
    required LatLng origin,
    required LatLng destination,
  });
}

/// Serviço de cálculo de rotas usando OSRM (Open Source Routing Machine).
/// Totalmente compatível com instâncias OSRM próprias (Docker) ou provedores públicos com fallback geodésico.
class OsrmRoutingService implements RoutingService {
  final String _baseUrl;
  final http.Client _client;

  // Cache em memória para rotas recentes evitando requisições duplicadas (TTL 15 min)
  final Map<String, _CachedRoute> _routeCache = {};

  OsrmRoutingService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? 'https://router.project-osrm.org',
        _client = client ?? http.Client();

  /// Gera chave de cache baseada em coordenadas arredondadas a ~11 metros
  String _cacheKey(LatLng o, LatLng d) {
    final oLat = o.latitude.toStringAsFixed(4);
    final oLng = o.longitude.toStringAsFixed(4);
    final dLat = d.latitude.toStringAsFixed(4);
    final dLng = d.longitude.toStringAsFixed(4);
    return '$oLat,$oLng->$dLat,$dLng';
  }

  @override
  Future<RouteInfo> calculateRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final key = _cacheKey(origin, destination);
    final cached = _routeCache[key];
    if (cached != null && !cached.isExpired) {
      return cached.route;
    }

    try {
      // OSRM URL: /route/v1/driving/{lng1},{lat1};{lng2},{lat2}?overview=full&geometries=geojson
      final uri = Uri.parse(
        '$_baseUrl/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
      );

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 4),
        onTimeout: () => throw Exception('OSRM request timed out'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final code = data['code'] as String?;

        if (code == 'Ok') {
          final routes = data['routes'] as List<dynamic>?;
          if (routes != null && routes.isNotEmpty) {
            final routeData = routes.first as Map<String, dynamic>;
            final distanceMeters = (routeData['distance'] as num).toDouble();
            final durationSeconds = (routeData['duration'] as num).toDouble();
            final geometry = routeData['geometry'] as Map<String, dynamic>;
            final rawCoordinates = geometry['coordinates'] as List<dynamic>;

            final points = rawCoordinates.map((c) {
              final coord = c as List<dynamic>;
              final lng = (coord[0] as num).toDouble();
              final lat = (coord[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();

            final etaMin = (durationSeconds / 60.0).ceil();
            final routeInfo = RouteInfo(
              points: points,
              distanceMeters: distanceMeters,
              durationSeconds: durationSeconds,
              etaText: '$etaMin min',
              distanceText: GeoUtils.formatDistance(distanceMeters),
              summary: 'Rota otimizada OSRM',
              isFallback: false,
            );

            _routeCache[key] = _CachedRoute(
              route: routeInfo,
              expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            );

            return routeInfo;
          }
        }
      }

      // Se OSRM retornar erro ou sem rotas válidas, gera fallback geodésico
      debugPrint('[OsrmRoutingService] Fallback acionado: status ${response.statusCode}');
      return RouteInfo.directFallback(origin, destination);
    } catch (e) {
      debugPrint('[OsrmRoutingService] Erro ao consultar rota OSRM ($e). Usando fallback.');
      return RouteInfo.directFallback(origin, destination);
    }
  }

  void clearCache() {
    _routeCache.clear();
  }
}

class _CachedRoute {
  final RouteInfo route;
  final DateTime expiresAt;

  _CachedRoute({required this.route, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
