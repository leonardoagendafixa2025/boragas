import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../data/mock_database.dart';

final supportTicketsProvider =
    NotifierProvider<SupportTicketsNotifier, List<SupportTicketModel>>(
  SupportTicketsNotifier.new,
);

class SupportTicketsNotifier extends Notifier<List<SupportTicketModel>> {
  @override
  List<SupportTicketModel> build() => List.from(MockDatabase.initialTickets);

  void createTicket({
    required String requesterName,
    required String requesterRole,
    required String category,
    required String subject,
    required String initialMessage,
    String? relatedOrderId,
  }) {
    final newTicket = SupportTicketModel(
      id: 'tkt-${DateTime.now().millisecondsSinceEpoch}',
      ticketNumber: '#SUP-${1000 + (DateTime.now().millisecond * 3) % 9000}',
      requesterName: requesterName,
      requesterRole: requesterRole,
      category: category,
      subject: subject,
      status: TicketStatus.open,
      relatedOrderId: relatedOrderId,
      createdAt: DateTime.now(),
      messages: [
        SupportMessageModel(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          senderName: requesterName,
          senderRole: requesterRole,
          content: initialMessage,
          sentAt: DateTime.now(),
        ),
      ],
    );

    state = [newTicket, ...state];
  }

  void addMessage(
      String ticketId, String content, String senderName, String senderRole) {
    state = state.map((ticket) {
      if (ticket.id == ticketId) {
        final newMsg = SupportMessageModel(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          senderName: senderName,
          senderRole: senderRole,
          content: content,
          sentAt: DateTime.now(),
        );
        return ticket.copyWith(messages: [...ticket.messages, newMsg]);
      }
      return ticket;
    }).toList();
  }
}
