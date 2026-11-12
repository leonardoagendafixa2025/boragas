class DeliveryFeeResult {
  final double fee;
  final bool isFree;
  final bool isOutOfRange;
  final String description;
  final String pricingMethod; // 'neighborhood', 'distance', 'free_threshold', 'store_base'

  const DeliveryFeeResult({
    required this.fee,
    required this.isFree,
    required this.isOutOfRange,
    required this.description,
    required this.pricingMethod,
  });
}

class StoreModel {
  final String id;
  final String name;
  final String cnpj;
  final String phone;
  final String logoUrl;
  final String coverUrl;
  final String address;
  final double distanceKm;
  final double rating;
  final int reviewsCount;
  final int estimatedTimeMin;
  final double deliveryFee; // Taxa base de entrega configurada pela distribuidora
  final bool isVerified;
  final bool isOpen;
  final double commissionRate; // e.g. 8.0 %
  final bool isSuspendedForNonPayment;

  // Regras avançadas de precificação de frete configuradas pela distribuidora
  final double feePerKm; // Valor em R$ cobrado por KM rodado
  final double maxDeliveryRadiusKm; // Raio máximo de atendimento da distribuidora em KM
  final double? freeDeliveryThreshold; // Valor mínimo de pedido para frete grátis (opcional)
  final Map<String, double> neighborhoodFees; // Mapeamento: nome do bairro -> taxa em R$
  final bool isNeighborhoodPricingEnabled; // Se a tabela de bairros está ativa

  const StoreModel({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.phone,
    required this.logoUrl,
    required this.coverUrl,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.reviewsCount,
    required this.estimatedTimeMin,
    required this.deliveryFee,
    this.isVerified = true,
    this.isOpen = true,
    this.commissionRate = 8.0,
    this.isSuspendedForNonPayment = false,
    this.feePerKm = 0.0,
    this.maxDeliveryRadiusKm = 15.0,
    this.freeDeliveryThreshold,
    this.neighborhoodFees = const {},
    this.isNeighborhoodPricingEnabled = true,
  });

  /// Normaliza nomes de bairros para busca insensível a acentos e maiúsculas/minúsculas
  static String normalizeNeighborhood(String input) {
    if (input.trim().isEmpty) return '';
    var text = input.trim().toLowerCase();
    const withAccents = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuucn';
    for (int i = 0; i < withAccents.length; i++) {
      text = text.replaceAll(withAccents[i], withoutAccents[i]);
    }
    // Remove pontuações e espaços extras
    text = text.replaceAll(RegExp(r'[^\w\s]'), '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Calcula o valor exato do frete da distribuidora para o endereço e subtotal informados
  DeliveryFeeResult calculateDeliveryFee({
    String? neighborhood,
    double? clientDistanceKm,
    double subtotal = 0.0,
  }) {
    // 1. Regra de Frete Grátis: se o subtotal atingir o mínimo configurado pela distribuidora
    if (freeDeliveryThreshold != null &&
        freeDeliveryThreshold! > 0 &&
        subtotal >= freeDeliveryThreshold!) {
      return DeliveryFeeResult(
        fee: 0.0,
        isFree: true,
        isOutOfRange: false,
        description:
            'Frete Grátis garantido pela distribuidora em pedidos acima de R\$ ${freeDeliveryThreshold!.toStringAsFixed(2).replaceAll('.', ',')}',
        pricingMethod: 'free_threshold',
      );
    }

    // 2. Regra por Tabela de Bairros da Distribuidora
    if (isNeighborhoodPricingEnabled &&
        neighborhood != null &&
        neighborhood.trim().isNotEmpty) {
      final normalizedTarget = normalizeNeighborhood(neighborhood);

      for (final entry in neighborhoodFees.entries) {
        if (normalizeNeighborhood(entry.key) == normalizedTarget) {
          final fee = entry.value;
          return DeliveryFeeResult(
            fee: fee,
            isFree: fee == 0.0,
            isOutOfRange: false,
            description: fee == 0.0
                ? 'Frete Grátis para o bairro ${entry.key}'
                : 'Taxa fixa da distribuidora para o bairro ${entry.key}: R\$ ${fee.toStringAsFixed(2).replaceAll('.', ',')}',
            pricingMethod: 'neighborhood',
          );
        }
      }
    }

    // 3. Regra por Quilometragem (KM) e Raio Máximo
    final effectiveDistance = clientDistanceKm ?? distanceKm;

    if (maxDeliveryRadiusKm > 0 && effectiveDistance > maxDeliveryRadiusKm) {
      return DeliveryFeeResult(
        fee: deliveryFee,
        isFree: false,
        isOutOfRange: true,
        description:
            'Endereço fora do raio de entrega desta distribuidora (máximo ${maxDeliveryRadiusKm.toStringAsFixed(1)} km, seu local está a ${effectiveDistance.toStringAsFixed(1)} km)',
        pricingMethod: 'out_of_range',
      );
    }

    // Cálculo por KM: Taxa Base + (Distância * Taxa por KM)
    final distanceCost = effectiveDistance * feePerKm;
    final totalFee = (deliveryFee + distanceCost);
    // Arredonda para 2 casas
    final roundedFee = (totalFee * 100).roundToDouble() / 100;

    return DeliveryFeeResult(
      fee: roundedFee,
      isFree: roundedFee == 0.0,
      isOutOfRange: false,
      description: roundedFee == 0.0
          ? 'Frete Grátis por distância'
          : 'Entrega por distância (${effectiveDistance.toStringAsFixed(1)} km: R\$ ${deliveryFee.toStringAsFixed(2).replaceAll('.', ',')} base + R\$ ${distanceCost.toStringAsFixed(2).replaceAll('.', ',')})',
      pricingMethod: 'distance',
    );
  }

  StoreModel copyWith({
    String? id,
    String? name,
    String? cnpj,
    String? phone,
    String? logoUrl,
    String? coverUrl,
    String? address,
    double? distanceKm,
    double? rating,
    int? reviewsCount,
    int? estimatedTimeMin,
    double? deliveryFee,
    bool? isVerified,
    bool? isOpen,
    double? commissionRate,
    bool? isSuspendedForNonPayment,
    double? feePerKm,
    double? maxDeliveryRadiusKm,
    double? freeDeliveryThreshold,
    Map<String, double>? neighborhoodFees,
    bool? isNeighborhoodPricingEnabled,
    bool clearFreeDeliveryThreshold = false,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      address: address ?? this.address,
      distanceKm: distanceKm ?? this.distanceKm,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      estimatedTimeMin: estimatedTimeMin ?? this.estimatedTimeMin,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isVerified: isVerified ?? this.isVerified,
      isOpen: isOpen ?? this.isOpen,
      commissionRate: commissionRate ?? this.commissionRate,
      isSuspendedForNonPayment:
          isSuspendedForNonPayment ?? this.isSuspendedForNonPayment,
      feePerKm: feePerKm ?? this.feePerKm,
      maxDeliveryRadiusKm: maxDeliveryRadiusKm ?? this.maxDeliveryRadiusKm,
      freeDeliveryThreshold: clearFreeDeliveryThreshold
          ? null
          : (freeDeliveryThreshold ?? this.freeDeliveryThreshold),
      neighborhoodFees: neighborhoodFees ?? this.neighborhoodFees,
      isNeighborhoodPricingEnabled:
          isNeighborhoodPricingEnabled ?? this.isNeighborhoodPricingEnabled,
    );
  }
}
