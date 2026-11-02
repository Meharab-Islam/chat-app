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
    required List<MessageModel> messages,
    required VoidCallback notify,
    required ValueChanged<bool> onPeerTyping,
    required ValueChanged<MessageModel> onNewMessage,
  }) {
    final s = chatRepository.socketService;
    return [
      s.onTypingStart((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId && d['userId'] != currentUserId) {
          onPeerTyping(true);
        }
      }),
      s.onTypingStop((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId && d['userId'] != currentUserId) {
          onPeerTyping(false);
        }
      }),
      s.onNewMessage((d) {
        if (d is Map<String, dynamic> && (d['chatId'] ?? d['conversationId']) == conversationId) {
          onNewMessage(MessageModel.fromJson(d));
        }
      }),
      s.onMessageDelivered((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId) {
          final msgId = d['messageId']?.toString();
          final idx = messages.indexWhere((m) => m.id == msgId);
          if (idx != -1 && messages[idx].status != 'read') {
            messages[idx] = messages[idx].copyWith(status: 'delivered');
            notify();
          }
        }
      }),
      s.onMessageRead((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId && d['readerId'] != currentUserId) {
          bool ch = false;
          for (int i = 0; i < messages.length; i++) {
            if (messages[i].senderId == currentUserId && messages[i].status != 'read') {
              messages[i] = messages[i].copyWith(status: 'read');
              ch = true;
            }
          }
          if (ch) notify();
        }
      }),
      s.onMessageUnsent((d) {
        if (d is Map<String, dynamic> && d['chatId'] == conversationId) {
          final msgId = d['messageId']?.toString();
          final idx = messages.indexWhere((m) => m.id == msgId);
          if (idx != -1) {
            messages[idx] = messages[idx].copyWith(isUnsent: true, text: 'This message was unsent');
            notify();
          }
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

  Future<List<File>> pickMixedMediaFiles() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp4', 'mov', 'mkv', 'webm', '3gp', 'avi',
          'mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac',
          'jpg', 'jpeg', 'png', 'webp', 'gif',
        ],
      );
      if (res.isNotEmpty) {
        return res.where((f) => f.path != null).map((f) => File(f.path!)).toList();
      }
    } catch (e) {
      debugPrint('Error picking mixed media: $e');
    }
    return [];
  }

  Future<List<File>> pickAudioFiles() async {
    try {
      final res = await FilePicker.pickFiles(type: FileType.audio);
      if (res.isNotEmpty) {
        return res.where((f) => f.path != null).map((f) => File(f.path!)).toList();
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
    }
    return [];
  }
}
