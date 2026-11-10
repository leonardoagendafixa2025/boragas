import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/tracking_models.dart';
import '../services/background_location_service.dart';
import '../services/delivery_tracking_service.dart';
import '../services/routing_service.dart';

/// Provider singleton para cálculo de rotas rodoviárias OSRM
final routingServiceProvider = Provider<RoutingService>((ref) {
  return OsrmRoutingService();
});

/// Provider singleton para o serviço de mensageria de rastreamento Supabase
final deliveryTrackingServiceProvider = Provider<DeliveryTrackingService>((ref) {
  return SupabaseDeliveryTrackingService();
});

/// Provider para o serviço de localização em primeiro e segundo plano
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  final service = BackgroundLocationService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Stream de localização em tempo real para um pedido específico (para a tela do cliente)
final deliveryLocationStreamProvider =
    StreamProvider.autoDispose.family<DeliveryLocationPing, String>((ref, deliveryId) {
  final service = ref.watch(deliveryTrackingServiceProvider);
  final stream = service.subscribeToDelivery(deliveryId);

  ref.onDispose(() {
    service.unsubscribeFromDelivery(deliveryId);
  });

  return stream;
});

/// Estado da sessão de rastreamento do entregador
class CourierTrackingState {
  final bool isTrackingActive;
  final String? activeDeliveryId;
  final DeliveryLocationPing? lastPing;
  final RealtimeMetrics metrics;

  const CourierTrackingState({
    this.isTrackingActive = false,
    this.activeDeliveryId,
    this.lastPing,
    required this.metrics,
  });

  CourierTrackingState copyWith({
    bool? isTrackingActive,
    String? activeDeliveryId,
    DeliveryLocationPing? lastPing,
    RealtimeMetrics? metrics,
  }) {
    return CourierTrackingState(
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      activeDeliveryId: activeDeliveryId ?? this.activeDeliveryId,
      lastPing: lastPing ?? this.lastPing,
      metrics: metrics ?? this.metrics,
    );
  }
}

class CourierTrackingNotifier extends Notifier<CourierTrackingState> {
  @override
  CourierTrackingState build() {
    final trackingService = ref.watch(deliveryTrackingServiceProvider);
    return CourierTrackingState(
      metrics: trackingService.metrics,
    );
  }

  Future<void> startTrackingForDelivery({
    required String deliveryId,
    required String courierId,
    VehicleType vehicleType = VehicleType.motorcycleWithGasRack,
    LatLng? initialPos,
  }) async {
    final locationService = ref.read(backgroundLocationServiceProvider);
    final trackingService = ref.read(deliveryTrackingServiceProvider);

    // Inicia captura GPS (foreground service no Android / CoreLocation no iOS / simulador)
    await locationService.startTracking(
      deliveryId: deliveryId,
      courierId: courierId,
      vehicleType: vehicleType,
      initialPosition: initialPos,
    );

    // Conecta o stream do GPS ao canal Supabase Broadcast
    trackingService.startCourierBroadcast(
      deliveryId: deliveryId,
      courierId: courierId,
      vehicleType: vehicleType,
      locationStream: locationService.pingStream,
    );

    state = state.copyWith(
      isTrackingActive: true,
      activeDeliveryId: deliveryId,
      metrics: trackingService.metrics,
    );
  }

  Future<void> stopTracking() async {
    final locationService = ref.read(backgroundLocationServiceProvider);
    final trackingService = ref.read(deliveryTrackingServiceProvider);

    await locationService.stopTracking();
    await trackingService.stopCourierBroadcast();

    state = state.copyWith(
      isTrackingActive: false,
      activeDeliveryId: null,
      metrics: trackingService.metrics,
    );
  }

  Future<void> notifyArrival({
    required String deliveryId,
    required String courierId,
    required LatLng position,
  }) async {
    final trackingService = ref.read(deliveryTrackingServiceProvider);
    await trackingService.broadcastMilestone(
      deliveryId: deliveryId,
      courierId: courierId,
      milestone: 'arrived',
      currentPos: position,
    );
  }
}

final courierTrackingNotifierProvider =
    NotifierProvider<CourierTrackingNotifier, CourierTrackingState>(
  CourierTrackingNotifier.new,
);
