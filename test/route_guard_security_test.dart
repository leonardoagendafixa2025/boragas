import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/core/router/app_router.dart';
import 'package:boragas/features/auth/providers/auth_provider.dart';

void main() {
  group('Route Guards & Strict RBAC Protection Tests - BoraGás', () {
    const unauthenticatedState = AuthState(
      isAuthenticated: false,
      user: null,
      isSessionChecked: true,
    );

    final customerState = const AuthState(
      isAuthenticated: true,
      isSessionChecked: true,
      user: UserProfile(
        id: 'usr-1',
        name: 'Cliente Teste',
        phone: '(11) 98000-1111',
        email: 'cliente@teste.com',
        role: UserRole.customer,
      ),
    );

    final merchantState = const AuthState(
      isAuthenticated: true,
      isSessionChecked: true,
      user: UserProfile(
        id: 'merch-1',
        name: 'Lojista Teste',
        phone: '(11) 98000-2222',
        email: 'lojista@teste.com',
        role: UserRole.merchant,
        storeId: 'store-1',
      ),
    );

    final courierState = const AuthState(
      isAuthenticated: true,
      isSessionChecked: true,
      user: UserProfile(
        id: 'courier-1',
        name: 'Entregador Teste',
        phone: '(11) 98000-3333',
        email: 'entregador@teste.com',
        role: UserRole.courier,
        vehicleModel: 'Honda Fan 160',
        vehiclePlate: 'BRA-2024',
      ),
    );

    final adminState = const AuthState(
      isAuthenticated: true,
      isSessionChecked: true,
      user: UserProfile(
        id: 'admin-1',
        name: 'Admin Teste',
        phone: '(11) 98000-4444',
        email: 'admin@teste.com',
        role: UserRole.admin,
      ),
    );

    test('1. Unauthenticated user accessing /admin is redirected to /login', () {
      final redirect = evaluateAppRouteRedirect(
        auth: unauthenticatedState,
        location: '/admin',
      );
      expect(redirect, equals('/login'));
    });

    test('2. Unauthenticated user accessing /merchant is redirected to /login', () {
      final redirect = evaluateAppRouteRedirect(
        auth: unauthenticatedState,
        location: '/merchant',
      );
      expect(redirect, equals('/login'));
    });

    test('3. Unauthenticated user accessing /courier is redirected to /login', () {
      final redirect = evaluateAppRouteRedirect(
        auth: unauthenticatedState,
        location: '/courier',
      );
      expect(redirect, equals('/login'));
    });

    test('4. Authenticated Customer trying to access /admin is blocked and redirected to /home', () {
      final redirect = evaluateAppRouteRedirect(
        auth: customerState,
        location: '/admin',
      );
      expect(redirect, equals('/home'));
    });

    test('5. Authenticated Customer trying to access /merchant is blocked and redirected to /home', () {
      final redirect = evaluateAppRouteRedirect(
        auth: customerState,
        location: '/merchant',
      );
      expect(redirect, equals('/home'));
    });

    test('6. Authenticated Customer trying to access /courier is blocked and redirected to /home', () {
      final redirect = evaluateAppRouteRedirect(
        auth: customerState,
        location: '/courier',
      );
      expect(redirect, equals('/home'));
    });

    test('7. Authenticated Merchant is permitted on /merchant and blocked on /admin', () {
      final merchantOnMerchant = evaluateAppRouteRedirect(
        auth: merchantState,
        location: '/merchant',
      );
      expect(merchantOnMerchant, isNull); // Permitted!

      final merchantOnAdmin = evaluateAppRouteRedirect(
        auth: merchantState,
        location: '/admin',
      );
      expect(merchantOnAdmin, equals('/merchant')); // Blocked & redirected to own portal
    });

    test('8. Authenticated Courier is permitted on /courier and blocked on /admin', () {
      final courierOnCourier = evaluateAppRouteRedirect(
        auth: courierState,
        location: '/courier',
      );
      expect(courierOnCourier, isNull); // Permitted!

      final courierOnAdmin = evaluateAppRouteRedirect(
        auth: courierState,
        location: '/admin',
      );
      expect(courierOnAdmin, equals('/courier')); // Blocked & redirected to own portal
    });

    test('9. Authenticated Admin has master access to /admin, /merchant, and /courier', () {
      expect(evaluateAppRouteRedirect(auth: adminState, location: '/admin'), isNull);
      expect(evaluateAppRouteRedirect(auth: adminState, location: '/merchant'), isNull);
      expect(evaluateAppRouteRedirect(auth: adminState, location: '/courier'), isNull);
    });

    test('10. Authenticated users on /login are redirected to their respective home', () {
      expect(evaluateAppRouteRedirect(auth: adminState, location: '/login'), equals('/admin'));
      expect(evaluateAppRouteRedirect(auth: merchantState, location: '/login'), equals('/merchant'));
      expect(evaluateAppRouteRedirect(auth: courierState, location: '/login'), equals('/courier'));
      expect(evaluateAppRouteRedirect(auth: customerState, location: '/login'), equals('/home'));
    });
  });
}
