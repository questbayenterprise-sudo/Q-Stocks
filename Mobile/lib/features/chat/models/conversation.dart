class Conversation {
  final int id;
  final int otherUserId;
  final String otherUserName;
  final String venueName;
  final String context;
  final String lastMessage;
  final String lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.venueName,
    required this.context,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? 0,
      otherUserId: json['other_user_id'] ?? 0,
      otherUserName: json['other_user_name'] ?? '',
      venueName: json['venue_name'] ?? '',
      context: json['context'] ?? 'general',
      lastMessage: json['last_message'] ?? '',
      lastMessageAt: json['last_message_at'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String message;
  final String messageType;
  final bool isRead;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      conversationId: json['conversation_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ChatContact {
  final int id;
  final String username;
  final String userType;

  ChatContact({
    required this.id,
    required this.username,
    required this.userType,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      userType: json['user_type'] ?? '',
    );
  }
}
