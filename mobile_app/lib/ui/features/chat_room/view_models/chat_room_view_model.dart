import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../data/models/message_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/media_service.dart';
import 'chat_room_actions_mixin.dart';
import 'chat_room_socket_mixin.dart';

class ChatRoomViewModel extends ChangeNotifier
    with ChatRoomSocketMixin, ChatRoomActionsMixin {
  @override
  final String conversationId;
  final UserModel peerUser;
  @override
  final String currentUserId;
  @override
  final ChatRepository chatRepository;
  @override
  final MediaService mediaService;

  List<MessageModel> _messages = [];
  final List<File> _selectedMedia = [];
  bool _isDownloading = false;
  List<VoidCallback> _socketUnsubscribers = [];
  MessageModel? _replyingTo;
  String _searchQuery = '';
  bool _isSearching = false;

  ChatRoomViewModel({
    required this.conversationId,
    required this.peerUser,
    required this.currentUserId,
    required this.chatRepository,
    required this.mediaService,
  }) {
    final cached = chatRepository.getMessages(conversationId);
    if (cached.isNotEmpty) {
      _messages = List<MessageModel>.from(cached)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    chatRepository.activeConversationId = conversationId;
    chatRepository.socketService.joinChat(conversationId);
    _loadMessages();
    _socketUnsubscribers = subscribeSocketEvents();
  }

  @override
  List<MessageModel> get messagesList => _messages;
  @override
  void reloadMessages() => _loadMessages();
  @override
  void clearReplyingTo() => _replyingTo = null;

  @override
  void setDownloading(bool downloading) {
    _isDownloading = downloading;
    if (!isDisposed) notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!isDisposed) super.notifyListeners();
  }

  List<MessageModel> get messages {
    if (_isSearching && _searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return _messages.where((m) => m.text.toLowerCase().contains(q)).toList();
    }
    return _messages;
  }

  List<File> get selectedMedia => List.unmodifiable(_selectedMedia);
  bool get isDownloading => _isDownloading;
  @override
  MessageModel? get replyingTo => _replyingTo;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  void toggleSearch(bool a) {
    _isSearching = a;
    if (!a) _searchQuery = '';
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setReplyingTo(MessageModel? m) {
    _replyingTo = m;
    notifyListeners();
  }

  void removeSelectedMedia(int i) {
    if (i >= 0 && i < _selectedMedia.length) {
      _selectedMedia.removeAt(i);
      notifyListeners();
    }
  }

  void clearSelectedMedia() {
    _selectedMedia.clear();
    notifyListeners();
  }

  void onTypingChanged(String text) =>
      chatRepository.socketService.emitTyping(conversationId, text.isNotEmpty);

  Future<void> _loadMessages() async {
    if (isDisposed) return;
    final msgs = await chatRepository.fetchMessages(conversationId);
    if (isDisposed) return;
    _messages = List<MessageModel>.from(msgs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final unreadPeer = _messages.cast<MessageModel?>().firstWhere(
      (m) => m != null && m.senderId != currentUserId && m.status != 'read',
      orElse: () => null,
    );
    if (unreadPeer != null) {
      chatRepository.markAsRead(conversationId, unreadPeer.id);
    }
    notifyListeners();
  }

  void _updateMsgStatus(String tempId, MessageModel? sMsg, bool failed) {
    final idx = _messages.indexWhere((m) => m.id == tempId);
    if (idx != -1 && !isDisposed) {
      _messages[idx] = failed
          ? _messages[idx].copyWith(status: 'failed')
          : (sMsg ?? _messages[idx].copyWith(status: 'sent'));
      notifyListeners();
    }
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    onTypingChanged('');
    final replyId = _replyingTo?.id;
    _replyingTo = null;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    _messages.insert(
      0,
      MessageModel(
        id: tempId,
        conversationId: conversationId,
        senderId: currentUserId,
        text: text.trim(),
        status: 'sending',
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      final sMsg = await chatRepository.sendMessage(
        conversationId: conversationId,
        senderId: currentUserId,
        text: text.trim(),
        replyToId: replyId,
      );
      _updateMsgStatus(tempId, sMsg, false);
    } catch (_) {
      _updateMsgStatus(tempId, null, true);
    }
  }

  Future<void> pickMedia() async {
    final picked = await pickGalleryMedia();
    if (picked.isNotEmpty && !isDisposed) {
      _selectedMedia.addAll(picked);
      notifyListeners();
    }
  }

  Future<void> pickAudio() async {
    final picked = await pickAudioFiles();
    if (picked.isNotEmpty && !isDisposed) {
      _selectedMedia.addAll(picked);
      notifyListeners();
    }
  }

  Future<void> sendMediaMessage({String caption = ''}) async {
    if (_selectedMedia.isEmpty) return;
    final files = List<File>.from(_selectedMedia);
    _selectedMedia.clear();
    notifyListeners();

    final replyId = _replyingTo?.id;
    _replyingTo = null;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    _messages.insert(
      0,
      createOptimisticMediaMessage(
        tempId: tempId,
        files: files,
        caption: caption,
      ),
    );
    notifyListeners();

    try {
      final sMsg = await dispatchMediaMessage(
        files: files,
        caption: caption,
        replyToId: replyId,
      );
      _updateMsgStatus(tempId, sMsg, false);
    } catch (_) {
      _updateMsgStatus(tempId, null, true);
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    for (final unsub in _socketUnsubscribers) {
      unsub();
    }
    _socketUnsubscribers.clear();
    chatRepository.socketService.leaveChat(conversationId);
    if (chatRepository.activeConversationId == conversationId) {
      chatRepository.activeConversationId = null;
    }
    super.dispose();
  }
}
