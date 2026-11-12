enum TicketStatus { open, inProgress, resolved }

class SupportMessageModel {
  final String id;
  final String ticketId;
  final String? senderId;
  final String senderName;
  final String senderRole; // 'customer', 'merchant', 'admin'
  final String content;
  final DateTime sentAt;

  const SupportMessageModel({
    required this.id,
    required this.ticketId,
    this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_id': ticketId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'content': content,
        'sent_at': sentAt.toIso8601String(),
      };

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: json['id']?.toString() ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
      ticketId: json['ticket_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString(),
      senderName: json['sender_name']?.toString() ?? 'Usuário',
      senderRole: json['sender_role']?.toString() ?? 'customer',
      content: json['content']?.toString() ?? '',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }
}

class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String requesterId;
  final String requesterName;
  final String? requesterPhone;
  final String? requesterEmail;
  final String requesterRole; // 'customer', 'merchant'
  final String category; // 'Atraso na Entrega', 'Problema com Pagamento / Maquininha', etc.
  final String subject;
  final TicketStatus status;
  final String? relatedOrderId;
  final List<SupportMessageModel> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhone,
    this.requesterEmail,
    required this.requesterRole,
    required this.category,
    required this.subject,
    required this.status,
    this.relatedOrderId,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  SupportTicketModel copyWith({
    String? id,
    String? ticketNumber,
    String? requesterId,
    String? requesterName,
    String? requesterPhone,
    String? requesterEmail,
    String? requesterRole,
    String? category,
    String? subject,
    TicketStatus? status,
    String? relatedOrderId,
    List<SupportMessageModel>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterRole: requesterRole ?? this.requesterRole,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      relatedOrderId: relatedOrderId ?? this.relatedOrderId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_number': ticketNumber,
        'requester_id': requesterId,
        'requester_name': requesterName,
        'requester_phone': requesterPhone,
        'requester_email': requesterEmail,
        'requester_role': requesterRole,
        'category': category,
        'subject': subject,
        'status': status.name,
        'related_order_id': relatedOrderId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'open';
    TicketStatus status = TicketStatus.open;
    if (statusStr == 'in_progress' || statusStr == 'inprogress') {
      status = TicketStatus.inProgress;
    } else if (statusStr == 'resolved') {
      status = TicketStatus.resolved;
    }

    final rawMessages = json['messages'] as List?;
    final messages = rawMessages != null
        ? rawMessages.map((m) => SupportMessageModel.fromJson(Map<String, dynamic>.from(m as Map))).toList()
        : <SupportMessageModel>[];

    return SupportTicketModel(
      id: json['id']?.toString() ?? 'tkt-${DateTime.now().millisecondsSinceEpoch}',
      ticketNumber: json['ticket_number']?.toString() ?? '#SUP-0000',
      requesterId: json['requester_id']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? 'Cliente BoraGás',
      requesterPhone: json['requester_phone']?.toString(),
      requesterEmail: json['requester_email']?.toString(),
      requesterRole: json['requester_role']?.toString() ?? 'customer',
      category: json['category']?.toString() ?? 'Geral',
      subject: json['subject']?.toString() ?? 'Chamado de Suporte',
      status: status,
      relatedOrderId: json['related_order_id']?.toString(),
      messages: messages,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }
}
