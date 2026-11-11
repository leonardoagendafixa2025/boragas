import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_shell_screen.dart';
import '../../features/auth/presentation/bem_vindo_screen.dart';
import '../../features/auth/presentation/cadastro_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/recuperar_senha_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
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
      path: '/',
      redirect: (context, state) => '/splash',
    ),
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
      path: '/cadastro',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CadastroScreen(),
    ),
    GoRoute(
      path: '/recuperar',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RecuperarSenhaScreen(),
    ),
    GoRoute(
      path: '/bem-vindo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final nome = extra?['nome'] as String? ?? '';
        final primeiroAcesso = extra?['primeiroAcesso'] as bool? ?? false;
        return BemVindoScreen(nome: nome, primeiroAcesso: primeiroAcesso);
      },
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

/// Listenable que notifica o GoRouter sempre que o estado de autenticação ou role mudar
class AuthRouterListenable extends ChangeNotifier {
  final Ref _ref;

  AuthRouterListenable(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated ||
            previous?.user?.role != next.user?.role ||
            previous?.isSessionChecked != next.isSessionChecked) {
          notifyListeners();
        }
      },
    );
  }
}

String homeForRole(UserRole? role) {
  switch (role) {
    case UserRole.admin:
      return '/admin';
    case UserRole.merchant:
      return '/merchant';
    case UserRole.courier:
      return '/courier';
    case UserRole.customer:
    default:
      return '/home';
  }
}

/// Função pura de validação e Route Guard do BoraGás (RBAC Estrito)
String? evaluateAppRouteRedirect({
  required AuthState auth,
  required String location,
}) {
  final isAuthenticated = auth.isAuthenticated && auth.user != null;
  final role = auth.user?.role;

  final isAdminRoute = location == '/admin' || location.startsWith('/admin/');
  final isMerchantRoute = location == '/merchant' || location.startsWith('/merchant/');
  final isCourierRoute = location == '/courier' || location.startsWith('/courier/');

  // 1. Proteção estrita de rotas restritas (Admin, Lojista/Logística e Entregador)
  if (isAdminRoute || isMerchantRoute || isCourierRoute) {
    if (!isAuthenticated) {
      // NÃO AUTENTICADO: redirecionamento imediato para login
      return '/login';
    }

    // AUTENTICADO: verificação estrita de privilégios (RBAC)
    if (isAdminRoute && role != UserRole.admin) {
      return homeForRole(role);
    }
    if (isMerchantRoute && role != UserRole.merchant && role != UserRole.admin) {
      return homeForRole(role);
    }
    if (isCourierRoute && role != UserRole.courier && role != UserRole.admin) {
      return homeForRole(role);
    }
  }

  // 2. Se já autenticado e estiver em rotas públicas como /login
  if (isAuthenticated && location == '/login') {
    return homeForRole(role);
  }

  return null;
}

/// Provider do roteador GoRouter com Route Guards & RBAC Estrito
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = AuthRouterListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      return evaluateAppRouteRedirect(
        auth: ref.read(authProvider),
        location: state.uri.path,
      );
    },
    routes: _buildAppRoutes(),
  );
});

/// Roteador estático legado
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: _buildAppRoutes(),
);
