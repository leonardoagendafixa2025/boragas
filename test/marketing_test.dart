import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/core/constants/app_colors.dart';
import 'package:boragas/core/models/marketing_model.dart';
import 'package:boragas/features/customer/presentation/loyalty_screen.dart';
import 'package:boragas/features/customer/presentation/referral_screen.dart';
import 'package:boragas/features/customer/presentation/widgets/marketing/flash_deal_card.dart';
import 'package:boragas/features/customer/presentation/widgets/marketing/loyalty_card_widget.dart';
import 'package:boragas/features/customer/presentation/widgets/marketing/stories_bar.dart';
import 'package:boragas/features/customer/providers/marketing_providers.dart';

void main() {
  final sampleStoryGroups = [
    const StoryGroupModel(
      id: 'stories-relampago',
      label: 'Relâmpago',
      icon: Icons.electric_bolt_rounded,
      isUnseen: true,
      ringGradientColors: [AppColors.accentFlame, Color(0xFFEF4444)],
      slides: [],
    ),
    const StoryGroupModel(
      id: 'stories-cupons',
      label: 'Cupons',
      icon: Icons.local_activity_rounded,
      isUnseen: true,
      ringGradientColors: [AppColors.primary, Color(0xFF38BDF8)],
      slides: [],
    ),
    const StoryGroupModel(
      id: 'stories-combos',
      label: 'Combos',
      icon: Icons.auto_awesome_rounded,
      isUnseen: true,
      ringGradientColors: [AppColors.success, Color(0xFF10B981)],
      slides: [],
    ),
    const StoryGroupModel(
      id: 'stories-seguranca',
      label: 'Segurança',
      icon: Icons.verified_user_rounded,
      isUnseen: false,
      ringGradientColors: [AppColors.border, AppColors.textMuted],
      slides: [],
    ),
    const StoryGroupModel(
      id: 'stories-indique',
      label: 'Ganhe R\$10',
      icon: Icons.card_giftcard_rounded,
      isUnseen: true,
      ringGradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      slides: [],
    ),
  ];

  final sampleDeal = FlashDealModel(
    id: 'fd-test-01',
    storeId: 'store-1',
    storeName: 'Ultragaz Paulistana Express',
    productName: 'Botijão P13 (13kg)',
    brand: 'Ultragaz',
    originalPrice: 110.00,
    promotionalPrice: 94.90,
    endsAt: DateTime.now().add(const Duration(hours: 2)),
    totalStock: 10,
    remainingStock: 5,
    neighborhood: 'Bela Vista',
  );

  group('StoriesBar Marketing Tests', () {
    testWidgets('StoriesBar inicia limpo sem dados mock em produção', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StoriesBar(),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('StoriesBar renderiza grupos ativos quando configurados', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storiesProvider.overrideWith(() => _MockStoriesNotifier(sampleStoryGroups)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StoriesBar(),
            ),
          ),
        ),
      );

      expect(find.text('Relâmpago'), findsOneWidget);
      expect(find.text('Cupons'), findsOneWidget);
      expect(find.text('Combos'), findsOneWidget);
      expect(find.text('Segurança'), findsOneWidget);
      expect(find.text('Ganhe R\$10'), findsOneWidget);
    });
  });

  group('FlashDealCard Marketing Tests', () {
    testWidgets('FlashDealCard não renderiza nada se não houver oferta ativa (produção limpa)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FlashDealCard(),
            ),
          ),
        ),
      );

      expect(find.text('CHAMA RELÂMPAGO'), findsNothing);
    });

    testWidgets('FlashDealCard renderiza oferta com urgência e desconto quando ativa', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            flashDealProvider.overrideWith(() => _MockFlashDealNotifier(sampleDeal)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FlashDealCard(),
            ),
          ),
        ),
      );

      expect(find.text('CHAMA RELÂMPAGO'), findsOneWidget);
      expect(find.textContaining('Ultragaz'), findsWidgets);
      expect(find.textContaining('Restam apenas'), findsOneWidget);
      expect(find.textContaining('Garantir por R\$'), findsOneWidget);
    });
  });

  group('LoyaltyCard & Referral Tests', () {
    testWidgets('LoyaltyCardWidget renderiza 5 slots em estado inicial limpo (0 selos marcados)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoyaltyCardWidget(),
            ),
          ),
        ),
      );

      expect(find.text('Cartão Fidelidade BoraGás'), findsOneWidget);
      expect(find.text('Prêmio!'), findsOneWidget);
      expect(find.text('Faça seu 1º pedido para ganhar seu primeiro selo!'), findsOneWidget);
    });

    testWidgets('LoyaltyCardWidget exibe progresso quando selos são acumulados', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loyaltyCardProvider.overrideWith(() => _MockLoyaltyCardNotifier(
                  const LoyaltyCardModel(
                    currentStamps: 3,
                    totalStampsRequired: 5,
                    rewardDescription: 'R\$ 25 OFF',
                    rewardDiscountValue: 25.00,
                    completedOrders: ['#BG-101', '#BG-102', '#BG-103'],
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoyaltyCardWidget(),
            ),
          ),
        ),
      );

      expect(find.textContaining('Faltam apenas 2 pedidos'), findsOneWidget);
    });

    testWidgets('ReferralScreen renderiza carteira inicial zerada e código de indicação', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ReferralScreen(),
          ),
        ),
      );

      expect(find.text('Indique & Ganhe'), findsOneWidget);
      expect(find.text('BORAVIZINHO10'), findsOneWidget);
      expect(find.text('Compartilhar no WhatsApp'), findsOneWidget);
      expect(find.textContaining('R\$ 0,00'), findsOneWidget);
    });

    testWidgets('LoyaltyScreen renderiza estado limpo com histórico vazio', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoyaltyScreen(),
          ),
        ),
      );

      expect(find.text('BoraGás Fidelidade VIP'), findsOneWidget);
      expect(find.text('0 de 5 Selos'), findsOneWidget);
      expect(find.text('Nenhum pedido finalizado ainda'), findsOneWidget);
    });
  });
}

class _MockStoriesNotifier extends StoriesNotifier {
  final List<StoryGroupModel> _initial;
  _MockStoriesNotifier(this._initial);

  @override
  List<StoryGroupModel> build() => _initial;
}

class _MockFlashDealNotifier extends FlashDealNotifier {
  final FlashDealModel? _initial;
  _MockFlashDealNotifier(this._initial);

  @override
  FlashDealModel? build() => _initial;
}

class _MockLoyaltyCardNotifier extends LoyaltyCardNotifier {
  final LoyaltyCardModel _initial;
  _MockLoyaltyCardNotifier(this._initial);

  @override
  LoyaltyCardModel build() => _initial;
}
