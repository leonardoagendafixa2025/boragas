import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/features/customer/presentation/subscription_club_screen.dart';
import 'package:boragas/features/admin/presentation/widgets/sales_chart_widget.dart';
import 'package:boragas/features/courier/presentation/courier_screen.dart';

void main() {
  testWidgets('Clube BoraGás screen renders benefits and plan options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SubscriptionClubScreen(),
        ),
      ),
    );

    // Verify Title and Hero elements
    expect(find.text('Clube BoraGás'), findsOneWidget);
    expect(find.text('Abastecimento Automático BoraGás'), findsOneWidget);
    expect(find.text('Botijão GLP 13kg (Troca)'), findsOneWidget);
    expect(find.text('Ativar Assinatura com 5% OFF'), findsOneWidget);
  });

  testWidgets('SalesChartWidget renders 7-day evolution bars and peak hour insights', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SalesChartWidget(),
        ),
      ),
    );

    expect(find.text('CURVA DE VENDAS & COMISSÕES'), findsOneWidget);
    expect(find.text('Evolução dos Últimos 7 Dias'), findsOneWidget);
    expect(find.text('GLP 13kg (68%)'), findsOneWidget);
    expect(find.text('Horários de Maior Demanda'), findsOneWidget);
    expect(find.text('7D'), findsOneWidget);
  });

  testWidgets('CourierScreen renders active deliveries and driver wallet header', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CourierScreen(),
        ),
      ),
    );

    expect(find.text('BoraGás Entregador'), findsOneWidget);
    expect(find.text('Marcos Oliveira'), findsOneWidget);
    expect(find.text('Ganhos Hoje (Taxas)'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
  });
}
