import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boragas/core/widgets/change_password_dialog.dart';
import 'package:boragas/features/auth/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Segurança & Alteração de Senha no Perfil (RLS & GoTrue)', () {
    test('1. Bloqueia alteração quando usuário não está autenticado', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.changePassword(
        currentPassword: 'qualquer_senha',
        newPassword: 'nova_senha_123',
        confirmPassword: 'nova_senha_123',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('não autenticado'));
    });

    test('2. Bloqueia se a nova senha tiver menos de 6 caracteres', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      authNotifier.switchDemoRole(UserRole.customer);

      final result = await authNotifier.changePassword(
        currentPassword: '123456',
        newPassword: '123',
        confirmPassword: '123',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('no mínimo 6 caracteres'));
    });

    test('3. Bloqueia se a confirmação de senha não coincidir', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      authNotifier.switchDemoRole(UserRole.customer);

      final result = await authNotifier.changePassword(
        currentPassword: '123456',
        newPassword: 'NovaSenha@2026',
        confirmPassword: 'OutraSenha@2026',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('não confere'));
    });

    test('4. Bloqueia se a nova senha for idêntica à senha atual', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      authNotifier.switchDemoRole(UserRole.customer);

      final result = await authNotifier.changePassword(
        currentPassword: '123456',
        newPassword: '123456',
        confirmPassword: '123456',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('diferente da senha atual'));
    });

    test('5. Bloqueia se a senha atual digitada estiver incorreta', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      authNotifier.switchDemoRole(UserRole.customer);

      final result = await authNotifier.changePassword(
        currentPassword: 'senha_completamente_errada',
        newPassword: 'NovaSenha@2026',
        confirmPassword: 'NovaSenha@2026',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('senha atual digitada está incorreta'));
    });

    test('6. Altera senha com sucesso para Cliente e valida login subsequente', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      // Cadastra um cliente real
      final registered = await authNotifier.registerUser(
        name: 'Roberto Santos',
        email: 'roberto@email.com',
        phone: '(11) 99999-8888',
        password: 'SenhaAntiga@123',
        role: UserRole.customer,
      );
      expect(registered, isTrue);

      // Altera a senha
      final changeResult = await authNotifier.changePassword(
        currentPassword: 'SenhaAntiga@123',
        newPassword: 'SenhaNova@2026',
        confirmPassword: 'SenhaNova@2026',
      );
      expect(changeResult.success, isTrue);
      expect(changeResult.message, contains('com sucesso'));

      // Desconecta da conta
      await authNotifier.logout();
      expect(container.read(authProvider).isAuthenticated, isFalse);

      // Tenta login com a senha antiga -> DEVE FALHAR
      final loginOld = await authNotifier.loginWithEmailPassword('roberto@email.com', 'SenhaAntiga@123');
      expect(loginOld, isFalse);

      // Tenta login com a nova senha -> DEVE TER SUCESSO
      final loginNew = await authNotifier.loginWithEmailPassword('roberto@email.com', 'SenhaNova@2026');
      expect(loginNew, isTrue);
      expect(container.read(authProvider).isAuthenticated, isTrue);
      expect(container.read(authProvider).user?.email, equals('roberto@email.com'));
    });

    test('7. Suporte a alteração de senha para todos os 4 papéis (Customer, Merchant, Courier, Admin)', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      // 1. Lojista
      authNotifier.switchDemoRole(UserRole.merchant);
      final merchChange = await authNotifier.changePassword(
        currentPassword: '123456',
        newPassword: 'NovaSenhaLojista@123',
        confirmPassword: 'NovaSenhaLojista@123',
      );
      expect(merchChange.success, isTrue);

      // 2. Entregador
      authNotifier.switchDemoRole(UserRole.courier);
      final courierChange = await authNotifier.changePassword(
        currentPassword: '123456',
        newPassword: 'NovaSenhaCourier@123',
        confirmPassword: 'NovaSenhaCourier@123',
      );
      expect(courierChange.success, isTrue);

      // 3. Super Admin
      authNotifier.switchDemoRole(UserRole.admin);
      final adminChange = await authNotifier.changePassword(
        currentPassword: '123456',
        newPassword: 'NovaSenhaAdmin@123',
        confirmPassword: 'NovaSenhaAdmin@123',
      );
      expect(adminChange.success, isTrue);
    });

    testWidgets('8. ChangePasswordDialog renderiza campos e validação de formulário', (tester) async {
      final container = ProviderContainer();
      container.read(authProvider.notifier).switchDemoRole(UserRole.customer);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ChangePasswordDialog(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Alterar Senha de Acesso'), findsOneWidget);
      expect(find.text('CLIENTE'), findsOneWidget);
      expect(find.text('Senha Atual'), findsOneWidget);
      expect(find.text('Nova Senha'), findsOneWidget);
      expect(find.text('Confirmar Nova Senha'), findsOneWidget);
      expect(find.byKey(const Key('change_password_submit_btn')), findsOneWidget);

      // Tenta submeter formulário em branco
      await tester.tap(find.byKey(const Key('change_password_submit_btn')));
      await tester.pump();

      expect(find.text('Informe sua senha atual.'), findsOneWidget);
    });
  });
}
