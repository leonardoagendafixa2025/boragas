import 'package:latlong2/latlong.dart';

/// Tipos de veículos da frota BoraGás
enum VehicleType {
  motorcycleWithGasRack, // Moto com baú/gaiola lateral para botijões P13
  deliveryVan,           // Furgão para entregas a comércios e restaurantes
  pickupTruck;          // Caminhonete de apoio para alta demanda

  String get label {
    switch (this) {
      case VehicleType.motorcycleWithGasRack:
        return 'Moto BoraGás (P13)';
      case VehicleType.deliveryVan:
        return 'Furgão de Entrega';
      case VehicleType.pickupTruck:
        return 'Caminhonete BoraGás';
    }
  }

  static VehicleType fromString(String? val) {
    switch (val) {
      case 'deliveryVan':
        return VehicleType.deliveryVan;
      case 'pickupTruck':
        return VehicleType.pickupTruck;
      case 'motorcycleWithGasRack':
      default:
        return VehicleType.motorcycleWithGasRack;
    }
  }
}

/// Pacote de telemetria transmitido via Supabase Realtime Broadcast.
/// Otimizado para payloads leves (< 250 bytes) e alta taxa de atualização.
class DeliveryLocationPing {
  final String deliveryId;
  final String courierId;
  final double latitude;
  final double longitude;
  final double bearing;
  final double speedKmh;
  final double accuracyMeters;
  final DateTime timestamp;
  final double? batteryLevel;
  final bool isMoving;
  final String status;
  final int? etaMinutes;
  final double? remainingDistanceMeters;
  final VehicleType vehicleType;

  const DeliveryLocationPing({
    required this.deliveryId,
    required this.courierId,
    required this.latitude,
    required this.longitude,
    required this.bearing,
    required this.speedKmh,
    required this.accuracyMeters,
    required this.timestamp,
    this.batteryLevel,
    required this.isMoving,
    required this.status,
    this.etaMinutes,
    this.remainingDistanceMeters,
    this.vehicleType = VehicleType.motorcycleWithGasRack,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
    'delivery_id': deliveryId,
    'courier_id': courierId,
    'lat': latitude,
    'lng': longitude,
    'bearing': bearing,
    'speed_kmh': speedKmh,
    'acc_m': accuracyMeters,
    'ts': timestamp.millisecondsSinceEpoch,
    if (batteryLevel != null) 'bat': batteryLevel,
    'is_moving': isMoving,
    'status': status,
    if (etaMinutes != null) 'eta_min': etaMinutes,
    if (remainingDistanceMeters != null) 'rem_dist_m': remainingDistanceMeters,
    'veh': vehicleType.name,
  };

  factory DeliveryLocationPing.fromJson(Map<String, dynamic> json) {
    return DeliveryLocationPing(
      deliveryId: json['delivery_id']?.toString() ?? '',
      courierId: json['courier_id']?.toString() ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0.0,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      accuracyMeters: (json['acc_m'] as num?)?.toDouble() ?? 5.0,
      timestamp: json['ts'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['ts'] as int)
          : DateTime.now(),
      batteryLevel: (json['bat'] as num?)?.toDouble(),
      isMoving: json['is_moving'] as bool? ?? false,
      status: json['status']?.toString() ?? 'out_for_delivery',
      etaMinutes: (json['eta_min'] as num?)?.toInt(),
      remainingDistanceMeters: (json['rem_dist_m'] as num?)?.toDouble(),
      vehicleType: VehicleType.fromString(json['veh']?.toString()),
    );
  }

  DeliveryLocationPing copyWith({
    String? deliveryId,
    String? courierId,
    double? latitude,
    double? longitude,
    double? bearing,
    double? speedKmh,
    double? accuracyMeters,
    DateTime? timestamp,
    double? batteryLevel,
    bool? isMoving,
    String? status,
    int? etaMinutes,
    double? remainingDistanceMeters,
    VehicleType? vehicleType,
  }) {
    return DeliveryLocationPing(
      deliveryId: deliveryId ?? this.deliveryId,
      courierId: courierId ?? this.courierId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bearing: bearing ?? this.bearing,
      speedKmh: speedKmh ?? this.speedKmh,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      timestamp: timestamp ?? this.timestamp,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isMoving: isMoving ?? this.isMoving,
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      remainingDistanceMeters: remainingDistanceMeters ?? this.remainingDistanceMeters,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }
}

/// Informações de cálculo de rota rodoviária (OSRM / OpenStreetMap)
class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String etaText;
  final String distanceText;
  final String? summary;
  final bool isFallback;

  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.etaText,
    required this.distanceText,
    this.summary,
    this.isFallback = false,
  });

  int get etaMinutes => (durationSeconds / 60.0).ceil();

  static RouteInfo directFallback(LatLng origin, LatLng destination) {
    // Estimativa geodésica em linha reta com fator de sinuosidade urbana 1.35x e 30 km/h médio
    final directDist = const Distance().as(LengthUnit.Meter, origin, destination);
    final urbanDist = directDist * 1.35;
    final seconds = (urbanDist / (30.0 * 1000.0 / 3600.0));
    final mins = (seconds / 60.0).ceil();

    return RouteInfo(
      points: [origin, destination],
      distanceMeters: urbanDist,
      durationSeconds: seconds,
      etaText: '$mins min',
      distanceText: urbanDist < 1000
          ? '${urbanDist.round()} m'
          : '${(urbanDist / 1000.0).toStringAsFixed(1).replaceAll('.', ',')} km',
      summary: 'Estimativa geodésica urbana',
      isFallback: true,
    );
  }
}

/// Telemetria e métricas de consumo de Realtime para monitoramento de custos
class RealtimeMetrics {
  final int messagesSent;
  final int messagesReceived;
  final DateTime sessionStart;
  final double averageIntervalSeconds;

  const RealtimeMetrics({
    this.messagesSent = 0,
    this.messagesReceived = 0,
    required this.sessionStart,
    this.averageIntervalSeconds = 5.0,
  });

  RealtimeMetrics copyWith({
    int? messagesSent,
    int? messagesReceived,
    DateTime? sessionStart,
    double? averageIntervalSeconds,
  }) {
    return RealtimeMetrics(
      messagesSent: messagesSent ?? this.messagesSent,
      messagesReceived: messagesReceived ?? this.messagesReceived,
      sessionStart: sessionStart ?? this.sessionStart,
      averageIntervalSeconds: averageIntervalSeconds ?? this.averageIntervalSeconds,
    );
  }
}
