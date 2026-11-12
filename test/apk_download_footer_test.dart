import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/core/services/apk_download_service.dart';
import 'package:boragas/features/customer/presentation/widgets/app_footer.dart';
import 'package:boragas/features/customer/presentation/widgets/customer_drawer.dart';

void main() {
  group('Opção de Baixar APK no Rodapé do App & Menu - BoraGás', () {
    test('1. ApkDownloadService possui URLs e metadados oficiais configurados', () {
      expect(ApkDownloadService.apkDownloadUrl, contains('BoraGas-release.apk'));
      expect(ApkDownloadService.apkDirectUrl, contains('BoraGas-release.apk'));
      expect(ApkDownloadService.apkVersion, contains('1.0.0'));
      expect(ApkDownloadService.apkSize, isNotEmpty);
    });

    testWidgets('2. AppFooter renderiza card destacado de download do APK e links institucionais',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AppFooter(),
              ),
            ),
          ),
        ),
      );

      // Card de Download APK
      expect(find.text('APK OFICIAL ANDROID'), findsOneWidget);
      expect(find.text('Instale o App BoraGás no seu Celular'), findsOneWidget);
      expect(find.text('Baixar APK Oficial para Android'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);

      // Badges
      expect(find.text('100% Seguro'), findsOneWidget);
      expect(find.text('Entrega Rápida'), findsOneWidget);
      expect(find.text('Push Nativo'), findsOneWidget);

      // Links Rápidos no rodapé
      expect(find.text('Baixar APK'), findsOneWidget);
      expect(find.text('Suporte & Ajuda'), findsOneWidget);
      expect(find.text('Indique & Ganhe'), findsOneWidget);
      expect(find.text('Clube BoraGás'), findsOneWidget);
      expect(find.text('Meus Pedidos'), findsOneWidget);

      // Copyright & CNPJ
      expect(find.textContaining('CNPJ 52.891.432/0001-90'), findsOneWidget);
    });

    testWidgets('3. CustomerDrawer renderiza opção de download no menu e no rodapé do drawer',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              drawer: CustomerDrawer(),
              body: Text('Home'),
            ),
          ),
        ),
      );

      // Abre o drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Botão rápido no rodapé fixo do drawer
      expect(find.text('Baixar APK Android (v1.0.0)'), findsOneWidget);

      // Rola a lista interna até o item do menu
      await tester.scrollUntilVisible(
        find.text('Baixar App Android (APK)'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Opção no menu
      expect(find.text('Baixar App Android (APK)'), findsOneWidget);
      expect(find.text('OFICIAL'), findsOneWidget);
    });
  });
}
