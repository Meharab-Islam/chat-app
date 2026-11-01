import 'dart:async';
import '../models/chat_conversation_model.dart';
import '../models/message_model.dart';
import '../services/media_service.dart';
import '../services/storage_service.dart';

class ChatStoreManager {
  final MediaService mediaService;
  final StorageService storageService;
  final String currentUserId;

  final List<ChatConversationModel> conversations = [];
  final Map<String, List<MessageModel>> messagesByConv = {};
  final streamController = StreamController<List<ChatConversationModel>>.broadcast();

  ChatStoreManager({
    required this.mediaService,
    required this.storageService,
    required this.currentUserId,
  });

  void addMessageToStore(String conversationId, MessageModel message) {
    final list = messagesByConv.putIfAbsent(conversationId, () => []);
    final existingIdx = list.indexWhere((m) => m.id == message.id);
    if (existingIdx != -1) {
      list[existingIdx] = message;
    } else {
      list.insert(0, message);
    }

    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final updated = conversations[idx].copyWith(
        lastMessage: message,
        updatedAt: message.timestamp,
      );
      conversations.removeAt(idx);
      conversations.insert(0, updated);
      streamController.add(conversations);
    }
  }

  void updateMessageStatus(String? convId, String msgId, String status) {
    if (convId == null) return;
    final list = messagesByConv[convId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.id == msgId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(status: status);
      }
    }
    streamController.add(conversations);
  }

  void markMessagesRead(String? convId, String? lastReadId) {
    if (convId == null) return;
    final list = messagesByConv[convId];
    if (list != null) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].senderId != currentUserId) {
          list[i] = list[i].copyWith(status: 'read');
        }
      }
    }
    final idx = conversations.indexWhere((c) => c.id == convId);
    if (idx != -1) {
      conversations[idx] = conversations[idx].copyWith(unreadCount: 0);
      streamController.add(conversations);
    }
  }

  void markMessageUnsent(String? convId, String msgId) {
    if (convId == null) return;
    final list = messagesByConv[convId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.id == msgId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isUnsent: true, text: 'This message was unsent');
      }
    }
    streamController.add(conversations);
  }

  void setPeerOnlineStatus(String? userId, bool isOnline) {
    if (userId == null) return;
    bool changed = false;
    for (int i = 0; i < conversations.length; i++) {
      if (conversations[i].peerUser.id == userId) {
        conversations[i] = conversations[i].copyWith(
          peerUser: conversations[i].peerUser.copyWith(isOnline: isOnline),
        );
        changed = true;
      }
    }
    if (changed) streamController.add(conversations);
  }

  void checkAutoSave(MessageModel message) {
    if (storageService.getAutoSaveMedia() && message.mediaUrl != null) {
      if (message.mediaType == MessageMediaType.image) {
        mediaService.saveImageToGallery(message.mediaUrl!);
      } else if (message.mediaType == MessageMediaType.video) {
        mediaService.saveVideoToGallery(message.mediaUrl!);
      }
    }
  }

  String? getConversationTitle(String conversationId) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      return conversations[idx].peerUser.name;
    }
    return null;
  }
}

