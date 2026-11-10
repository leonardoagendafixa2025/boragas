enum TicketStatus { open, inProgress, resolved }

class SupportMessageModel {
  final String id;
  final String senderName;
  final String senderRole; // 'customer', 'merchant', 'admin'
  final String content;
  final DateTime sentAt;

  const SupportMessageModel({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.sentAt,
  });
}

class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String requesterName;
  final String requesterRole; // 'customer', 'merchant'
  final String category; // 'Atraso', 'Pagamento/Maquininha', 'Botijão com defeito', 'Comissão'
  final String subject;
  final TicketStatus status;
  final String? relatedOrderId;
  final List<SupportMessageModel> messages;
  final DateTime createdAt;

  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.requesterName,
    required this.requesterRole,
    required this.category,
    required this.subject,
    required this.status,
    this.relatedOrderId,
    required this.messages,
    required this.createdAt,
  });

  SupportTicketModel copyWith({
    String? id,
    String? ticketNumber,
    String? requesterName,
    String? requesterRole,
    String? category,
    String? subject,
    TicketStatus? status,
    String? relatedOrderId,
    List<SupportMessageModel>? messages,
    DateTime? createdAt,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      requesterName: requesterName ?? this.requesterName,
      requesterRole: requesterRole ?? this.requesterRole,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      relatedOrderId: relatedOrderId ?? this.relatedOrderId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
