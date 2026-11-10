import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/core/widgets/boragas_logo.dart';
import 'package:boragas/core/widgets/status_badge.dart';

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
}
