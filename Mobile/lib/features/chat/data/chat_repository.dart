import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../models/conversation.dart';

class ChatRepository {
  final String _baseUrl = AppConfig.baseUrl;

  /// Fetch all conversations for a user
  Future<List<Conversation>> getConversations(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/GetConversations'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => Conversation.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("ChatRepo.getConversations error: $e");
    }
    return [];
  }

  /// Create or get existing conversation
  Future<int?> createConversation({
    required int user1Id,
    required int user2Id,
    int? venueId,
    int? bookingId,
    String context = 'general',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/CreateConversation'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user1_id": user1Id,
          "user2_id": user2Id,
          if (venueId != null) "venue_id": venueId,
          if (bookingId != null) "booking_id": bookingId,
          "context": context,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['conversation_id'];
      }
    } catch (e) {
      debugPrint("ChatRepo.createConversation error: $e");
    }
    return null;
  }

  /// Fetch messages for a conversation
  Future<List<ChatMessage>> getMessages(String conversationId,
      {int page = 1, int pageSize = 50}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/GetMessages'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "conversation_id": conversationId,
          "page": page,
          "page_size": pageSize,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => ChatMessage.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("ChatRepo.getMessages error: $e");
    }
    return [];
  }

  /// Send a message
  Future<bool> sendMessage({
    required int conversationId,
    required int senderId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/SendMessage'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "conversation_id": conversationId,
          "sender_id": senderId,
          "message": message,
          "message_type": messageType,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint("ChatRepo.sendMessage error: $e");
    }
    return false;
  }

  /// Mark messages as read
  Future<void> markMessagesRead(int conversationId, int userId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/MarkMessagesRead'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "conversation_id": conversationId,
          "user_id": userId,
        }),
      );
    } catch (e) {
      debugPrint("ChatRepo.markRead error: $e");
    }
  }

  /// Get total unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/GetUnreadCount'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['count'] ?? 0;
      }
    } catch (e) {
      debugPrint("ChatRepo.unreadCount error: $e");
    }
    return 0;
  }

  /// Get contactable users for new chat
  Future<List<ChatContact>> getContacts(String userId, String userType) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/GetChatContacts'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "user_type": userType}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => ChatContact.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("ChatRepo.getContacts error: $e");
    }
    return [];
  }
}
