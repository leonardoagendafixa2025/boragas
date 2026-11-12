import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boragas/core/models/support_ticket_model.dart';
import 'package:boragas/features/admin/presentation/admin_support_screen.dart';
import 'package:boragas/features/auth/providers/auth_provider.dart';
import 'package:boragas/features/support/presentation/new_ticket_dialog.dart';
import 'package:boragas/features/support/presentation/ticket_detail_screen.dart';
import 'package:boragas/features/support/providers/support_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Suporte & Helpdesk Real - BoraGás', () {
    test('1. Criação de chamado com dados reais do cliente conectado (sem dados mock de terceiros)', () async {
      final container = ProviderContainer();

      // Loga como cliente real (ex: Leonardo Fernandes)
      await container.read(authProvider.notifier).registerUser(
            name: 'Leonardo Fernandes',
            email: 'leonardoenigma@hotmail.com',
            phone: '(31) 97314-9306',
            password: 'SenhaSegura@2026',
            role: UserRole.customer,
          );

      final authUser = container.read(authProvider).user;
      expect(authUser?.name, equals('Leonardo Fernandes'));
      expect(authUser?.email, equals('leonardoenigma@hotmail.com'));
      expect(authUser?.phone, equals('(31) 97314-9306'));

      // Abre novo chamado
      final ticket = await container.read(supportTicketsProvider.notifier).createTicket(
            category: 'Atraso na Entrega',
            subject: 'Pedido demorando para chegar',
            initialMessage: 'Olá, meu pedido ainda não saiu para entrega.',
          );

      expect(ticket.ticketNumber, startsWith('#SUP-'));
      expect(ticket.requesterName, equals('Leonardo Fernandes'));
      expect(ticket.requesterEmail, equals('leonardoenigma@hotmail.com'));
      expect(ticket.requesterPhone, equals('(31) 97314-9306'));
      expect(ticket.status, equals(TicketStatus.open));
      expect(ticket.messages.length, equals(1));
      expect(ticket.messages.first.senderName, equals('Leonardo Fernandes'));
      expect(ticket.messages.first.content, contains('ainda não saiu para entrega'));
    });

    test('2. Adição de mensagens e resposta bidirecional do Admin', () async {
      final container = ProviderContainer();

      // Cliente abre o chamado
      await container.read(authProvider.notifier).registerUser(
            name: 'Leonardo Fernandes',
            email: 'leonardo@email.com',
            phone: '(31) 97314-9306',
            password: 'SenhaSegura@2026',
            role: UserRole.customer,
          );

      final ticket = await container.read(supportTicketsProvider.notifier).createTicket(
            category: 'Problema com Pagamento / Maquininha',
            subject: 'Maquininha deu erro',
            initialMessage: 'O entregador tentou passar o cartão mas falhou.',
          );

      // Simula Admin respondendo ao chamado
      container.read(authProvider.notifier).switchDemoRole(UserRole.admin);

      await container.read(supportTicketsProvider.notifier).addMessage(
            ticketId: ticket.id,
            content: 'Já estamos verificando com a distribuidora. Foi gerado estorno.',
          );

      final updatedTickets = container.read(supportTicketsProvider);
      final currentTicket = updatedTickets.firstWhere((t) => t.id == ticket.id);

      expect(currentTicket.messages.length, equals(2));
      // Admin mudou status para em atendimento
      expect(currentTicket.status, equals(TicketStatus.inProgress));
      expect(currentTicket.messages.last.senderName, contains('Suporte Oficial'));
      expect(currentTicket.messages.last.senderRole, equals('admin'));

      // Atualiza status para resolvido
      await container.read(supportTicketsProvider.notifier).updateTicketStatus(ticket.id, TicketStatus.resolved);
      final resolvedTicket = container.read(supportTicketsProvider).firstWhere((t) => t.id == ticket.id);
      expect(resolvedTicket.status, equals(TicketStatus.resolved));
    });

    testWidgets('3. NewTicketDialog exibe o nome real do usuário conectado e valida campos', (tester) async {
      final container = ProviderContainer();
      await container.read(authProvider.notifier).registerUser(
            name: 'Leonardo Fernandes',
            email: 'leonardo@email.com',
            phone: '(31) 97314-9306',
            password: 'SenhaSegura@2026',
            role: UserRole.customer,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: NewTicketDialog(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verifica que exibe o nome real do cliente e NÃO Carlos Eduardo
      expect(find.text('Leonardo Fernandes'), findsOneWidget);
      expect(find.text('(31) 97314-9306'), findsOneWidget);
      expect(find.text('Carlos Eduardo Silva'), findsNothing);

      // Tenta submeter sem preencher assunto
      await tester.tap(find.text('Enviar Chamado'));
      await tester.pump();

      expect(find.text('Informe o assunto.'), findsOneWidget);
    });

    testWidgets('4. TicketDetailScreen renderiza mensagens reais e permite resposta', (tester) async {
      final container = ProviderContainer();
      await container.read(authProvider.notifier).registerUser(
            name: 'Leonardo Fernandes',
            email: 'leonardo@email.com',
            phone: '(31) 97314-9306',
            password: 'SenhaSegura@2026',
            role: UserRole.customer,
          );

      final ticket = await container.read(supportTicketsProvider.notifier).createTicket(
            category: 'Atraso na Entrega',
            subject: 'Cadê meu botijão?',
            initialMessage: 'Já se passaram 40 minutos.',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: TicketDetailScreen(ticketId: ticket.id),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(ticket.ticketNumber), findsOneWidget);
      expect(find.text('Cadê meu botijão?'), findsOneWidget);
      expect(find.text('Leonardo Fernandes'), findsOneWidget);
      expect(find.text('Já se passaram 40 minutos.'), findsOneWidget);
      expect(find.text('Carlos Eduardo Silva'), findsNothing);
    });

    testWidgets('5. AdminSupportScreen renderiza KPIs e lista de chamados', (tester) async {
      final container = ProviderContainer();
      container.read(authProvider.notifier).switchDemoRole(UserRole.admin);

      await container.read(supportTicketsProvider.notifier).createTicket(
            category: 'Dúvidas sobre o Clube BoraGás',
            subject: 'Dúvida desconto 5%',
            initialMessage: 'Como funciona o desconto na recarga?',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AdminSupportScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Helpdesk & Suporte'), findsOneWidget);
      expect(find.text('Baileys Hub'), findsOneWidget);
      expect(find.text('Total Chamados'), findsOneWidget);
      expect(find.text('Dúvida desconto 5%'), findsWidgets);
    });
  });
}
