import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/tracking_models.dart';
import '../../../core/providers/tracking_providers.dart';
import '../../../core/services/external_navigation_service.dart';
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

  Future<void> _callCustomer(String phone) async {
    try {
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      final uri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _whatsappCustomer(String phone) async {
    try {
      String clean = phone.replaceAll(RegExp(r'\D'), '');
      if (!clean.startsWith('55')) clean = '55$clean';
      final uri = Uri.parse('https://wa.me/$clean?text=Ol%C3%A1!%20Sou%20o%20entregador%20do%20BoraG%C3%A1s%20com%20o%20seu%20pedido.');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _openPinValidationDialog(OrderModel order) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pin_rounded, color: Color(0xFFFF6B00), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Validar PIN do Cliente',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solicite o código de 4 dígitos na tela do cliente para confirmar a entrega de ${order.orderNumber}:',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 10, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                hintText: '••••',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SlideToActionWidget(
              height: 48,
              label: 'Deslize p/ Validar Entrega',
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
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(child: Text('✅ PIN validado! Entrega concluída e GPS encerrado com sucesso.')),
                          ],
                        ),
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
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
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
            Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Cliente notificado: "O entregador chegou na sua porta!" 🔔')),
          ],
        ),
        backgroundColor: Color(0xFF0F172A),
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFFFF6B00), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BoraGás Entregador',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Painel de Despacho & Rotas',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
              context.go('/home');
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 14),
            label: const Text('App Cliente', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Sair da Conta',
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Profile & Telemetry Card (Design Moderno com Grid Perfeita)
              _buildProfileAndTelemetryCard(trackingState),

              const SizedBox(height: 20),

              // ENTREGA ATIVA EM TEMPO REAL (HERO SECTION)
              if (activeDelivery != null) ...[
                _buildActiveDeliveryHeroSection(activeDelivery, trackingState),
                const SizedBox(height: 24),
              ],

              // OUTRAS ENTREGAS AGUARDANDO DESPACHO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FILA DE PEDIDOS (${queuedDeliveries.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                      letterSpacing: 0.6,
                    ),
                  ),
                  if (queuedDeliveries.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${queuedDeliveries.length} pendentes',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (queuedDeliveries.isEmpty && activeDelivery == null)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Tudo entregue com sucesso!',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Aguardando novos despachos da distribuidora...',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...queuedDeliveries.map((order) => _buildQueuedOrderCard(order)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAndTelemetryCard(CourierTrackingState trackingState) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Nome + Veículo + Status
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marcos Oliveira',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.two_wheeler, color: Colors.white70, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Honda Fan 160 • Placa BRA-2024',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge Status Online
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      trackingState.isTrackingActive
                          ? (_isUsingRealGps ? 'GPS REAL' : 'GPS ATIVO')
                          : 'ONLINE',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // 3 Cards de Métricas com Expanded e Grid Perfeita (Sem sobreposição)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Transmissões',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trackingState.metrics.messagesSent} pings',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Intervalo',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '~${trackingState.metrics.averageIntervalSeconds.toStringAsFixed(1)}s',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Ganhos Hoje (Taxas)',
                        style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'R\$ 148,00',
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFF6B00), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, color: Color(0xFFFF6B00), size: 18),
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
          ClipRRect(
            child: SizedBox(
              height: 230,
              child: BoraGasInteractiveMap(
                height: 230,
                destination: _destinationCoords,
                initialCourierPosition: _courierStartCoords,
                initialRoute: _activeRoute,
                courierName: 'Sua Moto (Honda 160)',
              ),
            ),
          ),

          // Informações do Destino e do Cliente
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Endereço
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.place_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ENDEREÇO DE ENTREGA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.deliveryAddress,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Card de Contato do Cliente (Com Botões Diretos de WhatsApp e Chamada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline, size: 18, color: Color(0xFF334155)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              order.customerPhone,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      // Botão WhatsApp
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        tooltip: 'WhatsApp do Cliente',
                        onPressed: () => _whatsappCustomer(order.customerPhone),
                      ),
                      const SizedBox(width: 6),
                      // Botão Ligar
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.15),
                          foregroundColor: const Color(0xFF007AFF),
                          padding: const EdgeInsets.all(8),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        tooltip: 'Ligar para o Cliente',
                        onPressed: () => _callCustomer(order.customerPhone),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // NAVEGAÇÃO GPS EXTERNA (WAZE & GOOGLE MAPS)
                const Text(
                  'NAVEGAÇÃO GPS EXTERNA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D2FF).withValues(alpha: 0.12),
                          foregroundColor: const Color(0xFF0284C7),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ExternalNavigationService.openWaze(
                            latitude: _destinationCoords.latitude,
                            longitude: _destinationCoords.longitude,
                          );
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 18, color: Color(0xFF0284C7)),
                        label: const Text('Abrir Waze', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34A853).withValues(alpha: 0.12),
                          foregroundColor: const Color(0xFF166534),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFF4ADE80), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ExternalNavigationService.openGoogleMaps(
                            latitude: _destinationCoords.latitude,
                            longitude: _destinationCoords.longitude,
                          );
                        },
                        icon: const Icon(Icons.map_rounded, size: 18, color: Color(0xFF166534)),
                        label: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // AÇÕES DA ENTREGA: AVISO DE CHEGADA E VALIDAR PIN
                const Text(
                  'AÇÕES DA ENTREGA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _notifyCustomerArrival(order),
                        icon: const Icon(Icons.doorbell_rounded, size: 18, color: Color(0xFFFF6B00)),
                        label: const Text('Cheguei no Local', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _openPinValidationDialog(order),
                        icon: const Icon(Icons.lock_open_rounded, size: 20),
                        label: const Text('VALIDAR PIN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.orderNumber,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.storeName,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                StatusBadge.fromOrderStatus(order.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
              icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Color(0xFFFF6B00)),
              label: const Text('Iniciar Esta Entrega', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
