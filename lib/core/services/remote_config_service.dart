import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteConfigState {
  final bool isMaintenanceMode;
  final String announcementBannerText;
  final bool showAnnouncementBanner;
  final Color seasonalAccentColor;
  final double defaultPlatformCommissionPercent;
  final bool enableDynamicPriceComparison;
  final int estimatedAverageDeliveryMinutes;
  final String supportContactPhone;
  final bool allowGuestOrders;

  const RemoteConfigState({
    this.isMaintenanceMode = false,
    this.announcementBannerText = '⚡ Entrega Turbo ativada em toda a sua região!',
    this.showAnnouncementBanner = true,
    this.seasonalAccentColor = const Color(0xFF0052CC),
    this.defaultPlatformCommissionPercent = 8.0,
    this.enableDynamicPriceComparison = true,
    this.estimatedAverageDeliveryMinutes = 25,
    this.supportContactPhone = '(11) 98765-4321',
    this.allowGuestOrders = false,
  });

  RemoteConfigState copyWith({
    bool? isMaintenanceMode,
    String? announcementBannerText,
    bool? showAnnouncementBanner,
    Color? seasonalAccentColor,
    double? defaultPlatformCommissionPercent,
    bool? enableDynamicPriceComparison,
    int? estimatedAverageDeliveryMinutes,
    String? supportContactPhone,
    bool? allowGuestOrders,
  }) {
    return RemoteConfigState(
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      announcementBannerText:
          announcementBannerText ?? this.announcementBannerText,
      showAnnouncementBanner:
          showAnnouncementBanner ?? this.showAnnouncementBanner,
      seasonalAccentColor: seasonalAccentColor ?? this.seasonalAccentColor,
      defaultPlatformCommissionPercent: defaultPlatformCommissionPercent ??
          this.defaultPlatformCommissionPercent,
      enableDynamicPriceComparison:
          enableDynamicPriceComparison ?? this.enableDynamicPriceComparison,
      estimatedAverageDeliveryMinutes:
          estimatedAverageDeliveryMinutes ?? this.estimatedAverageDeliveryMinutes,
      supportContactPhone: supportContactPhone ?? this.supportContactPhone,
      allowGuestOrders: allowGuestOrders ?? this.allowGuestOrders,
    );
  }
}

class RemoteConfigNotifier extends Notifier<RemoteConfigState> {
  @override
  RemoteConfigState build() => const RemoteConfigState();

  void updateConfig({
    bool? isMaintenanceMode,
    String? announcementBannerText,
    bool? showAnnouncementBanner,
    Color? seasonalAccentColor,
    double? defaultPlatformCommissionPercent,
    bool? enableDynamicPriceComparison,
    int? estimatedAverageDeliveryMinutes,
    String? supportContactPhone,
    bool? allowGuestOrders,
  }) {
    state = state.copyWith(
      isMaintenanceMode: isMaintenanceMode,
      announcementBannerText: announcementBannerText,
      showAnnouncementBanner: showAnnouncementBanner,
      seasonalAccentColor: seasonalAccentColor,
      defaultPlatformCommissionPercent: defaultPlatformCommissionPercent,
      enableDynamicPriceComparison: enableDynamicPriceComparison,
      estimatedAverageDeliveryMinutes: estimatedAverageDeliveryMinutes,
      supportContactPhone: supportContactPhone,
      allowGuestOrders: allowGuestOrders,
    );
  }

  void toggleMaintenance() {
    state = state.copyWith(isMaintenanceMode: !state.isMaintenanceMode);
  }

  void toggleAnnouncement() {
    state = state.copyWith(showAnnouncementBanner: !state.showAnnouncementBanner);
  }

  void setAnnouncementText(String text) {
    state = state.copyWith(announcementBannerText: text);
  }

  void setDefaultCommission(double commission) {
    state = state.copyWith(defaultPlatformCommissionPercent: commission);
  }
}

final remoteConfigProvider =
    NotifierProvider<RemoteConfigNotifier, RemoteConfigState>(
  RemoteConfigNotifier.new,
);
