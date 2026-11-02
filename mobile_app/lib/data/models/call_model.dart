class CallTokenData {
  final String token;
  final String url;
  final String roomName;
  final String callType;

  const CallTokenData({
    required this.token,
    required this.url,
    required this.roomName,
    required this.callType,
  });

  factory CallTokenData.fromJson(Map<String, dynamic> json) {
    return CallTokenData(
      token: json['token'] as String? ?? '',
      url: json['url'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      callType: json['callType'] as String? ?? 'video',
    );
  }
}

class IncomingCallData {
  final String callId;
  final String chatId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String callType; // 'audio' | 'video'
  final bool isGroup;
  final String chatName;

  const IncomingCallData({
    required this.callId,
    required this.chatId,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.callType,
    required this.isGroup,
    required this.chatName,
  });

  factory IncomingCallData.fromJson(Map<String, dynamic> json) {
    final caller = json['caller'] as Map<String, dynamic>? ?? {};
    return IncomingCallData(
      callId: json['callId'] as String? ?? '',
      chatId: json['chatId'] as String? ?? '',
      callerId: caller['id'] as String? ?? '',
      callerName: caller['name'] as String? ?? 'Caller',
      callerAvatar: caller['avatar'] as String?,
      callType: json['callType'] as String? ?? 'video',
      isGroup: json['isGroup'] as bool? ?? false,
      chatName: json['chatName'] as String? ?? 'Call',
    );
  }
}
