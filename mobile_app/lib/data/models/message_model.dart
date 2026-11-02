import '../services/api_client.dart';

enum MessageMediaType {
  none,
  image,
  video,
  file,
  audio,
  zip,
  pdf,
  apk;

  bool get isMedia => this != MessageMediaType.none;
  bool get isImage => this == MessageMediaType.image;
  bool get isVideo => this == MessageMediaType.video;
  bool get isAudio => this == MessageMediaType.audio;
  bool get isPdf => this == MessageMediaType.pdf;
  bool get isZip => this == MessageMediaType.zip;
  bool get isApk => this == MessageMediaType.apk;
  bool get isDocumentOrFile =>
      this == MessageMediaType.file ||
      this == MessageMediaType.pdf ||
      this == MessageMediaType.zip ||
      this == MessageMediaType.apk;
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final List<String> attachmentUrls;
  final MessageMediaType mediaType;
  final String? fileName;
  final int? fileSize;
  final String status;
  final DateTime timestamp;
  final bool isForwarded;
  final bool isUnsent;
  final String? originalSenderName;
  final String? senderName;
  final String? localFilePath;
  final int? durationSeconds;
  final String? replyToId;
  final String? replyToText;
  final Map<String, int> reactions;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.text = '',
    this.mediaUrl,
    this.attachmentUrls = const [],
    this.mediaType = MessageMediaType.none,
    this.fileName,
    this.fileSize,
    this.status = 'sent',
    required this.timestamp,
    this.isForwarded = false,
    this.isUnsent = false,
    this.originalSenderName,
    this.senderName,
    this.localFilePath,
    this.durationSeconds,
    this.replyToId,
    this.replyToText,
    this.reactions = const {},
  });

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    String? mediaUrl,
    List<String>? attachmentUrls,
    MessageMediaType? mediaType,
    String? fileName,
    int? fileSize,
    String? status,
    DateTime? timestamp,
    bool? isForwarded,
    bool? isUnsent,
    String? originalSenderName,
    String? senderName,
    String? localFilePath,
    int? durationSeconds,
    String? replyToId,
    String? replyToText,
    Map<String, int>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      mediaType: mediaType ?? this.mediaType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isForwarded: isForwarded ?? this.isForwarded,
      isUnsent: isUnsent ?? this.isUnsent,
      originalSenderName: originalSenderName ?? this.originalSenderName,
      senderName: senderName ?? this.senderName,
      localFilePath: localFilePath ?? this.localFilePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'mediaUrl': mediaUrl,
        'attachmentUrls': attachmentUrls,
        'mediaType': mediaType.name,
        'fileName': fileName,
        'fileSize': fileSize,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'isForwarded': isForwarded,
        'isUnsent': isUnsent,
        'replyToId': replyToId,
        'replyToText': replyToText,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String? resolvedMediaUrl;
    final allAttachmentUrls = <String>[];
    MessageMediaType type = MessageMediaType.none;
    String? fileName;
    int? fileSize;

    final attachments = json['attachments'] as List?;
    if (attachments != null && attachments.isNotEmpty) {
      for (final a in attachments) {
        if (a is Map<String, dynamic> && a['fileUrl'] != null) {
          allAttachmentUrls.add(ApiClient.resolveUrl(a['fileUrl'] as String?));
        }
      }
      final first = attachments[0] as Map<String, dynamic>;
      resolvedMediaUrl = ApiClient.resolveUrl(first['fileUrl'] as String?);
      fileName = first['fileName'] as String?;
      fileSize = first['fileSize'] as int?;

      final rawType = first['fileType'] as String? ?? '';
      final fn = (fileName ?? '').toLowerCase();
      if (rawType == 'apk' || fn.endsWith('.apk')) {
        type = MessageMediaType.apk;
      } else if (rawType == 'pdf' || fn.endsWith('.pdf')) {
        type = MessageMediaType.pdf;
      } else if (rawType == 'image') {
        type = MessageMediaType.image;
      } else if (rawType == 'video') {
        type = MessageMediaType.video;
      } else if (rawType == 'audio') {
        type = MessageMediaType.audio;
      } else if (rawType == 'zip' || fn.endsWith('.zip') || fn.endsWith('.rar') || fn.endsWith('.7z')) {
        type = MessageMediaType.zip;
      } else {
        type = MessageMediaType.file;
      }
    } else if (json['mediaUrl'] != null) {
      resolvedMediaUrl = ApiClient.resolveUrl(json['mediaUrl'] as String?);
      allAttachmentUrls.add(resolvedMediaUrl);
      final rawType = json['mediaType'] as String? ?? 'none';
      type = MessageMediaType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => MessageMediaType.none,
      );
    }

    final reactionsMap = <String, int>{};
    if (json['reactions'] is List) {
      for (final r in json['reactions'] as List) {
        final emoji = r['emoji'] as String?;
        if (emoji != null) {
          reactionsMap[emoji] = (reactionsMap[emoji] ?? 0) + 1;
        }
      }
    }

    return MessageModel(
      id: json['id'] as String,
      conversationId: json['chatId'] as String? ?? json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String,
      text: json['text'] as String? ?? '',
      mediaUrl: resolvedMediaUrl,
      attachmentUrls: allAttachmentUrls,
      mediaType: type,
      fileName: fileName,
      fileSize: fileSize,
      status: json['status'] as String? ?? 'sent',
      timestamp: DateTime.tryParse(json['createdAt'] as String? ?? json['timestamp'] as String? ?? '') ?? DateTime.now(),
      isForwarded: json['isForwarded'] as bool? ?? false,
      isUnsent: json['isUnsent'] as bool? ?? false,
      originalSenderName: json['originalSenderName'] as String?,
      senderName: json['sender']?['name'] as String? ?? json['senderName'] as String?,
      replyToId: json['replyToId'] as String?,
      replyToText: json['replyTo']?['text'] as String?,
      reactions: reactionsMap,
    );
  }
}
