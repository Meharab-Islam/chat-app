import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/media_service.dart';
import '../../../../data/services/video_thumbnail_cache.dart';

mixin ChatRoomActionsMixin {
  ChatRepository get chatRepository;
  MediaService get mediaService;
  String get conversationId;
  String get currentUserId;
  MessageModel? get replyingTo;
  void clearReplyingTo();
  void reloadMessages();
  void setDownloading(bool downloading);

  Future<bool> requestGalleryPermissions() async {
    try {
      if (Platform.isAndroid) {
        await [
          Permission.photos,
          Permission.videos,
          Permission.storage,
        ].request();
      } else if (Platform.isIOS) {
        await Permission.photos.request();
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
    return true;
  }

  Future<List<File>> pickGalleryMedia() async {
    await requestGalleryPermissions();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultipleMedia();
      if (picked.isNotEmpty) {
        return picked.map((x) => File(x.path)).toList();
      }
    } catch (e) {
      debugPrint('Error picking gallery media: $e');
      try {
        final single = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (single != null) return [File(single.path)];
      } catch (e2) {
        debugPrint('Fallback pickImage failed: $e2');
      }
    }
    return [];
  }

  Future<List<File>> pickAudioFiles() async {
    try {
      if (Platform.isAndroid) {
        await [Permission.audio, Permission.storage].request();
      }
      final res = await FilePicker.pickFiles(type: FileType.audio);
      if (res.isNotEmpty) {
        return res
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
    }
    return [];
  }

  MessageMediaType resolveMediaType(List<File> files) {
    final hasVideo = files.any((f) {
      final l = f.path.toLowerCase();
      return l.endsWith('.mp4') ||
          l.endsWith('.mov') ||
          l.endsWith('.mkv') ||
          l.endsWith('.webm');
    });
    if (hasVideo) return MessageMediaType.video;
    final hasAudio = files.any((f) {
      final l = f.path.toLowerCase();
      return l.endsWith('.mp3') ||
          l.endsWith('.wav') ||
          l.endsWith('.m4a') ||
          l.endsWith('.aac') ||
          l.endsWith('.ogg') ||
          l.endsWith('.opus') ||
          l.endsWith('.flac');
    });
    return hasAudio ? MessageMediaType.audio : MessageMediaType.image;
  }

  MessageModel createOptimisticMediaMessage({
    required String tempId,
    required List<File> files,
    required String caption,
  }) {
    return MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      text: caption.trim(),
      status: 'sending',
      timestamp: DateTime.now(),
      mediaType: resolveMediaType(files),
      attachmentUrls: files.map((f) => f.path).toList(),
      mediaUrl: files.first.path,
    );
  }

  Future<MessageModel?> dispatchMediaMessage({
    required List<File> files,
    required String caption,
    String? replyToId,
  }) async {
    final sMsg = await chatRepository.sendMessage(
      conversationId: conversationId,
      senderId: currentUserId,
      text: caption.trim(),
      fileAttachments: files,
      replyToId: replyToId,
    );
    if (sMsg != null && files.isNotEmpty) {
      if (sMsg.mediaUrl != null) {
        VideoThumbnailCache.registerLocalPath(sMsg.mediaUrl!, files.first.path);
      }
      for (int i = 0; i < sMsg.attachmentUrls.length && i < files.length; i++) {
        VideoThumbnailCache.registerLocalPath(
          sMsg.attachmentUrls[i],
          files[i].path,
        );
      }
    }
    return sMsg;
  }

  Future<void> unsendMessage(String messageId) async {
    await chatRepository.unsendMessage(messageId, conversationId);
    reloadMessages();
  }

  Future<void> deleteForMe(String messageId) async {
    await chatRepository.deleteForMe(messageId, conversationId);
    reloadMessages();
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    await chatRepository.reactToMessage(messageId, emoji);
    reloadMessages();
  }

  Future<bool> downloadMediaToGallery(MessageModel message) async {
    setDownloading(true);
    try {
      if (message.mediaUrl == null) return false;
      if (message.mediaType == MessageMediaType.image) {
        return await mediaService.saveImageToGallery(message.mediaUrl!);
      } else if (message.mediaType == MessageMediaType.video) {
        return await mediaService.saveVideoToGallery(message.mediaUrl!);
      }
      return false;
    } finally {
      setDownloading(false);
    }
  }

  Future<void> pickAndSendFiles() async {
    final files = await FilePicker.pickFiles();
    if (files.isNotEmpty) {
      final valid = files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
      if (valid.isNotEmpty) {
        final rId = replyingTo?.id;
        clearReplyingTo();
        await chatRepository.sendMessage(
          conversationId: conversationId,
          senderId: currentUserId,
          fileAttachments: valid,
          replyToId: rId,
        );
        reloadMessages();
      }
    }
  }

  Future<void> sendVoiceMessage(File audioFile) async {
    final rId = replyingTo?.id;
    clearReplyingTo();
    await chatRepository.sendMessage(
      conversationId: conversationId,
      senderId: currentUserId,
      fileAttachment: audioFile,
      replyToId: rId,
    );
    reloadMessages();
  }
}
