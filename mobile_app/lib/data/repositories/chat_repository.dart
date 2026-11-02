import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/chat_conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/chat_api_service.dart';
import '../services/media_service.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import 'chat_store_manager.dart';

class ChatRepository {
  final ApiClient apiClient;
  final SocketService socketService;
  final MediaService mediaService;
  final StorageService storageService;
  String currentUserId;
  String? activeConversationId;
  late final ChatStoreManager _store;
  late final ChatApiService _api;

  ChatRepository({
    required this.apiClient,
    required this.socketService,
    required this.mediaService,
    required this.storageService,
    required this.currentUserId,
  }) {
    _api = ChatApiService(apiClient: apiClient);
    _store = ChatStoreManager(
      mediaService: mediaService,
      storageService: storageService,
      currentUserId: currentUserId,
    );
    _initSocketListeners();
    loadConversations();
  }

  void updateCurrentUser(String userId) {
    currentUserId = userId;
    _store.updateCurrentUserId(userId);
    loadConversations();
  }

  void clearStore() {
    currentUserId = '';
    _store.clearStore();
  }

  Stream<List<ChatConversationModel>> get conversationsStream =>
      _store.streamController.stream;
  List<ChatConversationModel> get conversations =>
      List.unmodifiable(_store.conversations);

  void _initSocketListeners() {
    socketService.onNewMessage((data) {
      if (data is Map<String, dynamic>) {
        final msg = MessageModel.fromJson(data);
        _store.addMessageToStore(msg.conversationId, msg);
        _store.checkAutoSave(msg);
        _notifyIncomingMessage(msg);
        if (!_store.conversations.any((c) => c.id == msg.conversationId)) {
          loadConversations();
        }
      }
    });
    socketService.onMessageDelivered((data) {
      if (data is Map<String, dynamic>) {
        _store.updateMessageStatus(
          data['chatId'],
          data['messageId'],
          'delivered',
        );
      }
    });
    socketService.onMessageRead((data) {
      if (data is Map<String, dynamic>) {
        _store.markMessagesRead(data['chatId'], data['lastReadMessageId']);
      }
    });
    socketService.onMessageUnsent((data) {
      if (data is Map<String, dynamic>) {
        _store.markMessageUnsent(data['chatId'], data['messageId']);
      }
    });
    socketService.onUserOnline(
      (data) => _store.setPeerOnlineStatus(data['userId'], true),
    );
    socketService.onUserOffline(
      (data) => _store.setPeerOnlineStatus(data['userId'], false),
    );
  }

  Future<void> loadConversations() async {
    try {
      final list = await _api.fetchConversations();
      _store.conversations.clear();
      _store.conversations.addAll(list);
      _store.streamController.add(_store.conversations);
      _store.saveConversationsToDisk();
    } catch (e) {
      debugPrint('Failed to load chats: $e');
    }
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    try {
      final list = await _api.fetchMessages(conversationId);
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _store.messagesByConv[conversationId] = list;
      _store.saveMessagesToDisk(conversationId);
      return list;
    } catch (e) {
      debugPrint('Failed to fetch messages for $conversationId: $e');
    }
    return getMessages(conversationId);
  }

  List<MessageModel> getMessages(String conversationId) =>
      List.unmodifiable(_store.getCachedMessagesFor(conversationId));

  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String senderId,
    String text = '',
    List<File> fileAttachments = const [],
    File? fileAttachment,
    String? replyToId,
  }) async {
    try {
      final allFiles = <File>[...fileAttachments, ?fileAttachment];
      final message = await _api.sendMessage(
        conversationId: conversationId,
        text: text,
        files: allFiles,
        replyToId: replyToId,
      );
      if (message != null) {
        _store.addMessageToStore(conversationId, message);
        if (!_store.conversations.any((c) => c.id == conversationId)) {
          loadConversations();
        }
        return message;
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
    return null;
  }

  Future<void> deleteChat(String conversationId) async {
    try {
      await _api.deleteChat(conversationId);
      _store.conversations.removeWhere((c) => c.id == conversationId);
      _store.messagesByConv.remove(conversationId);
      _store.streamController.add(_store.conversations);
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }

  Future<void> markChatAsRead(
    String conversationId, [
    String? lastReadMessageId,
  ]) async {
    try {
      markAsRead(conversationId, lastReadMessageId);
      await _api.markChatAsRead(conversationId, lastReadMessageId);
    } catch (e) {
      debugPrint('Error marking chat read: $e');
    }
  }

  Future<List<UserModel>> searchUsers(String query) => _api.searchUsers(query);

  Future<ChatConversationModel?> createDirectChat(String recipientId) =>
      _api.createDirectChat(recipientId);

  Future<ChatConversationModel?> createGroupChat(
    String name,
    List<String> memberIds,
  ) async {
    final chat = await _api.createGroupChat(name, memberIds);
    if (chat != null) await loadConversations();
    return chat;
  }

  Future<ChatConversationModel?> updateGroup(
    String chatId, {
    String? name,
    File? avatarFile,
  }) async {
    final chat = await _api.updateGroup(
      chatId,
      name: name,
      avatarFile: avatarFile,
    );
    if (chat != null) await loadConversations();
    return chat;
  }

  Future<List<MessageModel>> searchMessagesInChat(
    String chatId,
    String query,
  ) => _api.searchMessagesInChat(chatId, query);

  Future<void> forwardMessage({
    MessageModel? originalMessage,
    String? messageId,
    required List<String> targetConversationIds,
    String? currentUserId,
    String? senderDisplayName,
    String? text,
  }) async {
    final id = messageId ?? originalMessage?.id ?? '';
    if (id.isEmpty) return;
    try {
      await _api.forwardMessage(id, targetConversationIds, text);
      await loadConversations();
    } catch (e) {
      debugPrint('Error forward: $e');
    }
  }

  Future<void> unsendMessage(String messageId, String conversationId) async {
    try {
      await _api.unsendMessage(messageId);
      _store.markMessageUnsent(conversationId, messageId);
    } catch (e) {
      debugPrint('Error unsend: $e');
    }
  }

  Future<void> deleteForMe(String messageId, String conversationId) async {
    try {
      await _api.deleteForMe(messageId);
      _store.messagesByConv[conversationId]?.removeWhere(
        (m) => m.id == messageId,
      );
      _store.streamController.add(_store.conversations);
    } catch (e) {
      debugPrint('Error delete for me: $e');
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) => _api
      .reactToMessage(messageId, emoji)
      .catchError((e) => debugPrint('Error reacting: $e'));

  void markAsRead(String conversationId, [String? lastReadMessageId]) {
    final list = _store.messagesByConv[conversationId];
    final lastMsgId =
        lastReadMessageId ?? (list?.isNotEmpty == true ? list!.last.id : '');
    if (lastMsgId.isNotEmpty) {
      socketService.emitMessageRead(conversationId, lastMsgId);
    }
    _store.markMessagesRead(conversationId, lastMsgId);
  }

  void _notifyIncomingMessage(MessageModel msg) {
    if (msg.senderId == currentUserId ||
        activeConversationId == msg.conversationId) {
      return;
    }
    final title =
        _store.getConversationTitle(msg.conversationId) ?? 'New Message';
    final body = msg.text.isNotEmpty
        ? msg.text
        : (msg.mediaType == MessageMediaType.image
              ? 'Sent a photo'
              : 'Sent an attachment');
    final imageUrl = msg.mediaType == MessageMediaType.image
        ? msg.mediaUrl
        : null;
    NotificationService.instance.showChatNotification(
      id: msg.conversationId.hashCode.abs(),
      title: title,
      body: body,
      chatId: msg.conversationId,
      imageUrl: imageUrl,
    );
  }
}
