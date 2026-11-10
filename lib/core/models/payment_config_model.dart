class StorePaymentConfigModel {
  final String storeId;
  final String gatewayProvider; // 'mercadopago', 'abacatepay'
  final String publicKey;
  final String accessToken;
  final String webhookSecret;
  final String posTerminalProvider; // 'Mercado Pago Point Pro 2', 'PagBank Moderninha Smart', 'Stone'
  final String posDeviceSerialId;
  final bool acceptsOnlinePix;
  final bool acceptsOnlineCard;
  final bool acceptsPosOnDelivery;
  final bool acceptsCashOnDelivery;
  final bool isGatewayConnected;

  const StorePaymentConfigModel({
    required this.storeId,
    this.gatewayProvider = 'mercadopago',
    this.publicKey = 'APP_USR-782193-mock-key',
    this.accessToken = 'APP_USR-782193-mock-token-live',
    this.webhookSecret = 'whsec_mock_boragas_secret',
    this.posTerminalProvider = 'Mercado Pago Point Smart',
    this.posDeviceSerialId = 'MP-POINT-98721',
    this.acceptsOnlinePix = true,
    this.acceptsOnlineCard = true,
    this.acceptsPosOnDelivery = true,
    this.acceptsCashOnDelivery = true,
    this.isGatewayConnected = true,
  });

  StorePaymentConfigModel copyWith({
    String? storeId,
    String? gatewayProvider,
    String? publicKey,
    String? accessToken,
    String? webhookSecret,
    String? posTerminalProvider,
    String? posDeviceSerialId,
    bool? acceptsOnlinePix,
    bool? acceptsOnlineCard,
    bool? acceptsPosOnDelivery,
    bool? acceptsCashOnDelivery,
    bool? isGatewayConnected,
  }) {
    return StorePaymentConfigModel(
      storeId: storeId ?? this.storeId,
      gatewayProvider: gatewayProvider ?? this.gatewayProvider,
      publicKey: publicKey ?? this.publicKey,
      accessToken: accessToken ?? this.accessToken,
      webhookSecret: webhookSecret ?? this.webhookSecret,
      posTerminalProvider: posTerminalProvider ?? this.posTerminalProvider,
      posDeviceSerialId: posDeviceSerialId ?? this.posDeviceSerialId,
      acceptsOnlinePix: acceptsOnlinePix ?? this.acceptsOnlinePix,
      acceptsOnlineCard: acceptsOnlineCard ?? this.acceptsOnlineCard,
      acceptsPosOnDelivery: acceptsPosOnDelivery ?? this.acceptsPosOnDelivery,
      acceptsCashOnDelivery:
          acceptsCashOnDelivery ?? this.acceptsCashOnDelivery,
      isGatewayConnected: isGatewayConnected ?? this.isGatewayConnected,
    );
  }
}
