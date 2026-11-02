import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../data/models/chat_conversation_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../widgets/chat_filter_chips.dart';

class ChatListViewModel extends ChangeNotifier {
  final ChatRepository chatRepository;
  StreamSubscription<List<ChatConversationModel>>? _subscription;
  List<ChatConversationModel> _conversations = [];
  String _searchQuery = '';
  ChatFilterType _activeFilter = ChatFilterType.all;

  ChatListViewModel({required this.chatRepository}) {
    _conversations = chatRepository.conversations;
    _subscription = chatRepository.conversationsStream.listen((list) {
      _conversations = list;
      notifyListeners();
    });
    chatRepository.loadConversations();
  }

  Future<void> loadConversations() async {
    await chatRepository.loadConversations();
    _conversations = chatRepository.conversations;
    notifyListeners();
  }

  List<ChatConversationModel> get rawConversations => _conversations;
  ChatFilterType get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String get currentUserId => chatRepository.currentUserId;

  int get totalUnreadCount =>
      _conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

  List<ChatConversationModel> get conversations {
    var list = _conversations;

    // Apply Filter
    switch (_activeFilter) {
      case ChatFilterType.unread:
        list = list.where((c) => c.unreadCount > 0).toList();
        break;
      case ChatFilterType.groups:
        list = list.where((c) => c.isGroup).toList();
        break;
      case ChatFilterType.media:
        list = list.where((c) => c.lastMessage?.mediaType.isMedia ?? false).toList();
        break;
      case ChatFilterType.online:
        list = list.where((c) => c.peerUser.isOnline).toList();
        break;
      case ChatFilterType.all:
        break;
    }

    // Apply Search Query
    if (_searchQuery.trim().isEmpty) return list;
    final query = _searchQuery.toLowerCase();
    return list.where((c) {
      final matchName = c.peerUser.name.toLowerCase().contains(query);
      final matchMsg = c.lastMessage?.text.toLowerCase().contains(query) ?? false;
      return matchName || matchMsg;
    }).toList();
  }

  void setActiveFilter(ChatFilterType filter) {
    if (_activeFilter != filter) {
      _activeFilter = filter;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> deleteConversation(String conversationId) async {
    await chatRepository.deleteChat(conversationId);
    notifyListeners();
  }

  Future<void> markChatAsRead(String conversationId) async {
    await chatRepository.markChatAsRead(conversationId);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    for (final c in _conversations) {
      if (c.unreadCount > 0) {
        await chatRepository.markChatAsRead(c.id);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
