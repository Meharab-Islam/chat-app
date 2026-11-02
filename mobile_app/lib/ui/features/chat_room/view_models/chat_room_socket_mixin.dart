import 'package:flutter/foundation.dart';

import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/chat_repository.dart';

mixin ChatRoomSocketMixin on ChangeNotifier {
  ChatRepository get chatRepository;
  String get conversationId;
  String get currentUserId;
  List<MessageModel> get messagesList;

  bool isDisposed = false;
  bool isPeerTyping = false;

  void onIncomingMessage(MessageModel message) {
    if (isDisposed) return;
    if (!messagesList.any((x) => x.id == message.id)) {
      messagesList.insert(0, message);
      notifyListeners();
    }
    if (message.senderId != currentUserId) {
      chatRepository.markAsRead(conversationId, message.id);
    }
  }

  void onTypingUpdate(bool isTyping) {
    if (!isDisposed) {
      isPeerTyping = isTyping;
      notifyListeners();
    }
  }

  void onMessagesMutated() {
    if (!isDisposed) notifyListeners();
  }

  List<VoidCallback> subscribeSocketEvents() {
    final s = chatRepository.socketService;
    return [
      s.onTypingStart((d) {
        if (d is Map<String, dynamic> &&
            d['chatId'] == conversationId &&
            d['userId'] != currentUserId) {
          onTypingUpdate(true);
        }
      }),
      s.onTypingStop((d) {
        if (d is Map<String, dynamic> &&
            d['chatId'] == conversationId &&
            d['userId'] != currentUserId) {
          onTypingUpdate(false);
        }
      }),
      s.onNewMessage((d) {
        if (d is Map<String, dynamic> &&
            (d['chatId'] ?? d['conversationId']) == conversationId) {
          onIncomingMessage(MessageModel.fromJson(d));
        }
      }),
      s.onMessageDelivered((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId) {
          final msgId = d['messageId']?.toString();
          final idx = messagesList.indexWhere((m) => m.id == msgId);
          if (idx != -1 && messagesList[idx].status != 'read') {
            messagesList[idx] = messagesList[idx].copyWith(status: 'delivered');
            onMessagesMutated();
          }
        }
      }),
      s.onMessageRead((d) {
        if (d is Map<String, dynamic> &&
            d['chatId'] == conversationId &&
            d['readerId'] != currentUserId) {
          bool ch = false;
          for (int i = 0; i < messagesList.length; i++) {
            if (messagesList[i].senderId == currentUserId &&
                messagesList[i].status != 'read') {
              messagesList[i] = messagesList[i].copyWith(status: 'read');
              ch = true;
            }
          }
          if (ch) onMessagesMutated();
        }
      }),
      s.onMessageUnsent((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId) {
          final msgId = d['messageId']?.toString();
          final idx = messagesList.indexWhere((m) => m.id == msgId);
          if (idx != -1) {
            messagesList[idx] = messagesList[idx].copyWith(
              isUnsent: true,
              text: 'This message was unsent',
            );
            onMessagesMutated();
          }
        }
      }),
    ];
  }
}
