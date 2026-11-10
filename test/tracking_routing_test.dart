import 'package:boragas/core/models/tracking_models.dart';
import 'package:boragas/core/utils/geo_utils.dart';
import 'package:boragas/core/widgets/map/boragas_interactive_map.dart';
import 'package:boragas/core/widgets/map/boragas_vehicle_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('GeoUtils Tests', () {
    test('Haversine distance between São Paulo MASP and Praça da Sé', () {
      const p1 = LatLng(-23.5614, -46.6558); // MASP
      const p2 = LatLng(-23.5505, -46.6333); // Praça da Sé

      final dist = GeoUtils.haversineDistanceMeters(p1, p2);

      // Distância geodésica em linha reta deve estar entre 2.5 km e 2.7 km
      expect(dist, greaterThan(2400));
      expect(dist, lessThan(2800));

      final formatted = GeoUtils.formatDistance(dist);
      expect(formatted.contains('km'), isTrue);
    });

    test('Azimuth / Bearing calculation', () {
      const from = LatLng(0.0, 0.0);
      const north = LatLng(1.0, 0.0);
      const east = LatLng(0.0, 1.0);

      final bearingNorth = GeoUtils.calculateBearing(from, north);
      final bearingEast = GeoUtils.calculateBearing(from, east);

      expect(bearingNorth, closeTo(0.0, 0.5));
      expect(bearingEast, closeTo(90.0, 0.5));
    });

    test('Smooth Bearing deadband ignores jitter at low speeds (< 4 km/h)', () {
      final smoothed = GeoUtils.smoothBearing(
        oldBearing: 45.0,
        newBearing: 180.0,
        speedKmh: 2.5, // Parado ou manobrando
      );

      // Deve manter a orientação anterior
      expect(smoothed, equals(45.0));

      final movingSmoothed = GeoUtils.smoothBearing(
        oldBearing: 45.0,
        newBearing: 90.0,
        speedKmh: 30.0, // Em velocidade
      );

      // Deve interpolar suavemente em direção ao novo ângulo
      expect(movingSmoothed, greaterThan(45.0));
      expect(movingSmoothed, lessThan(90.0));
    });

    test('Interpolate position linearly', () {
      const start = LatLng(0.0, 0.0);
      const end = LatLng(10.0, 20.0);

      final mid = GeoUtils.interpolatePosition(start, end, 0.5);
      expect(mid.latitude, closeTo(5.0, 0.001));
      expect(mid.longitude, closeTo(10.0, 0.001));
    });

    test('Route deviation check detects if courier strayed from path', () {
      final route = [
        const LatLng(-23.5600, -46.6500),
        const LatLng(-23.5700, -46.6500),
      ];

      // Ponto sobre a rota
      const onRoute = LatLng(-23.5650, -46.6501);
      expect(GeoUtils.hasDeviatedFromRoute(currentPos: onRoute, routePoints: route, thresholdMeters: 65), isFalse);

      // Ponto a 500m da rota
      const deviated = LatLng(-23.5650, -46.6550);
      expect(GeoUtils.hasDeviatedFromRoute(currentPos: deviated, routePoints: route, thresholdMeters: 65), isTrue);
    });
  });

  group('DeliveryLocationPing Model Tests', () {
    test('Serialization and Deserialization', () {
      final ping = DeliveryLocationPing(
        deliveryId: 'ord-999',
        courierId: 'courier-01',
        latitude: -23.5512,
        longitude: -46.6345,
        bearing: 124.5,
        speedKmh: 36.2,
        accuracyMeters: 4.8,
        timestamp: DateTime(2026, 11, 9, 18, 0, 0),
        isMoving: true,
        status: 'out_for_delivery',
        etaMinutes: 7,
        remainingDistanceMeters: 1420.0,
        vehicleType: VehicleType.motorcycleWithGasRack,
      );

      final json = ping.toJson();
      expect(json['delivery_id'], equals('ord-999'));
      expect(json['veh'], equals('motorcycleWithGasRack'));

      final recovered = DeliveryLocationPing.fromJson(json);
      expect(recovered.deliveryId, equals(ping.deliveryId));
      expect(recovered.latitude, closeTo(ping.latitude, 0.0001));
      expect(recovered.longitude, closeTo(ping.longitude, 0.0001));
      expect(recovered.bearing, closeTo(ping.bearing, 0.1));
      expect(recovered.speedKmh, closeTo(ping.speedKmh, 0.1));
      expect(recovered.vehicleType, equals(VehicleType.motorcycleWithGasRack));
    });

    test('RouteInfo fallback generates realistic urban distance and duration', () {
      const o = LatLng(-23.5505, -46.6333);
      const d = LatLng(-23.5614, -46.6558);

      final fallback = RouteInfo.directFallback(o, d);
      expect(fallback.isFallback, isTrue);
      expect(fallback.points.length, equals(2));
      expect(fallback.distanceMeters, greaterThan(2500));
      expect(fallback.etaMinutes, greaterThan(0));
    });
  });

  group('Map UI Widgets Test', () {
    testWidgets('BoraGasVehicleMarker renders smoothly for all vehicle types', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BoraGasVehicleMarker(
                bearing: 45.0,
                speedKmh: 35.0,
                isMoving: true,
                vehicleType: VehicleType.motorcycleWithGasRack,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BoraGasVehicleMarker), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('BoraGasInteractiveMap renders without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BoraGasInteractiveMap(
              destination: LatLng(-23.5614, -46.6558),
              initialCourierPosition: LatLng(-23.5535, -46.6412),
              height: 300,
            ),
          ),
        ),
      );

      expect(find.byType(BoraGasInteractiveMap), findsOneWidget);
      // Aguardar frames de renderização do flutter_map
      await tester.pumpAndSettle();
    });
  });
}
