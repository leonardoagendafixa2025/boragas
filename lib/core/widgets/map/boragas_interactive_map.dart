import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_colors.dart';
import '../../models/tracking_models.dart';
import '../../utils/geo_utils.dart';
import 'boragas_vehicle_marker.dart';

/// Mapa interativo BoraGás com interpolação contínua de movimento,
/// trajeto rodoviário OSRM e visualização premium semelhante ao iFood.
class BoraGasInteractiveMap extends StatefulWidget {
  final LatLng destination;
  final LatLng initialCourierPosition;
  final Stream<DeliveryLocationPing>? locationStream;
  final RouteInfo? initialRoute;
  final String? courierName;
  final String? courierVehiclePlate;
  final VoidCallback? onRecenterPressed;
  final bool showControls;
  final double height;

  const BoraGasInteractiveMap({
    super.key,
    required this.destination,
    required this.initialCourierPosition,
    this.locationStream,
    this.initialRoute,
    this.courierName,
    this.courierVehiclePlate,
    this.onRecenterPressed,
    this.showControls = true,
    this.height = 360,
  });

  @override
  State<BoraGasInteractiveMap> createState() => _BoraGasInteractiveMapState();
}

class _BoraGasInteractiveMapState extends State<BoraGasInteractiveMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late AnimationController _animationController;

  StreamSubscription<DeliveryLocationPing>? _streamSub;

  // Posições para interpolação suave
  late LatLng _startPosition;
  late LatLng _targetPosition;
  late LatLng _displayPosition;

  double _startBearing = 0.0;
  double _targetBearing = 0.0;
  double _displayBearing = 0.0;

  double _currentSpeed = 28.0;
  bool _isMoving = true;
  DateTime _lastPingTime = DateTime.now();
  Timer? _secondsTicker;
  int _secondsSinceLastPing = 0;

  List<LatLng> _routePoints = [];
  String _etaText = 'Calculando...';
  String _distanceText = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _startPosition = widget.initialCourierPosition;
    _targetPosition = widget.initialCourierPosition;
    _displayPosition = widget.initialCourierPosition;

    if (widget.initialRoute != null) {
      _routePoints = widget.initialRoute!.points;
      _etaText = widget.initialRoute!.etaText;
      _distanceText = widget.initialRoute!.distanceText;
    }

    // Inicializa animação de interpolação
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addListener(() {
        if (!mounted) return;
        setState(() {
          _displayPosition = GeoUtils.interpolatePosition(
            _startPosition,
            _targetPosition,
            _animationController.value,
          );

          // Suaviza a rotação do veículo
          final diff = (_targetBearing - _startBearing) % 360.0;
          final shortestDiff = diff > 180.0 ? diff - 360.0 : (diff < -180.0 ? diff + 360.0 : diff);
          _displayBearing = (_startBearing + shortestDiff * _animationController.value) % 360.0;
        });
      });

    _listenToLocationStream();

    // Ticker a cada 1 segundo para atualizar o indicador de "há Xs"
    _secondsTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _secondsSinceLastPing = DateTime.now().difference(_lastPingTime).inSeconds;
        });
      }
    });
  }

  void _listenToLocationStream() {
    if (widget.locationStream == null) return;

    _streamSub = widget.locationStream!.listen((ping) {
      if (!mounted) return;

      _lastPingTime = DateTime.now();
      _secondsSinceLastPing = 0;

      // Configura pontos de início e destino para interpolação
      _startPosition = _displayPosition;
      _targetPosition = ping.toLatLng();

      _startBearing = _displayBearing;
      _targetBearing = ping.bearing;

      _currentSpeed = ping.speedKmh;
      _isMoving = ping.isMoving;

      if (ping.etaMinutes != null) {
        _etaText = '${ping.etaMinutes} min';
      }
      if (ping.remainingDistanceMeters != null) {
        _distanceText = GeoUtils.formatDistance(ping.remainingDistanceMeters!);
      }

      // Dispara a animação fluída
      _animationController.forward(from: 0.0);
    });
  }

  @override
  void didUpdateWidget(covariant BoraGasInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationStream != widget.locationStream) {
      _streamSub?.cancel();
      _listenToLocationStream();
    }
    if (oldWidget.initialRoute != widget.initialRoute && widget.initialRoute != null) {
      setState(() {
        _routePoints = widget.initialRoute!.points;
        _etaText = widget.initialRoute!.etaText;
        _distanceText = widget.initialRoute!.distanceText;
      });
    }
  }

  void _recenterOnCourier() {
    _mapController.move(_displayPosition, 16.0);
  }

  void _fitRouteBounds() {
    final bounds = LatLngBounds.fromPoints([_displayPosition, widget.destination]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      ),
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _secondsTicker?.cancel();
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // 1. Mapa Base OpenStreetMap via CartoDB Tiles (Rápido, vetorial/raster limpo e sem custo de licença)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _displayPosition,
                initialZoom: 15.5,
                minZoom: 6.0,
                maxZoom: 18.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.boragas.app',
                  tileProvider: NetworkTileProvider(),
                ),

                // Trajeto desenhado (Polyline OSRM com visual BoraGás Laranja)
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // Sombra do trajeto
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 7.0,
                        color: Colors.black.withValues(alpha: 0.15),
                      ),
                      // Linha principal do trajeto BoraGás
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.5,
                        color: AppColors.primary,
                        borderColor: Colors.white.withValues(alpha: 0.4),
                        borderStrokeWidth: 1.0,
                      ),
                    ],
                  ),

                // Camada de Marcadores (Destino e Motocicleta em movimento)
                MarkerLayer(
                  markers: [
                    // Marcador do Cliente (Destino final)
                    Marker(
                      point: widget.destination,
                      width: 52,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: _buildDestinationMarker(),
                    ),

                    // Marcador Animado da Moto BoraGás
                    Marker(
                      point: _displayPosition,
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      child: BoraGasVehicleMarker(
                        bearing: _displayBearing,
                        speedKmh: _currentSpeed,
                        isMoving: _isMoving,
                        size: 56,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Chip superior de status da conexão e GPS
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _secondsSinceLastPing <= 15
                          ? const Color(0xFF10B981) // Verde online
                          : const Color(0xFFF59E0B), // Âmbar aguardando
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _secondsSinceLastPing <= 15
                        ? 'Ao vivo • GPS há ${_secondsSinceLastPing}s'
                        : 'Sinal instável • ${_secondsSinceLastPing}s',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Pílula flutuante de Previsão de Chegada (ETA)
          if (_etaText.isNotEmpty && _etaText != 'Calculando...')
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.primary, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      _etaText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (_distanceText.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        '($_distanceText)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // 4. Botões de controle lateral (Centralizar no entregador e Ajustar rota)
          if (widget.showControls)
            Positioned(
              right: 14,
              bottom: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFloatingButton(
                    icon: Icons.alt_route_rounded,
                    tooltip: 'Ver rota completa',
                    onTap: _fitRouteBounds,
                  ),
                  const SizedBox(height: 8),
                  _buildFloatingButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Centralizar no entregador',
                    color: AppColors.primary,
                    iconColor: Colors.white,
                    onTap: widget.onRecenterPressed ?? _recenterOnCourier,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        Container(
          width: 3,
          height: 6,
          color: const Color(0xFF0F172A),
        ),
      ],
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = const Color(0xFF1E293B),
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}
