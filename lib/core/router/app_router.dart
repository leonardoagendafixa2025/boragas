import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_shell_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/courier/presentation/courier_screen.dart';
import '../../features/customer/presentation/cart_checkout_screen.dart';
import '../../features/customer/presentation/customer_shell_screen.dart';
import '../../features/customer/presentation/home_screen.dart';
import '../../features/customer/presentation/loyalty_screen.dart';
import '../../features/customer/presentation/order_history_screen.dart';
import '../../features/customer/presentation/order_tracking_screen.dart';
import '../../features/customer/presentation/referral_screen.dart';
import '../../features/customer/presentation/store_details_screen.dart';
import '../../features/customer/presentation/subscription_club_screen.dart';
import '../../features/merchant/presentation/merchant_shell_screen.dart';
import '../../features/splash/animated_splash_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/support/presentation/ticket_detail_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

List<RouteBase> _buildAppRoutes() {
  return [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const AnimatedSplashScreen(),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'] ?? '(11) 98122-3344';
        return OtpScreen(phone: phone);
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => CustomerShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportScreen(),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartCheckoutScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/store/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final storeId = state.pathParameters['id'] ?? '';
        return StoreDetailsScreen(storeId: storeId);
      },
    ),
    GoRoute(
      path: '/tracking/:orderId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return OrderTrackingScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/support/ticket/:ticketId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final ticketId = state.pathParameters['ticketId'] ?? '';
        return TicketDetailScreen(ticketId: ticketId);
      },
    ),
    // Portal do Lojista (Acesso Direto)
    GoRoute(
      path: '/merchant',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MerchantShellScreen(),
    ),
    // Super Admin Master Control (Acesso Direto)
    GoRoute(
      path: '/admin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminShellScreen(),
    ),
    // App do Entregador (Acesso Direto)
    GoRoute(
      path: '/courier',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CourierScreen(),
    ),
    GoRoute(
      path: '/subscription-club',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SubscriptionClubScreen(),
    ),
    GoRoute(
      path: '/referral',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: '/loyalty',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoyaltyScreen(),
    ),
  ];
}

/// Provider do roteador GoRouter com suporte a acesso direto por URL
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: _buildAppRoutes(),
  );
});

/// Roteador estático legado
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: _buildAppRoutes(),
);
