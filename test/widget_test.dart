import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/core/widgets/boragas_logo.dart';
import 'package:boragas/core/widgets/status_badge.dart';
import 'package:boragas/features/customer/presentation/home_screen.dart';
import 'package:boragas/features/customer/presentation/widgets/customer_drawer.dart';

void main() {
  testWidgets('BoraGás Logo renders correctly with brand text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BoraGasLogo(size: 64, showText: true),
        ),
      ),
    );

    expect(find.byType(BoraGasLogo), findsOneWidget);
    expect(find.text('ENTREGA RÁPIDA ⚡'), findsOneWidget);
  });

  testWidgets('StatusBadge renders correctly for order statuses', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusBadge.verified(),
        ),
      ),
    );

    expect(find.byType(StatusBadge), findsOneWidget);
    expect(find.text('Verificado'), findsOneWidget);
  });

  testWidgets('CustomerDrawer opens when hamburger button in HomeHeader is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    // Encontra o botão de menu hambúrguer no topo
    final menuButton = find.byTooltip('Menu e Portais');
    expect(menuButton, findsOneWidget);

    // Clica no botão de menu hambúrguer
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    // Valida que o CustomerDrawer abriu com as opções do menu
    expect(find.byType(CustomerDrawer), findsOneWidget);
    expect(find.text('MEU APLICATIVO'), findsOneWidget);
    expect(find.text('Início & Distribuidoras'), findsOneWidget);
    expect(find.text('Meus Pedidos'), findsOneWidget);
    expect(find.text('Cartão Fidelidade'), findsOneWidget);
  });
}
