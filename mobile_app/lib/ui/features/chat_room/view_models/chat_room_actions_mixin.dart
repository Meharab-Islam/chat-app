import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/media_service.dart';

mixin ChatRoomActionsMixin {
  ChatRepository get chatRepository;
  MediaService get mediaService;
  String get conversationId;
  String get currentUserId;

  List<VoidCallback> initChatSocketEvents({
    required ValueChanged<bool> onPeerTypingChanged,
    required ValueChanged<MessageModel> onNewMessageReceived,
    required ValueChanged<String> onMessageDelivered,
    required VoidCallback onPeerReadMessages,
    required ValueChanged<String> onMessageUnsent,
  }) {
    final s = chatRepository.socketService;
    return [
      s.onTypingStart((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId && d['userId'] != currentUserId) {
          onPeerTypingChanged(true);
        }
      }),
      s.onTypingStop((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId && d['userId'] != currentUserId) {
          onPeerTypingChanged(false);
        }
      }),
      s.onNewMessage((d) {
        if (d is Map<String, dynamic> && (d['chatId'] ?? d['conversationId']) == conversationId) {
          onNewMessageReceived(MessageModel.fromJson(d));
        }
      }),
      s.onMessageDelivered((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId) {
          final msgId = d['messageId']?.toString();
          if (msgId != null) onMessageDelivered(msgId);
        }
      }),
      s.onMessageRead((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId) {
          if (d['readerId'] != currentUserId) {
            onPeerReadMessages();
          }
        }
      }),
      s.onMessageUnsent((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId) {
          final msgId = d['messageId']?.toString();
          if (msgId != null) onMessageUnsent(msgId);
        }
      }),
    ];
  }

  Future<void> unsend(String messageId, VoidCallback onRefresh) async {
    await chatRepository.unsendMessage(messageId, conversationId);
    onRefresh();
  }

  Future<void> deleteMessageForMe(String messageId, VoidCallback onRefresh) async {
    await chatRepository.deleteForMe(messageId, conversationId);
    onRefresh();
  }

  Future<void> react(String messageId, String emoji, VoidCallback onRefresh) async {
    await chatRepository.reactToMessage(messageId, emoji);
    onRefresh();
  }

  Future<bool> downloadToGallery(MessageModel message) async {
    if (message.mediaUrl == null) return false;
    if (message.mediaType == MessageMediaType.image) {
      return mediaService.saveImageToGallery(message.mediaUrl!);
    } else if (message.mediaType == MessageMediaType.video) {
      return mediaService.saveVideoToGallery(message.mediaUrl!);
    }
    return false;
  }

  Future<void> pickAndSendOtherFiles({String? replyToId, required VoidCallback onRefresh}) async {
    final files = await FilePicker.pickFiles();
    if (files.isNotEmpty) {
      final valid = files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
      if (valid.isNotEmpty) {
        await chatRepository.sendMessage(
          conversationId: conversationId,
          senderId: currentUserId,
          fileAttachments: valid,
          replyToId: replyToId,
        );
        onRefresh();
      }
    }
  }

  Future<void> sendVoice(File audioFile, {String? replyToId, required VoidCallback onRefresh}) async {
    await chatRepository.sendMessage(
      conversationId: conversationId,
      senderId: currentUserId,
      fileAttachment: audioFile,
      replyToId: replyToId,
    );
    onRefresh();
  }
}
