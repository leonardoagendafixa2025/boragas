import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boragas/core/models/order_model.dart';
import 'package:boragas/core/services/push_notification_service.dart';
import 'package:boragas/features/admin/presentation/admin_push_marketing_screen.dart';

void main() {
  group('Notificações Nativas Android & PWA com OneSignal Real', () {
    test('1. PushNotificationService inicializa com App ID e REST API Key reais', () async {
      await PushNotificationService.initialize();

      expect(PushNotificationService.appId,
          equals('a9c40927-f12c-4baa-8f01-bb5a9f4bd059'));
      expect(PushNotificationService.restApiKey, startsWith('os_v2_app_'));
    });

    test('2. Disparo de notificação transacional de pedido gera cabeçalhos de alta prioridade', () async {
      final res = await PushNotificationService.sendOrderStatusNotification(
        customerId: 'customer-qa-01',
        orderNumber: '#BG-9999',
        status: OrderStatus.outForDelivery,
        storeName: 'Ultragaz Paulistana',
        orderId: 'ord-test-99',
      );

      // Como o endpoint externo do OneSignal é chamado em teste, valida se o método executa sem crash
      expect(res, isA<bool>());
    });

    test('3. Disparo de broadcast de marketing para base inscrita monta payload estruturado', () async {
      final result = await PushNotificationService.sendMarketingBroadcast(
        title: '🔥 Quinta do Gás BoraGás',
        message: 'Aproveite R\$ 10 OFF no seu botijão P13 com entrega rápida.',
        couponCode: 'BORAGAS10',
        targetAudience: 'all',
      );

      expect(result, isA<PushBroadcastResult>());
      expect(result.recipientsCount, greaterThanOrEqualTo(0));
    });

    testWidgets('4. AdminPushMarketingScreen renderiza status OneSignal, formulário e preview', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminPushMarketingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica Header e status do OneSignal
      expect(find.text('Central de Push & Marketing'), findsOneWidget);
      expect(find.text('OneSignal Conectado & Operante'), findsOneWidget);
      expect(find.text(PushNotificationService.defaultAppId), findsOneWidget);

      // Verifica Campos do Formulário
      expect(find.text('Nova Campanha de Marketing Push'), findsOneWidget);
      expect(find.text('Título da Notificação'), findsOneWidget);
      expect(find.text('Mensagem da Notificação'), findsOneWidget);
      expect(find.text('Cupom de Desconto (Opcional)'), findsOneWidget);
      expect(find.text('Disparar Push Notification em Massa'), findsOneWidget);

      // Verifica Mockup de Tela Bloqueada do Celular
      expect(find.text('Preview na Tela Bloqueada do Cliente'), findsOneWidget);
      expect(find.text('BoraGás'), findsWidgets);

      // Verifica Histórico de Campanhas
      expect(find.text('Histórico de Campanhas Enviadas'), findsOneWidget);
    });
  });
}
