import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/features/customer/presentation/loyalty_screen.dart';
import 'package:boragas/features/customer/presentation/referral_screen.dart';
import 'package:boragas/features/customer/presentation/widgets/marketing/flash_deal_card.dart';
import 'package:boragas/features/customer/presentation/widgets/marketing/loyalty_card_widget.dart';
import 'package:boragas/features/customer/presentation/widgets/marketing/stories_bar.dart';

void main() {
  testWidgets('StoriesBar renders marketing story groups with icons and labels', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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

  testWidgets('FlashDealCard renders countdown deal with urgency and discount', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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

  testWidgets('LoyaltyCardWidget renders 5 stamp slots and progress text', (WidgetTester tester) async {
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
    expect(find.textContaining('Faltam apenas 2 pedidos'), findsOneWidget);
  });

  testWidgets('ReferralScreen renders credit balance, user code, and WhatsApp CTA', (WidgetTester tester) async {
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
    expect(find.textContaining('R\$ 20,00'), findsOneWidget);
  });

  testWidgets('LoyaltyScreen renders VIP card, stamps, and completed orders history', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoyaltyScreen(),
        ),
      ),
    );

    expect(find.text('BoraGás Fidelidade VIP'), findsOneWidget);
    expect(find.text('Faltam 2 selos para completar'), findsOneWidget);
    expect(find.text('R\$ 25 OFF'), findsOneWidget);
    expect(find.text('Pedidos que Pontuaram Neste Cartão'), findsOneWidget);
  });
}
