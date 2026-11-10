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

class _CourierScreenState extends ConsumerState<CourierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Coordenadas para entrega ativa (com suporte a detecção de GPS real)
  LatLng _destinationCoords = const LatLng(-23.5614, -46.6558);
  LatLng _courierStartCoords = const LatLng(-23.5535, -46.6412);
  RouteInfo? _activeRoute;
  bool _isUsingRealGps = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).switchDemoRole(UserRole.courier);
    });
    _initRouteAndTracking();
    _tryDetectRealLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      final uri = Uri.parse(
        'https://wa.me/$clean?text=Ol%C3%A1!%20Sou%20o%20entregador%20do%20BoraG%C3%A1s%20com%20o%20seu%20botij%C3%A3o.',
      );
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
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 10,
                color: Color(0xFF0F172A),
              ),
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
      backgroundColor: const Color(0xFF0B0F19),
      appBar: _buildTacticalAppBar(trackingState),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Perfil e Cockpit do Entregador
            _buildDriverProfileBar(trackingState),

            // Cockpit Mode Switcher (Abas de Alta Velocidade)
            _buildTacticalTabBar(activeDelivery != null, queuedDeliveries.length),

            // Conteúdo da Aba Selecionada
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Evita scroll acidental na moto
                children: [
                  // ABA 1: COCKPIT DA ENTREGA ATIVA (MAPA EXPANSIVO + PAINEL DE MISSÃO)
                  _buildActiveDeliveryTab(activeDelivery, trackingState),

                  // ABA 2: FILA DE PEDIDOS AGUARDANDO DESPACHO
                  _buildQueuedOrdersTab(queuedDeliveries),

                  // ABA 3: PERFIL, GANHOS E TELEMETRIA
                  _buildDriverWalletTab(trackingState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de Perfil e Cockpit do Condutor (Ergonômica, Compacta e Visual Tático)
  Widget _buildDriverProfileBar(CourierTrackingState trackingState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E3D56)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // Nome e Moto
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Marcos Oliveira',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.two_wheeler_rounded, color: Color(0xFF94A3B8), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Honda Fan 160 • Placa BRA-2024',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ONLINE Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Ganhos Hoje (Taxas)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ganhos Hoje (Taxas)',
                  style: TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'R\$ 148,00',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar Tático com Status Online e Ganhos Visíveis
  PreferredSizeWidget _buildTacticalAppBar(CourierTrackingState trackingState) {
    return AppBar(
      backgroundColor: const Color(0xFF0B0F19),
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF8800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
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
                  letterSpacing: -0.3,
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
        // Botão para voltar ao App Cliente
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Color(0xFF334155)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
            context.go('/home');
          },
          child: const Text('App Cliente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
    );
  }

  /// Barra de Abas Tática (Sem Rolagem Caótica)
  Widget _buildTacticalTabBar(bool hasActiveDelivery, int queuedCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFFF6B00),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.navigation_rounded, size: 15),
                const SizedBox(width: 6),
                const Text('Em Rota'),
                if (hasActiveDelivery) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.format_list_bulleted_rounded, size: 15),
                const SizedBox(width: 6),
                Text('Fila ($queuedCount)'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.account_balance_wallet_rounded, size: 15),
                SizedBox(width: 6),
                Text('Ganhos'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ABA 1: COCKPIT DA ENTREGA ATIVA (MAPA + CARTÃO DE MISSÃO ERGONÔMICO)
  Widget _buildActiveDeliveryTab(OrderModel? order, CourierTrackingState trackingState) {
    if (order == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nenhuma Entrega em Andamento',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Você está livre para aceitar novos botijões da distribuidora.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                label: const Text('Ver Fila de Pedidos', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 1. MAPA INTERATIVO HERO (Sem bordas grosseiras, com controles táticos flutuantes)
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              BoraGasInteractiveMap(
                destination: _destinationCoords,
                initialCourierPosition: _courierStartCoords,
                initialRoute: _activeRoute,
                courierName: 'Sua Moto (Honda 160)',
              ),

              // Floating Pill: Telemetria da Rota (Tempo e Distância)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        '6 min',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(3.6 km)',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Pill: Status do GPS Real / Simulado
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isUsingRealGps
                          ? const Color(0xFF10B981)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isUsingRealGps ? Icons.my_location_rounded : Icons.location_searching_rounded,
                        color: _isUsingRealGps ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isUsingRealGps ? 'GPS Ativo' : 'GPS Rota',
                        style: TextStyle(
                          color: _isUsingRealGps ? const Color(0xFF34D399) : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. PAINEL DE MISSÃO INFERIOR (HUD TÁTICO BRANCO MODERNO)
        Expanded(
          flex: 6,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Puxador central ergonômico
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header da Entrega: Número do Pedido + Loja + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              order.orderNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.storeName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                      StatusBadge.fromOrderStatus(order.status),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Endereço de Entrega (Visual Destacado)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.place_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DESTINO DE ENTREGA',
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
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Card de Contato do Cliente (WhatsApp e Chamada com 1 toque)
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
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 18, color: Color(0xFF475569)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                order.customerPhone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botão WhatsApp com cor sólida e contraste perfeito
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _whatsappCustomer(order.customerPhone),
                          icon: const Icon(Icons.chat_rounded, size: 15),
                          label: const Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        // Botão Ligar
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            foregroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.all(8),
                          ),
                          icon: const Icon(Icons.call_rounded, size: 18),
                          tooltip: 'Ligar para o Cliente',
                          onPressed: () => _callCustomer(order.customerPhone),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // NAVEGAÇÃO GPS EXTERNA (Waze e Google Maps em Linha Estilizada)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            backgroundColor: const Color(0xFFF0F9FF),
                            side: const BorderSide(color: Color(0xFFBAE6FD), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            ExternalNavigationService.openWaze(
                              latitude: _destinationCoords.latitude,
                              longitude: _destinationCoords.longitude,
                            );
                          },
                          icon: const Icon(Icons.near_me_rounded, size: 16),
                          label: const Text('Abrir Waze', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF166534),
                            backgroundColor: const Color(0xFFF0FDF4),
                            side: const BorderSide(color: Color(0xFFBBF7D0), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            ExternalNavigationService.openGoogleMaps(
                              latitude: _destinationCoords.latitude,
                              longitude: _destinationCoords.longitude,
                            );
                          },
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // AÇÕES DA ENTREGA: AVISAR CHEGADA & VALIDAR PIN
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _notifyCustomerArrival(order),
                          icon: const Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFFFF6B00)),
                          label: const Text('Avisei Chegada', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _openPinValidationDialog(order),
                          icon: const Icon(Icons.lock_open_rounded, size: 20),
                          label: const Text(
                            'VALIDAR PIN',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ABA 2: FILA DE PEDIDOS AGUARDANDO DESPACHO
  Widget _buildQueuedOrdersTab(List<OrderModel> queuedOrders) {
    if (queuedOrders.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist_rounded, color: Color(0xFF38BDF8), size: 54),
              SizedBox(height: 16),
              Text(
                'Fila de Pedidos Vazia',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                'Não há novos botijões aguardando despacho no momento.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: queuedOrders.length,
      itemBuilder: (context, index) {
        final order = queuedOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.orderNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.storeName,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge.fromOrderStatus(order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_rounded, color: Color(0xFF94A3B8), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, color: Color(0xFF64748B), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${order.customerName} • ${order.customerPhone}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  minimumSize: const Size.fromHeight(44),
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
                  _tabController.animateTo(0);
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Iniciar Esta Entrega', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ABA 3: PERFIL, GANHOS E TELEMETRIA
  Widget _buildDriverWalletTab(CourierTrackingState trackingState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de Perfil do Entregador
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marcos Oliveira (Condutor)',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.two_wheeler_rounded, color: Color(0xFF94A3B8), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Honda Fan 160 • Placa BRA-2024',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Card de Ganhos Diários
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Extrato de Ganhos (Taxas)',
                      style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Icon(Icons.payments_rounded, color: Color(0xFF34D399), size: 22),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'R\$ 148,00',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Total de 11 entregas realizadas hoje • Média R\$ 13,45/entrega',
                  style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Painel de Telemetria e Conectividade GPS
          const Text(
            'TELEMETRIA & CONEXÃO GPS',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transmissões', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(
                        '${trackingState.metrics.messagesSent} pings',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text('Sinal sincronizado', style: TextStyle(color: Color(0xFF10B981), fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Intervalo GPS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(
                        '~${trackingState.metrics.averageIntervalSeconds.toStringAsFixed(1)}s',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text('Taxa adaptativa', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10)),
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
}
