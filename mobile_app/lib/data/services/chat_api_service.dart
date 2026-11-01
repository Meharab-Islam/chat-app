import 'dart:io';
import '../models/chat_conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class ChatApiService {
  final ApiClient apiClient;

  ChatApiService({required this.apiClient});

  Future<List<ChatConversationModel>> fetchConversations() async {
    final data = await apiClient.get('/chats');
    if (data is List) {
      return data
          .map((item) => ChatConversationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    final data = await apiClient.get('/messages/$conversationId');
    if (data is List) {
      return data
          .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<MessageModel?> sendMessage({
    required String conversationId,
    String text = '',
    List<File> files = const [],
    String? replyToId,
  }) async {
    dynamic response;
    final fields = <String, String>{
      'chatId': conversationId,
      if (text.isNotEmpty) 'text': text,
      if (replyToId != null && replyToId.isNotEmpty) 'replyToId': replyToId,
    };

    if (files.isNotEmpty) {
      response = await apiClient.postMultipart(
        endpoint: '/messages',
        fields: fields,
        files: files,
        fileFieldName: 'files',
      );
    } else {
      response = await apiClient.post('/messages', fields);
    }

    if (response is Map<String, dynamic>) {
      return MessageModel.fromJson(response);
    }
    return null;
  }

  Future<void> deleteChat(String chatId) async {
    await apiClient.delete('/chats/$chatId');
  }

  Future<void> markChatAsRead(String chatId, [String? lastReadMessageId]) async {
    await apiClient.put('/messages/$chatId/read', {
      'lastReadMessageId': ?lastReadMessageId,
    });
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final data = await apiClient.get('/users/search?q=${Uri.encodeComponent(query)}');
    if (data is List) {
      return data
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ChatConversationModel?> createDirectChat(String recipientId) async {
    final data = await apiClient.post('/chats/direct', {'recipientId': recipientId});
    if (data is Map<String, dynamic>) {
      return ChatConversationModel.fromJson(data);
    }
    return null;
  }

  Future<ChatConversationModel?> createGroupChat(String name, List<String> memberIds) async {
    final data = await apiClient.post('/chats/group', {'name': name, 'memberIds': memberIds});
    if (data is Map<String, dynamic>) {
      return ChatConversationModel.fromJson(data);
    }
    return null;
  }

  Future<List<MessageModel>> searchMessagesInChat(String chatId, String query) async {
    final data = await apiClient.get('/messages/$chatId/search?q=${Uri.encodeComponent(query)}');
    if (data is List) {
      return data
          .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> forwardMessage(String messageId, List<String> targetChatIds, [String? text]) async {
    await apiClient.post('/messages/forward', {
      'messageId': messageId,
      'targetChatIds': targetChatIds,
      if (text != null && text.isNotEmpty) 'text': text,
    });
  }

  Future<void> unsendMessage(String messageId) async {
    await apiClient.delete('/messages/$messageId/unsend');
  }

  Future<void> deleteForMe(String messageId) async {
    await apiClient.delete('/messages/$messageId/delete-for-me');
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    await apiClient.post('/messages/$messageId/react', {'emoji': emoji});
  }
}
