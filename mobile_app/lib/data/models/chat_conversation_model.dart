import 'message_model.dart';
import 'user_model.dart';
import '../services/api_client.dart';

class ChatConversationModel {
  final String id;
  final String type;
  final UserModel peerUser;
  final MessageModel? lastMessage;
  final int unreadCount;
  final String? lastReadMessageId;
  final DateTime updatedAt;
  final int memberCount;
  final List<UserModel>? members;

  const ChatConversationModel({
    required this.id,
    this.type = 'direct',
    required this.peerUser,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastReadMessageId,
    required this.updatedAt,
    this.memberCount = 0,
    this.members,
  });

  bool get isGroup => type == 'group';

  ChatConversationModel copyWith({
    String? id,
    String? type,
    UserModel? peerUser,
    MessageModel? lastMessage,
    int? unreadCount,
    String? lastReadMessageId,
    DateTime? updatedAt,
    int? memberCount,
    List<UserModel>? members,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      peerUser: peerUser ?? this.peerUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'peerUser': peerUser.toJson(),
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': unreadCount,
        'lastReadMessageId': lastReadMessageId,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    UserModel peer;
    if (json['otherUser'] != null) {
      final u = json['otherUser'] as Map<String, dynamic>;
      peer = UserModel(
        id: u['id'] as String? ?? '',
        name: u['name'] as String? ?? 'User',
        email: u['email'] as String? ?? '',
        avatarUrl: ApiClient.resolveUrl(u['avatarUrl'] as String?),
        isOnline: u['isOnline'] as bool? ?? false,
        lastSeen: u['lastSeen'] != null ? DateTime.tryParse(u['lastSeen'] as String) : null,
      );
    } else if (json['peerUser'] != null) {
      peer = UserModel.fromJson(json['peerUser'] as Map<String, dynamic>);
    } else {
      peer = UserModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Group',
        email: '',
        avatarUrl: ApiClient.resolveUrl(json['avatarUrl'] as String?),
      );
    }

    MessageModel? lastMsg;
    if (json['lastMessage'] != null) {
      final lm = json['lastMessage'] as Map<String, dynamic>;
      lastMsg = MessageModel(
        id: lm['id'] as String? ?? '',
        conversationId: json['id'] as String,
        senderId: lm['sender']?['id'] as String? ?? '',
        text: lm['text'] as String? ?? '',
        status: lm['status'] as String? ?? 'sent',
        isUnsent: lm['isUnsent'] as bool? ?? false,
        timestamp: DateTime.tryParse(lm['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
    }

    final membersList = <UserModel>[];
    if (json['members'] is List) {
      for (final m in json['members'] as List) {
        if (m is Map<String, dynamic> && m['user'] != null) {
          final u = m['user'] as Map<String, dynamic>;
          membersList.add(UserModel(
            id: u['id'] as String? ?? '',
            name: u['name'] as String? ?? 'User',
            email: u['email'] as String? ?? '',
            avatarUrl: ApiClient.resolveUrl(u['avatarUrl'] as String?),
            isOnline: u['isOnline'] as bool? ?? false,
          ));
        }
      }
    }

    return ChatConversationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'direct',
      peerUser: peer,
      lastMessage: lastMsg,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastReadMessageId: json['lastReadMessageId'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      memberCount: (json['members'] as List?)?.length ?? 0,
      members: membersList,
    );
  }
}
