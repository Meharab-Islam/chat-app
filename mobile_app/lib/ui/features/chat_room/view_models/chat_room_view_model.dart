import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/media_service.dart';
import '../../../../data/services/video_thumbnail_cache.dart';
import 'chat_room_actions_mixin.dart';

class ChatRoomViewModel extends ChangeNotifier with ChatRoomActionsMixin {
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
  bool _isPeerTyping = false;
  bool _isDisposed = false;
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
      _messages = List<MessageModel>.from(cached)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    chatRepository.activeConversationId = conversationId;
    chatRepository.socketService.joinChat(conversationId);
    _loadMessages();
    _socketUnsubscribers = initChatSocketEvents(
      onPeerTypingChanged: (t) { if (!_isDisposed) { _isPeerTyping = t; notifyListeners(); } },
      onNewMessageReceived: (m) {
        if (!_isDisposed) {
          if (!_messages.any((x) => x.id == m.id)) { _messages.insert(0, m); notifyListeners(); }
          if (m.senderId != currentUserId) chatRepository.markAsRead(conversationId, m.id);
        }
      },
      onMessageDelivered: (msgId) {
        if (_isDisposed) return;
        final idx = _messages.indexWhere((m) => m.id == msgId);
        if (idx != -1 && _messages[idx].status != 'read') {
          _messages[idx] = _messages[idx].copyWith(status: 'delivered');
          notifyListeners();
        }
      },
      onPeerReadMessages: () {
        if (_isDisposed) return;
        bool changed = false;
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].senderId == currentUserId && _messages[i].status != 'read') {
            _messages[i] = _messages[i].copyWith(status: 'read');
            changed = true;
          }
        }
        if (changed) notifyListeners();
      },
      onMessageUnsent: (msgId) {
        if (_isDisposed) return;
        final idx = _messages.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(isUnsent: true, text: 'This message was unsent');
          notifyListeners();
        }
      },
    );
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
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
  bool get isPeerTyping => _isPeerTyping;
  MessageModel? get replyingTo => _replyingTo;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  void toggleSearch(bool a) { _isSearching = a; if (!a) _searchQuery = ''; notifyListeners(); }
  void setSearchQuery(String q) { _searchQuery = q; notifyListeners(); }
  void setReplyingTo(MessageModel? m) { _replyingTo = m; notifyListeners(); }
  void removeSelectedMedia(int i) { if (i >= 0 && i < _selectedMedia.length) { _selectedMedia.removeAt(i); notifyListeners(); } }
  void clearSelectedMedia() { _selectedMedia.clear(); notifyListeners(); }
  void onTypingChanged(String text) => chatRepository.socketService.emitTyping(conversationId, text.isNotEmpty);

  Future<void> _loadMessages() async {
    if (_isDisposed) return;
    final msgs = await chatRepository.fetchMessages(conversationId);
    if (_isDisposed) return;
    _messages = List<MessageModel>.from(msgs)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final unreadPeer = _messages.cast<MessageModel?>().firstWhere(
      (m) => m != null && m.senderId != currentUserId && m.status != 'read',
      orElse: () => null,
    );
    if (unreadPeer != null) {
      chatRepository.markAsRead(conversationId, unreadPeer.id);
    }
    notifyListeners();
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    onTypingChanged('');
    final replyId = _replyingTo?.id;
    _replyingTo = null;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    _messages.insert(0, MessageModel(
      id: tempId, conversationId: conversationId, senderId: currentUserId,
      text: text.trim(), status: 'sending', timestamp: DateTime.now(),
    ));
    notifyListeners();

    try {
      final sMsg = await chatRepository.sendMessage(
        conversationId: conversationId, senderId: currentUserId, text: text.trim(), replyToId: replyId,
      );
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1 && !_isDisposed) {
        _messages[idx] = sMsg ?? _messages[idx].copyWith(status: 'sent');
        notifyListeners();
      }
    } catch (_) {
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1 && !_isDisposed) {
        _messages[idx] = _messages[idx].copyWith(status: 'failed');
        notifyListeners();
      }
    }
  }

  Future<void> pickMedia() async {
    try {
      final picked = await ImagePicker().pickMultipleMedia();
      if (picked.isNotEmpty && !_isDisposed) {
        _selectedMedia.addAll(picked.map((x) => File(x.path)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  Future<void> sendMediaMessage({String caption = ''}) async {
    if (_selectedMedia.isEmpty) return;
    final files = List<File>.from(_selectedMedia);
    _selectedMedia.clear();
    notifyListeners();

    final replyId = _replyingTo?.id;
    _replyingTo = null;
    final hasVideo = files.any((f) {
      final l = f.path.toLowerCase();
      return l.endsWith('.mp4') || l.endsWith('.mov') || l.endsWith('.mkv') || l.endsWith('.webm');
    });

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    _messages.insert(0, MessageModel(
      id: tempId, conversationId: conversationId, senderId: currentUserId,
      text: caption.trim(), status: 'sending', timestamp: DateTime.now(),
      mediaType: hasVideo ? MessageMediaType.video : MessageMediaType.image,
      attachmentUrls: files.map((f) => f.path).toList(), mediaUrl: files.first.path,
    ));
    notifyListeners();

    try {
      final sMsg = await chatRepository.sendMessage(
        conversationId: conversationId, senderId: currentUserId,
        text: caption.trim(), fileAttachments: files, replyToId: replyId,
      );
      if (sMsg != null && files.isNotEmpty) {
        if (sMsg.mediaUrl != null) VideoThumbnailCache.registerLocalPath(sMsg.mediaUrl!, files.first.path);
        for (int i = 0; i < sMsg.attachmentUrls.length && i < files.length; i++) {
          VideoThumbnailCache.registerLocalPath(sMsg.attachmentUrls[i], files[i].path);
        }
      }
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1 && !_isDisposed) {
        _messages[idx] = sMsg ?? _messages[idx].copyWith(status: 'sent');
        notifyListeners();
      }
    } catch (e) {
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1 && !_isDisposed) {
        _messages[idx] = _messages[idx].copyWith(status: 'failed');
        notifyListeners();
      }
    }
  }

  Future<void> pickAndSendFiles() => pickAndSendOtherFiles(
        replyToId: _replyingTo?.id, onRefresh: () { if (!_isDisposed) { _replyingTo = null; _loadMessages(); } });

  Future<void> sendVoiceMessage(File audio) => sendVoice(
        audio, replyToId: _replyingTo?.id, onRefresh: () { if (!_isDisposed) { _replyingTo = null; _loadMessages(); } });

  Future<void> unsendMessage(String id) => unsend(id, _loadMessages);
  Future<void> deleteForMe(String id) => deleteMessageForMe(id, _loadMessages);
  Future<void> reactToMessage(String id, String e) => react(id, e, _loadMessages);

  Future<bool> downloadMediaToGallery(MessageModel msg) async {
    _isDownloading = true;
    notifyListeners();
    try {
      return await downloadToGallery(msg);
    } finally {
      if (!_isDisposed) {
        _isDownloading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final unsub in _socketUnsubscribers) { unsub(); }
    _socketUnsubscribers.clear();
    chatRepository.socketService.leaveChat(conversationId);
    if (chatRepository.activeConversationId == conversationId) chatRepository.activeConversationId = null;
    super.dispose();
  }
}
