import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/tracking_models.dart';
import '../utils/geo_utils.dart';

/// Serviço responsável pela captura de GPS em primeiro e segundo plano,
/// com Foreground Service no Android e CoreLocation no iOS, além de simulador para Web/Desktop.
class BackgroundLocationService {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _mockTimer;
  final StreamController<DeliveryLocationPing> _pingController =
      StreamController<DeliveryLocationPing>.broadcast();

  Stream<DeliveryLocationPing> get pingStream => _pingController.stream;

  double _currentBearing = 0.0;
  LatLng? _lastKnownPosition;

  /// Verifica e solicita permissões adequadas de localização
  static Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[BackgroundLocationService] Serviços de GPS desativados');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[BackgroundLocationService] Permissão negada pelo usuário');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[BackgroundLocationService] Permissão negada permanentemente');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[BackgroundLocationService] Erro ao checar permissão: $e');
      return false;
    }
  }

  /// Inicia rastreamento contínuo em segundo plano para o entregador ativo
  Future<void> startTracking({
    required String deliveryId,
    required String courierId,
    required VehicleType vehicleType,
    LatLng? initialPosition,
  }) async {
    await stopTracking();

    final hasPermission = await requestLocationPermission();

    // Em plataformas móveis com permissão concedida
    if (hasPermission && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final locationSettings = _buildLocationSettings();

        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          (Position pos) {
            final newPos = LatLng(pos.latitude, pos.longitude);
            final speedKmh = (pos.speed > 0 ? pos.speed * 3.6 : 0.0);

            if (_lastKnownPosition != null) {
              final rawBearing = GeoUtils.calculateBearing(_lastKnownPosition!, newPos);
              _currentBearing = GeoUtils.smoothBearing(
                oldBearing: _currentBearing,
                newBearing: rawBearing,
                speedKmh: speedKmh,
              );
            }
            _lastKnownPosition = newPos;

            final ping = DeliveryLocationPing(
              deliveryId: deliveryId,
              courierId: courierId,
              latitude: pos.latitude,
              longitude: pos.longitude,
              bearing: _currentBearing,
              speedKmh: speedKmh,
              accuracyMeters: pos.accuracy,
              timestamp: DateTime.now(),
              isMoving: speedKmh > 2.0,
              status: 'on_route',
              vehicleType: vehicleType,
            );

            if (!_pingController.isClosed) {
              _pingController.add(ping);
            }
          },
          onError: (error) {
            debugPrint('[BackgroundLocationService] Erro no stream GPS: $error');
          },
        );
        return;
      } catch (e) {
        debugPrint('[BackgroundLocationService] Falha ao iniciar GPS nativo: $e. Ativando simulador.');
      }
    }

    // Modo Simulador Inteligente (Web, Desktop ou sem permissão GPS real em emulador)
    _startSimulatedTracking(
      deliveryId: deliveryId,
      courierId: courierId,
      vehicleType: vehicleType,
      startPosition: initialPosition ?? const LatLng(-23.5505, -46.6333),
    );
  }

  /// Configurações nativas de localização com Foreground Service
  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 4),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "BoraGás Entregas: Compartilhando sua rota em tempo real",
          notificationTitle: "Entrega em Andamento 🛵💨",
          enableWakeLock: true,
          color: null,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
  }

  /// Gera deslocamento contínuo suave para demonstrações e testes em desktop/navegador
  void _startSimulatedTracking({
    required String deliveryId,
    required String courierId,
    required VehicleType vehicleType,
    required LatLng startPosition,
  }) {
    double currentLat = startPosition.latitude;
    double currentLng = startPosition.longitude;
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      // Pequeno deslocamento simulado em direção noroeste
      final deltaLat = 0.00035;
      final deltaLng = 0.00028;
      final prevPos = LatLng(currentLat, currentLng);
      currentLat += deltaLat;
      currentLng += deltaLng;
      final newPos = LatLng(currentLat, currentLng);

      _currentBearing = GeoUtils.calculateBearing(prevPos, newPos);

      final ping = DeliveryLocationPing(
        deliveryId: deliveryId,
        courierId: courierId,
        latitude: currentLat,
        longitude: currentLng,
        bearing: _currentBearing,
        speedKmh: 34.5,
        accuracyMeters: 4.2,
        timestamp: DateTime.now(),
        isMoving: true,
        status: 'on_route',
        vehicleType: vehicleType,
      );

      if (!_pingController.isClosed) {
        _pingController.add(ping);
      }
    });
  }

  /// Para a captura de GPS e limpa os recursos
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  void dispose() {
    stopTracking();
    _pingController.close();
  }
}
