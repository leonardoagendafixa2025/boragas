import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tracking_models.dart';
import '../utils/geo_utils.dart';
import 'supabase_service.dart';

/// Interface para o serviço de rastreamento de entregas BoraGás
abstract class DeliveryTrackingService {
  /// Inicia publicação de localização para o entregador
  void startCourierBroadcast({
    required String deliveryId,
    required String courierId,
    required VehicleType vehicleType,
    required Stream<DeliveryLocationPing> locationStream,
  });

  /// Interrompe a transmissão e libera os canais
  Future<void> stopCourierBroadcast();

  /// Subscreve a atualizações em tempo real para o cliente ou painel
  Stream<DeliveryLocationPing> subscribeToDelivery(String deliveryId);

  /// Cancela a assinatura de uma entrega específica
  Future<void> unsubscribeFromDelivery(String deliveryId);

  /// Emite evento imediato de marco (ex: 'arrived', 'completed')
  Future<void> broadcastMilestone({
    required String deliveryId,
    required String courierId,
    required String milestone,
    required LatLng currentPos,
  });

  /// Métricas da sessão atual para monitoramento de economia e cotas
  RealtimeMetrics get metrics;
}

/// Implementação profissional do serviço com Supabase Realtime Broadcast e modo Mock/Offline resiliente
class SupabaseDeliveryTrackingService implements DeliveryTrackingService {
  RealtimeChannel? _courierChannel;
  StreamSubscription<DeliveryLocationPing>? _locationSubscription;
  DateTime? _lastTransmissionTime;
  DeliveryLocationPing? _lastTransmittedPing;
  DateTime? _lastDbSyncTime;

  // Canais de clientes assinantes
  final Map<String, RealtimeChannel> _activeClientChannels = {};
  final Map<String, StreamController<DeliveryLocationPing>> _clientControllers = {};

  // Métricas de custo e telemetria
  int _messagesSent = 0;
  int _messagesReceived = 0;
  DateTime _sessionStart = DateTime.now();

  @override
  RealtimeMetrics get metrics {
    final now = DateTime.now();
    final totalSec = now.difference(_sessionStart).inSeconds;
    final avgInterval = _messagesSent > 0 && totalSec > 0
        ? totalSec / _messagesSent
        : 5.0;

    return RealtimeMetrics(
      messagesSent: _messagesSent,
      messagesReceived: _messagesReceived,
      sessionStart: _sessionStart,
      averageIntervalSeconds: avgInterval,
    );
  }

  @override
  void startCourierBroadcast({
    required String deliveryId,
    required String courierId,
    required VehicleType vehicleType,
    required Stream<DeliveryLocationPing> locationStream,
  }) {
    _sessionStart = DateTime.now();
    _messagesSent = 0;

    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      final channelName = 'delivery:$deliveryId';
      _courierChannel = SupabaseService.client.channel(channelName);
      _courierChannel?.subscribe();
    }

    _locationSubscription?.cancel();
    _locationSubscription = locationStream.listen((ping) {
      _evaluateAndTransmit(ping);
    });
  }

  /// Avalia a política adaptativa de transmissão para economia de cotas
  void _evaluateAndTransmit(DeliveryLocationPing newPing) {
    final now = DateTime.now();

    if (_lastTransmittedPing == null) {
      _sendBroadcast(newPing);
      return;
    }

    final elapsed = _lastTransmissionTime != null
        ? now.difference(_lastTransmissionTime!).inMilliseconds
        : 999999;

    final lastPos = _lastTransmittedPing!.toLatLng();
    final newPos = newPing.toLatLng();
    final distanceMoved = GeoUtils.haversineDistanceMeters(lastPos, newPos);
    final bearingDiff = (newPing.bearing - _lastTransmittedPing!.bearing).abs();

    // 1. Entregador em movimento (> 4 km/h)
    if (newPing.speedKmh >= 4.0) {
      // Envia a cada 5 segundos ou se houve manobra/curva acentuada (> 30 graus e 15m)
      if (elapsed >= 5000 || (distanceMoved >= 15.0 && bearingDiff >= 30.0 && elapsed >= 2500)) {
        _sendBroadcast(newPing);
      }
    }
    // 2. Entregador em baixa velocidade (1 km/h - 4 km/h)
    else if (newPing.speedKmh >= 1.0) {
      if (elapsed >= 10000 || distanceMoved >= 20.0) {
        _sendBroadcast(newPing);
      }
    }
    // 3. Entregador parado (semáforo ou aguardando entrega)
    else {
      // Heartbeat a cada 30 segundos apenas para manter o cliente seguro de que a conexão segue viva
      if (elapsed >= 30000) {
        _sendBroadcast(newPing);
      }
    }
  }

  Future<void> _sendBroadcast(DeliveryLocationPing ping) async {
    _lastTransmissionTime = DateTime.now();
    _lastTransmittedPing = ping;
    _messagesSent++;

    // Transmite via Realtime Broadcast de baixa latência
    if (_courierChannel != null && SupabaseService.isInitialized) {
      try {
        await _courierChannel!.sendBroadcastMessage(
          event: 'location_update',
          payload: ping.toJson(),
        );
      } catch (e) {
        debugPrint('[DeliveryTrackingService] Erro ao enviar broadcast: $e');
      }
    }

    // Persistência controlada no PostgreSQL a cada 60s (evita inserção de alta frequência)
    final now = DateTime.now();
    if (_lastDbSyncTime == null || now.difference(_lastDbSyncTime!).inSeconds >= 60) {
      _lastDbSyncTime = now;
      _persistLastKnownPosition(ping);
    }
  }

  Future<void> _persistLastKnownPosition(DeliveryLocationPing ping) async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) return;
    try {
      await SupabaseService.client.rpc('rpc_update_courier_position', params: {
        'p_delivery_id': ping.deliveryId,
        'p_courier_id': ping.courierId,
        'p_latitude': ping.latitude,
        'p_longitude': ping.longitude,
        'p_bearing': ping.bearing,
        'p_speed_kmh': ping.speedKmh,
        'p_status': ping.status,
      });
    } catch (e) {
      debugPrint('[DeliveryTrackingService] RPC update position erro: $e');
    }
  }

  @override
  Future<void> broadcastMilestone({
    required String deliveryId,
    required String courierId,
    required String milestone,
    required LatLng currentPos,
  }) async {
    final milestonePing = DeliveryLocationPing(
      deliveryId: deliveryId,
      courierId: courierId,
      latitude: currentPos.latitude,
      longitude: currentPos.longitude,
      bearing: _lastTransmittedPing?.bearing ?? 0.0,
      speedKmh: 0.0,
      accuracyMeters: 5.0,
      timestamp: DateTime.now(),
      isMoving: false,
      status: milestone,
    );

    // Envio imediato do evento de marco
    await _sendBroadcast(milestonePing);
    await _persistLastKnownPosition(milestonePing);
  }

  @override
  Future<void> stopCourierBroadcast() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    if (_courierChannel != null && SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.removeChannel(_courierChannel!);
      } catch (e) {
        debugPrint('[DeliveryTrackingService] Erro ao remover canal: $e');
      }
      _courierChannel = null;
    }
    _lastTransmittedPing = null;
    _lastTransmissionTime = null;
  }

  @override
  Stream<DeliveryLocationPing> subscribeToDelivery(String deliveryId) {
    if (_clientControllers.containsKey(deliveryId)) {
      return _clientControllers[deliveryId]!.stream;
    }

    final controller = StreamController<DeliveryLocationPing>.broadcast();
    _clientControllers[deliveryId] = controller;

    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      final channelName = 'delivery:$deliveryId';
      final channel = SupabaseService.client.channel(channelName);

      channel.onBroadcast(event: 'location_update', callback: (payload) {
        _messagesReceived++;
        try {
          final ping = DeliveryLocationPing.fromJson(payload);
          if (!controller.isClosed) {
            controller.add(ping);
          }
        } catch (e) {
          debugPrint('[DeliveryTrackingService] Erro ao decodificar ping recebido: $e');
        }
      }).subscribe();

      _activeClientChannels[deliveryId] = channel;
    }

    return controller.stream;
  }

  @override
  Future<void> unsubscribeFromDelivery(String deliveryId) async {
    final channel = _activeClientChannels.remove(deliveryId);
    if (channel != null && SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.removeChannel(channel);
      } catch (e) {
        debugPrint('[DeliveryTrackingService] Erro ao cancelar canal do cliente: $e');
      }
    }

    final controller = _clientControllers.remove(deliveryId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }
}
