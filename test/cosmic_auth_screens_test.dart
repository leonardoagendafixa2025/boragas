import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boragas/features/auth/presentation/bem_vindo_screen.dart';
import 'package:boragas/features/auth/presentation/cadastro_screen.dart';
import 'package:boragas/features/auth/presentation/login_screen.dart';
import 'package:boragas/features/auth/presentation/recuperar_senha_screen.dart';
import 'package:boragas/features/auth/presentation/widgets/auth_shell.dart';
import 'package:boragas/features/auth/presentation/widgets/avatar_picker.dart';
import 'package:boragas/features/auth/presentation/widgets/morph_button.dart';

void main() {
  group('Design Cósmico & Telas de Autenticação - BoraGás', () {
    testWidgets('1. LoginScreen renderiza campos com estilo cósmico e botões demo', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Entrar'), findsWidgets);
      expect(find.text('Peça seu gás de cozinha em poucos toques'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Esqueci minha senha'), findsOneWidget);
      expect(find.byType(MorphButton), findsOneWidget);
      expect(find.byType(RodapeLink), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Cadastre-se')),
        findsOneWidget,
      );
      // Demo chips
      expect(find.text('Acesso Rápido (Demonstração / Testes):'), findsOneWidget);
      expect(find.text('Lojista'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Entregador'), findsOneWidget);
      expect(find.text('Cliente'), findsOneWidget);
    });

    testWidgets('2. CadastroScreen renderiza seleção de avatar, chips de perfil e campos animados', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CadastroScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Criar conta'), findsWidgets);
      expect(find.text('Leva menos de um minuto'), findsOneWidget);
      expect(find.byType(AvatarPicker), findsOneWidget);
      expect(find.text('Tipo de Perfil'), findsOneWidget);
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Distribuidora'), findsOneWidget);
      expect(find.text('Entregador'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('WhatsApp / Telefone'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Aceito os Termos de Uso e a Política de Privacidade'), findsOneWidget);
      expect(find.byType(MorphButton), findsOneWidget);
      expect(find.byType(RodapeLink), findsOneWidget);
    });

    testWidgets('3. RecuperarSenhaScreen renderiza formulário e fluxo de recuperação', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecuperarSenhaScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Esqueceu a senha?'), findsOneWidget);
      expect(find.text('Sem problemas! Enviaremos um link para redefinir'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Enviar link'), findsOneWidget);
    });

    testWidgets('4. BemVindoScreen renderiza chama animada, saudação e CTA dinâmico', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BemVindoScreen(
              nome: 'Maria',
              primeiroAcesso: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bem-vindo de volta,\nMaria!'), findsOneWidget);
      expect(find.text('Que bom ter você por aqui'), findsOneWidget);
      expect(find.text('Tudo pronto para o seu próximo pedido de gás.'), findsOneWidget);
      expect(find.text('Pedir gás agora'), findsOneWidget);
      expect(find.byType(RodapeLink), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Trocar de conta')),
        findsOneWidget,
      );
    });
  });
}
