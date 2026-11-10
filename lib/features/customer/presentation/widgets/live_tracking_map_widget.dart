import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/tracking_models.dart';
import '../../../../core/providers/tracking_providers.dart';
import '../../../../core/widgets/map/boragas_interactive_map.dart';

/// Widget de mapa para a tela do cliente, conectado ao Supabase Realtime Broadcast,
/// com suporte a detecção do GPS real do dispositivo (PC/Mobile) e cálculo de rota OSRM.
class LiveTrackingMapWidget extends ConsumerStatefulWidget {
  final String orderId;
  final String courierName;
  final String storeName;
  final String destinationAddress;
  final LatLng destinationCoords;
  final LatLng initialCourierCoords;

  const LiveTrackingMapWidget({
    super.key,
    this.orderId = 'ord-101',
    required this.courierName,
    required this.storeName,
    required this.destinationAddress,
    this.destinationCoords = const LatLng(-23.5614, -46.6558), // Av. Paulista (Default/Fallback)
    this.initialCourierCoords = const LatLng(-23.5535, -46.6412), // Bela Vista (Default/Fallback)
  });

  @override
  ConsumerState<LiveTrackingMapWidget> createState() => _LiveTrackingMapWidgetState();
}

class _LiveTrackingMapWidgetState extends ConsumerState<LiveTrackingMapWidget> {
  RouteInfo? _calculatedRoute;
  bool _isLoadingRoute = true;
  bool _isDetectingGps = false;
  bool _isUsingRealGps = false;

  late LatLng _currentDestination;
  late LatLng _currentCourier;

  @override
  void initState() {
    super.initState();
    _currentDestination = widget.destinationCoords;
    _currentCourier = widget.initialCourierCoords;

    _fetchRoadRoute();
    // Tenta detectar a localização real do dispositivo/navegador automaticamente
    _tryDetectRealLocation();
  }

  Future<void> _fetchRoadRoute() async {
    setState(() => _isLoadingRoute = true);
    try {
      final routing = ref.read(routingServiceProvider);
      final route = await routing.calculateRoute(
        origin: _currentCourier,
        destination: _currentDestination,
      );
      if (mounted) {
        setState(() {
          _calculatedRoute = route;
          _isLoadingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _calculatedRoute = RouteInfo.directFallback(
            _currentCourier,
            _currentDestination,
          );
          _isLoadingRoute = false;
        });
      }
    }
  }

  /// Detecta o GPS real do usuário (Navegador Chrome/PC ou Celular)
  Future<void> _tryDetectRealLocation() async {
    if (_isDetectingGps) return;
    setState(() => _isDetectingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isDetectingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isDetectingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isDetectingGps = false);
        return;
      }

      // Obtém coordenadas reais do dispositivo
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final realDest = LatLng(pos.latitude, pos.longitude);
      // Posiciona a moto do entregador a ~1.2 km de distância na mesma cidade
      final realCourier = LatLng(pos.latitude - 0.0095, pos.longitude - 0.0075);

      if (!mounted) return;

      setState(() {
        _currentDestination = realDest;
        _currentCourier = realCourier;
        _isUsingRealGps = true;
        _isDetectingGps = false;
      });

      // Recalcula trajeto rodoviário real OSRM no local físico do usuário
      await _fetchRoadRoute();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '📍 Localização real do seu dispositivo detectada!\nTraçando rota no seu bairro.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('[LiveTrackingMapWidget] Localização real indisponível: $e');
      if (mounted) {
        setState(() => _isDetectingGps = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stream de localização em tempo real para este pedido
    final trackingService = ref.watch(deliveryTrackingServiceProvider);
    final locationStream = trackingService.subscribeToDelivery(widget.orderId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de status de localização (GPS Real vs Simulação Padrão)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isUsingRealGps ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isUsingRealGps ? Icons.gps_fixed_rounded : Icons.location_city_rounded,
                      size: 15,
                      color: _isUsingRealGps ? const Color(0xFF059669) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isUsingRealGps
                          ? 'Localização Real do seu Dispositivo (GPS)'
                          : 'Localização Demonstrativa (São Paulo)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isUsingRealGps ? const Color(0xFF065F46) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _isDetectingGps ? null : _tryDetectRealLocation,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isDetectingGps)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _isUsingRealGps ? Icons.refresh_rounded : Icons.my_location_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          _isDetectingGps
                              ? 'Detectando...'
                              : (_isUsingRealGps ? 'Atualizar' : 'Pegar meu GPS'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mapa Interativo
          SizedBox(
            height: 260,
            child: _isLoadingRoute
                ? Container(
                    height: 260,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text(
                            'Traçando melhor rota rodoviária (OSRM)...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : BoraGasInteractiveMap(
                    key: ValueKey('${_currentDestination.latitude}_${_currentDestination.longitude}'),
                    height: 260,
                    destination: _currentDestination,
                    initialCourierPosition: _currentCourier,
                    initialRoute: _calculatedRoute,
                    locationStream: locationStream,
                    courierName: widget.courierName,
                  ),
          ),

          // Informações de status e rota abaixo do mapa
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.courierName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isUsingRealGps
                            ? 'Destino: Sua localização atual (GPS)'
                            : 'Em rota para: ${widget.destinationAddress}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_calculatedRoute != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _calculatedRoute!.etaText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          _calculatedRoute!.distanceText,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
