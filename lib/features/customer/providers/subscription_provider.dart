import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_service.dart';

class SubscriptionClubModel {
  final bool isActive;
  final String planId;
  final String planTitle;
  final double planPrice;
  final int frequencyDays;
  final String timeSlot;
  final DateTime nextDeliveryDate;
  final bool isPaused;
  final DateTime createdAt;
  final String deliveryAddress;

  const SubscriptionClubModel({
    required this.isActive,
    required this.planId,
    required this.planTitle,
    required this.planPrice,
    required this.frequencyDays,
    required this.timeSlot,
    required this.nextDeliveryDate,
    required this.isPaused,
    required this.createdAt,
    required this.deliveryAddress,
  });

  int get daysUntilNextDelivery {
    final diff = nextDeliveryDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  SubscriptionClubModel copyWith({
    bool? isActive,
    String? planId,
    String? planTitle,
    double? planPrice,
    int? frequencyDays,
    String? timeSlot,
    DateTime? nextDeliveryDate,
    bool? isPaused,
    DateTime? createdAt,
    String? deliveryAddress,
  }) {
    return SubscriptionClubModel(
      isActive: isActive ?? this.isActive,
      planId: planId ?? this.planId,
      planTitle: planTitle ?? this.planTitle,
      planPrice: planPrice ?? this.planPrice,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      timeSlot: timeSlot ?? this.timeSlot,
      nextDeliveryDate: nextDeliveryDate ?? this.nextDeliveryDate,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_active': isActive,
        'plan_id': planId,
        'plan_title': planTitle,
        'plan_price': planPrice,
        'frequency_days': frequencyDays,
        'time_slot': timeSlot,
        'next_delivery_date': nextDeliveryDate.toIso8601String(),
        'is_paused': isPaused,
        'created_at': createdAt.toIso8601String(),
        'delivery_address': deliveryAddress,
      };

  factory SubscriptionClubModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionClubModel(
      isActive: json['is_active'] as bool? ?? true,
      planId: json['plan_id'] as String? ?? 'gas-p13',
      planTitle: json['plan_title'] as String? ?? 'Botijão GLP 13kg (Troca)',
      planPrice: (json['plan_price'] as num?)?.toDouble() ?? 99.75,
      frequencyDays: json['frequency_days'] as int? ?? 45,
      timeSlot: json['time_slot'] as String? ?? 'Sábado pela manhã (09h - 12h)',
      nextDeliveryDate: json['next_delivery_date'] != null
          ? DateTime.tryParse(json['next_delivery_date'] as String) ??
              DateTime.now().add(const Duration(days: 45))
          : DateTime.now().add(const Duration(days: 45)),
      isPaused: json['is_paused'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      deliveryAddress: json['delivery_address'] as String? ?? '',
    );
  }
}

class SubscriptionClubNotifier extends Notifier<SubscriptionClubModel?> {
  static const _storageKey = 'boragas_subscription_club_v1';

  @override
  SubscriptionClubModel? build() {
    _loadFromStorage();
    return null;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = SubscriptionClubModel.fromJson(map);
      }
    } catch (e) {
      debugPrint('Aviso ao carregar assinatura do Clube BoraGás: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state == null) {
        await prefs.remove(_storageKey);
      } else {
        await prefs.setString(_storageKey, jsonEncode(state!.toJson()));
      }
    } catch (e) {
      debugPrint('Aviso ao salvar assinatura do Clube BoraGás: $e');
    }
  }

  Future<void> activateSubscription({
    required String planId,
    required String planTitle,
    required double planPrice,
    required int frequencyDays,
    required String timeSlot,
    required String deliveryAddress,
  }) async {
    final nextDate = DateTime.now().add(Duration(days: frequencyDays));
    state = SubscriptionClubModel(
      isActive: true,
      planId: planId,
      planTitle: planTitle,
      planPrice: planPrice,
      frequencyDays: frequencyDays,
      timeSlot: timeSlot,
      nextDeliveryDate: nextDate,
      isPaused: false,
      createdAt: DateTime.now(),
      deliveryAddress: deliveryAddress,
    );
    await _saveToStorage();

    // Sincroniza opcionalmente com Supabase se disponível
    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      SupabaseService.client.from('subscriptions').upsert({
        'plan_id': planId,
        'frequency_days': frequencyDays,
        'time_slot': timeSlot,
        'delivery_address': deliveryAddress,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).catchError((err) {
        debugPrint('Supabase subscriptions sync notice: $err');
      });
    }
  }

  Future<void> togglePause() async {
    if (state == null) return;
    state = state!.copyWith(isPaused: !state!.isPaused);
    await _saveToStorage();
  }

  Future<void> cancelSubscription() async {
    state = null;
    await _saveToStorage();
  }

  Future<void> postponeNextDelivery(int extraDays) async {
    if (state == null) return;
    final updatedDate = state!.nextDeliveryDate.add(Duration(days: extraDays));
    state = state!.copyWith(nextDeliveryDate: updatedDate);
    await _saveToStorage();
  }

  Future<void> advanceNextDeliveryToToday() async {
    if (state == null) return;
    state = state!.copyWith(nextDeliveryDate: DateTime.now());
    await _saveToStorage();
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionClubNotifier, SubscriptionClubModel?>(
        SubscriptionClubNotifier.new);
