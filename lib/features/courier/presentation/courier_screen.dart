import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/tracking_models.dart';
import '../../../core/providers/tracking_providers.dart';
import '../../../core/services/external_navigation_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/map/boragas_interactive_map.dart';
import '../../../core/widgets/slide_to_action.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/customer_providers.dart';

class CourierScreen extends ConsumerStatefulWidget {
  const CourierScreen({super.key});

  @override
  ConsumerState<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends ConsumerState<CourierScreen> {
  // Coordenadas para entrega ativa (com suporte a detecção de GPS real)
  LatLng _destinationCoords = const LatLng(-23.5614, -46.6558);
  LatLng _courierStartCoords = const LatLng(-23.5535, -46.6412);
  RouteInfo? _activeRoute;
  bool _isUsingRealGps = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).switchDemoRole(UserRole.courier);
    });
    _initRouteAndTracking();
    _tryDetectRealLocation();
  }

  Future<void> _tryDetectRealLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final realCourier = LatLng(pos.latitude, pos.longitude);
      final realDest = LatLng(pos.latitude + 0.0095, pos.longitude + 0.0075);

      if (mounted) {
        setState(() {
          _courierStartCoords = realCourier;
          _destinationCoords = realDest;
          _isUsingRealGps = true;
        });

        final routing = ref.read(routingServiceProvider);
        final route = await routing.calculateRoute(
          origin: _courierStartCoords,
          destination: _destinationCoords,
        );
        if (mounted) {
          setState(() => _activeRoute = route);
        }
      }
    } catch (_) {}
  }

  Future<void> _initRouteAndTracking() async {
    final routing = ref.read(routingServiceProvider);
    try {
      final route = await routing.calculateRoute(
        origin: _courierStartCoords,
        destination: _destinationCoords,
      );
      if (mounted) {
        setState(() => _activeRoute = route);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _activeRoute = RouteInfo.directFallback(_courierStartCoords, _destinationCoords);
        });
      }
    }

    // Auto-inicia transmissão se houver pedido em rota
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final orders = ref.read(ordersProvider);
      final activeOrder = orders.where((o) => o.status == OrderStatus.outForDelivery).firstOrNull;
      if (activeOrder != null) {
        final trackingState = ref.read(courierTrackingNotifierProvider);
        if (!trackingState.isTrackingActive) {
          ref.read(courierTrackingNotifierProvider.notifier).startTrackingForDelivery(
                deliveryId: activeOrder.id,
                courierId: 'courier-marcos-01',
                vehicleType: VehicleType.motorcycleWithGasRack,
                initialPos: _courierStartCoords,
              );
        }
      }
    });
  }

  void _openPinValidationDialog(OrderModel order) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pin_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text('Validar PIN do Cliente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solicite o código de 4 dígitos na tela do cliente para confirmar a entrega de ${order.orderNumber}:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            SlideToActionWidget(
              height: 46,
              label: 'Deslize p/ Validar',
              icon: Icons.check_rounded,
              activeTrackColor: AppColors.success,
              onCompleted: () async {
                final enteredPin = pinController.text.trim();
                if (enteredPin == order.deliveryConfirmationCode) {
                  final updated = order.copyWith(
                    status: OrderStatus.delivered,
                    deliveredAt: DateTime.now(),
                  );

                  ref.read(ordersProvider.notifier).update(
                        (list) => list.map((o) => o.id == order.id ? updated : o).toList(),
                      );

                  // Interrompe transmissão GPS automaticamente após finalização
                  await ref.read(courierTrackingNotifierProvider.notifier).stopTracking();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ PIN validado! Entrega concluída e GPS encerrado com sucesso.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ PIN incorreto! O código correto de teste é "${order.deliveryConfirmationCode}".'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _notifyCustomerArrival(OrderModel order) {
    ref.read(courierTrackingNotifierProvider.notifier).notifyArrival(
          deliveryId: order.id,
          courierId: 'courier-marcos-01',
          position: _destinationCoords,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Cliente notificado: "O entregador chegou na sua porta!" 🔔')),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final trackingState = ref.watch(courierTrackingNotifierProvider);

    final activeDelivery = orders
        .where((o) => o.status == OrderStatus.outForDelivery)
        .firstOrNull;

    final queuedDeliveries = orders
        .where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.accepted)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.two_wheeler_rounded, color: AppColors.accentFlame),
            SizedBox(width: 8),
            Text('BoraGás Entregador', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair da Conta',
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text('App Cliente', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Profile & Telemetry Card
            _buildProfileAndTelemetryCard(trackingState),

            const SizedBox(height: 20),

            // ENTREGA ATIVA EM TEMPO REAL (HERO SECTION)
            if (activeDelivery != null) ...[
              _buildActiveDeliveryHeroSection(activeDelivery, trackingState),
              const SizedBox(height: 24),
            ],

            // OUTRAS ENTREGAS AGUARDANDO DESPACHO
            Text(
              'FILA DE PEDIDOS (${queuedDeliveries.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            if (queuedDeliveries.isEmpty && activeDelivery == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
                      SizedBox(height: 10),
                      Text('Tudo entregue com sucesso!', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('Aguardando novos despachos da distribuidora...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              ...queuedDeliveries.map((order) => _buildQueuedOrderCard(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAndTelemetryCard(CourierTrackingState trackingState) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marcos Oliveira',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        'Honda Fan 160 • Placa BRA-2024',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              // Badge de Transmissão GPS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: trackingState.isTrackingActive ? const Color(0xFF10B981) : AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trackingState.isTrackingActive ? Icons.wifi_tethering_rounded : Icons.check_circle_outline,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trackingState.isTrackingActive
                          ? (_isUsingRealGps ? 'ONLINE • GPS REAL' : 'ONLINE • GPS ATIVO')
                          : 'ONLINE',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),

          // Métricas de Realtime e Telemetria
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transmissões Realtime', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    '${trackingState.metrics.messagesSent} pings',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Intervalo Adaptativo', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    '~${trackingState.metrics.averageIntervalSeconds.toStringAsFixed(1)}s',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Ganhos Hoje (Taxas)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('R\$ 148,00', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryHeroSection(OrderModel order, CourierTrackingState trackingState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da entrega ativa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, color: AppColors.accentFlame, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ENTREGA ATIVA • ${order.orderNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
                StatusBadge.fromOrderStatus(order.status),
              ],
            ),
          ),

          // Mapa Interativo do Entregador com trajeto e visualizador
          SizedBox(
            height: 230,
            child: BoraGasInteractiveMap(
              height: 230,
              destination: _destinationCoords,
              initialCourierPosition: _courierStartCoords,
              initialRoute: _activeRoute,
              courierName: 'Sua Moto (Honda 160)',
            ),
          ),

          // Informações do Destino e do Cliente
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Endereço de Entrega:',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                          ),
                          Text(
                            order.deliveryAddress,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Cliente: ${order.customerName} • ${order.customerPhone}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),

                const SizedBox(height: 14),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),

                // BOTÕES DE NAVEGAÇÃO EXTERNA (WAZE & GOOGLE MAPS)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00B0FF),
                          side: const BorderSide(color: Color(0xFF00B0FF), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ExternalNavigationService.openWaze(
                            latitude: _destinationCoords.latitude,
                            longitude: _destinationCoords.longitude,
                          );
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 18),
                        label: const Text('Abrir Waze', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF34A853),
                          side: const BorderSide(color: Color(0xFF34A853), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ExternalNavigationService.openGoogleMaps(
                            latitude: _destinationCoords.latitude,
                            longitude: _destinationCoords.longitude,
                          );
                        },
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // BOTÕES DE AÇÃO: AVISO DE CHEGADA E FINALIZAÇÃO DE ENTREGA (PIN)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _notifyCustomerArrival(order),
                        icon: const Icon(Icons.doorbell_rounded, size: 18),
                        label: const Text('Cheguei no Local', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Validar PIN',
                        height: 48,
                        isFlameAccent: true,
                        icon: Icons.lock_open_rounded,
                        onPressed: () => _openPinValidationDialog(order),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuedOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                StatusBadge.fromOrderStatus(order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Loja: ${order.storeName}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Endereço: ${order.deliveryAddress}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final updated = order.copyWith(status: OrderStatus.outForDelivery);
                      ref.read(ordersProvider.notifier).update(
                            (list) => list.map((o) => o.id == order.id ? updated : o).toList(),
                          );
                      ref.read(courierTrackingNotifierProvider.notifier).startTrackingForDelivery(
                            deliveryId: order.id,
                            courierId: 'courier-marcos-01',
                            vehicleType: VehicleType.motorcycleWithGasRack,
                            initialPos: _courierStartCoords,
                          );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Iniciar Entrega'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
