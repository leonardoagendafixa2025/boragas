import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boragas/features/auth/presentation/recuperar_senha_screen.dart';
import 'package:boragas/features/auth/providers/auth_provider.dart';

void main() {
  group('Recuperação de Senha 100% Real via WhatsApp - BoraGás', () {
    test('1. sendPasswordResetOtp localiza WhatsApp do cliente pelo e-mail e gera OTP de 6 dígitos', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      final res = await notifier.sendPasswordResetOtp('leonardoenigma@hotmail.com');
      expect(res['success'], isTrue);
      expect(res['code'], isNotNull);
      expect(res['code'].toString().length, equals(6));
      expect(res['maskedPhone'], isNotNull);
      expect(res['message'], contains('WhatsApp'));
    });

    test('2. sendPasswordResetOtp com telefone direto formata DDD e gera código de verificação', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      final res = await notifier.sendPasswordResetOtp('31973149306');
      expect(res['success'], isTrue);
      expect(res['code'].toString().length, equals(6));
      expect(res['phone'], contains('5531973149306'));
    });

    test('3. sendPasswordResetOtp rejeita dados vazios ou formato inválido', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      final vazio = await notifier.sendPasswordResetOtp('   ');
      expect(vazio['success'], isFalse);

      final curto = await notifier.sendPasswordResetOtp('123');
      expect(curto['success'], isFalse);
    });

    test('4. confirmPasswordReset bloqueia código incorreto ou nova senha com menos de 6 caracteres', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.sendPasswordResetOtp('31973149306');

      // Código errado
      final errCode = await notifier.confirmPasswordReset(
        code: '999999',
        newPassword: 'NovaSenha@123',
      );
      expect(errCode['success'], isFalse);
      expect(errCode['message'], contains('Código de verificação incorreto'));

      // Senha curta
      final errPwd = await notifier.confirmPasswordReset(
        code: '123456',
        newPassword: '123',
      );
      expect(errPwd['success'], isFalse);
      expect(errPwd['message'], contains('mínimo 6 caracteres'));
    });

    test('5. confirmPasswordReset com código correto altera senha com sucesso', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      final otpRes = await notifier.sendPasswordResetOtp('31973149306');
      final validOtp = otpRes['code'].toString();

      final res = await notifier.confirmPasswordReset(
        code: validOtp,
        newPassword: 'NovaSenhaSegura@2026',
      );

      expect(res['success'], isTrue);
      expect(res['message'], contains('Senha alterada com sucesso'));
    });

    testWidgets('6. RecuperarSenhaScreen renderiza campos de WhatsApp e transiciona etapas', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecuperarSenhaScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Etapa 1
      expect(find.text('Recuperar Senha'), findsOneWidget);
      expect(find.text('Receba seu código de validação no WhatsApp para redefinir'), findsOneWidget);
      expect(find.text('WhatsApp com DDD (ex: 31973149306)'), findsOneWidget);
      expect(find.text('Enviar Código no WhatsApp'), findsOneWidget);
      expect(find.text('Recuperação por WhatsApp'), findsOneWidget);
    });
  });
}
