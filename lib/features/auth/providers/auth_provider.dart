import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

enum UserRole { customer, merchant, courier, admin }

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final String? storeId; // Preenchido para lojistas e entregadores vinculados
  final String? vehicleModel; // Modelo da moto/veículo (ex: Honda CG 160)
  final String? vehiclePlate; // Placa do veículo (ex: BRA-2024)

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.storeId,
    this.vehicleModel,
    this.vehiclePlate,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? storeId,
    String? vehicleModel,
    String? vehiclePlate,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = true, // Inicia autenticado como cliente de demonstração
    this.user = const UserProfile(
      id: 'usr-001',
      name: 'Carlos Eduardo Silva',
      phone: '(11) 98122-3344',
      email: 'carlos.silva@email.com',
      role: UserRole.customer,
    ),
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> sendPhoneOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.auth.signInWithOtp(
          phone: phone.replaceAll(RegExp(r'\D'), ''),
        );
      } catch (e) {
        // Fallback para mock
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 900));

    if (code == '123456' || code.length == 6) {
      state = state.copyWith(
        isAuthenticated: true,
        user: UserProfile(
          id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Cliente BoraGás',
          phone: phone,
          email: 'cliente@boragas.app',
          role: UserRole.customer,
        ),
        isLoading: false,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Código incorreto. Tente usar 123456.',
    );
    return false;
  }

  Future<bool> loginMerchant(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 900));

    state = state.copyWith(
      isAuthenticated: true,
      user: UserProfile(
        id: 'merch-01',
        name: 'Gerente Ultragaz Paulistana',
        phone: '(11) 98711-2233',
        email: email,
        role: UserRole.merchant,
        storeId: 'store-1',
      ),
      isLoading: false,
    );
    return true;
  }

  Future<bool> loginCourier(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 900));

    state = state.copyWith(
      isAuthenticated: true,
      user: UserProfile(
        id: 'courier-01',
        name: 'Marcos Oliveira',
        phone: '(11) 97722-1199',
        email: email,
        role: UserRole.courier,
        storeId: 'store-1',
        vehicleModel: 'Honda Fan 160',
        vehiclePlate: 'BRA-2024',
      ),
      isLoading: false,
    );
    return true;
  }

  Future<bool> updateVehicleInfo({
    required String vehicleModel,
    required String vehiclePlate,
  }) async {
    if (state.user == null) return false;

    state = state.copyWith(
      user: state.user!.copyWith(
        vehicleModel: vehicleModel,
        vehiclePlate: vehiclePlate,
      ),
    );

    // Persiste no Supabase caso online
    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      try {
        final currentUid = SupabaseService.client.auth.currentUser?.id;
        final targetId = currentUid ?? (state.user!.id.length >= 32 ? state.user!.id : null);
        if (targetId != null) {
          await SupabaseService.client.from('profiles').update({
            'vehicle_model': vehicleModel,
            'license_plate': vehiclePlate,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', targetId);
        }
      } catch (e) {
        debugPrint('Erro ao persistir veículo no Supabase: $e');
      }
    }
    return true;
  }

  Future<bool> loginAdmin(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 900));

    state = state.copyWith(
      isAuthenticated: true,
      user: UserProfile(
        id: 'admin-01',
        name: 'Super Administrador BoraGás',
        phone: '(11) 98888-0001',
        email: email,
        role: UserRole.admin,
      ),
      isLoading: false,
    );
    return true;
  }

  void switchDemoRole(UserRole role) {
    if (role == UserRole.customer) {
      state = state.copyWith(
        user: const UserProfile(
          id: 'usr-001',
          name: 'Carlos Eduardo Silva',
          phone: '(11) 98122-3344',
          email: 'carlos.silva@email.com',
          role: UserRole.customer,
        ),
      );
    } else if (role == UserRole.merchant) {
      state = state.copyWith(
        user: const UserProfile(
          id: 'merch-01',
          name: 'Gerente Ultragaz Paulistana',
          phone: '(11) 98711-2233',
          email: 'lojista@boragas.app',
          role: UserRole.merchant,
          storeId: 'store-1',
        ),
      );
    } else if (role == UserRole.courier) {
      state = state.copyWith(
        user: const UserProfile(
          id: 'courier-01',
          name: 'Marcos Oliveira',
          phone: '(11) 97722-1199',
          email: 'entregador@boragas.app',
          role: UserRole.courier,
          storeId: 'store-1',
          vehicleModel: 'Honda Fan 160',
          vehiclePlate: 'BRA-2024',
        ),
      );
    } else {
      state = state.copyWith(
        user: const UserProfile(
          id: 'admin-01',
          name: 'Super Admin Master',
          phone: '(11) 98888-0001',
          email: 'admin@boragas.app',
          role: UserRole.admin,
        ),
      );
    }
  }

  void logout() {
    state = const AuthState(isAuthenticated: false, user: null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
