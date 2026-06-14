class SupportTicket {
  final String id;
  final String userId;
  final String status;
  final DateTime createdAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
