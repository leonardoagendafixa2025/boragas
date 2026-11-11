import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/core/widgets/slide_to_action.dart';
import 'package:boragas/core/widgets/floating_order_tracker.dart';
import 'package:boragas/core/widgets/shimmer_loading.dart';
import 'package:boragas/core/widgets/interactive_scale_button.dart';
import 'package:boragas/core/models/order_model.dart';
import 'package:boragas/data/mock_database.dart';
import 'package:boragas/features/customer/providers/customer_providers.dart';

class _TestOrdersNotifier extends OrdersNotifier {
  final List<OrderModel> _initial;
  _TestOrdersNotifier(this._initial);

  @override
  List<OrderModel> build() => _initial;
}

void main() {
  testWidgets('SlideToActionWidget renders label and responds to drag gesture', (WidgetTester tester) async {
    bool isCompleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 320,
              child: SlideToActionWidget(
                label: 'Deslize para Confirmar',
                onCompleted: () {
                  isCompleted = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Deslize para Confirmar'), findsOneWidget);
    expect(find.byType(SlideToActionWidget), findsOneWidget);
    expect(isCompleted, isFalse);

    // Simulate drag across the widget with startGesture and up
    final thumbFinder = find.byKey(const Key('slide-action-thumb'));
    final gesture = await tester.startGesture(tester.getCenter(thumbFinder));
    await gesture.moveBy(const Offset(280, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(isCompleted, isTrue);
  });

  testWidgets('FloatingOrderTracker renders active order live activity capsule', (WidgetTester tester) async {
    final sampleOrder = MockDatabase.sampleOrdersForTesting.first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(() => _TestOrdersNotifier([sampleOrder])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FloatingOrderTracker(),
          ),
        ),
      ),
    );

    // Active order from mock database has outForDelivery or preparing
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Rastrear'), findsOneWidget);
  });

  testWidgets('StoreCardSkeleton renders with animated Shimmer shader', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StoreCardSkeleton(),
        ),
      ),
    );

    expect(find.byType(Shimmer), findsOneWidget);
    expect(find.byType(StoreCardSkeleton), findsOneWidget);
  });

  testWidgets('InteractiveScaleButton renders child and handles press down', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveScaleButton(
            onTap: () => tapped = true,
            child: const Text('Botão com Física'),
          ),
        ),
      ),
    );

    expect(find.text('Botão com Física'), findsOneWidget);
    await tester.tap(find.text('Botão com Física'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
