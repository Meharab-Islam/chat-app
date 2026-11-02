import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse details) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(
    '🔔 [NotificationService] Background action: ${details.actionId}, input: ${details.input}',
  );

  final plugin = FlutterLocalNotificationsPlugin();
  if (details.id != null) {
    try {
      await plugin.cancel(id: details.id!);
    } catch (_) {}
  }

  if (details.actionId == 'action_reply') {
    final replyText = details.input?.trim();
    final chatId = details.payload;
    if (replyText != null &&
        replyText.isNotEmpty &&
        chatId != null &&
        chatId.isNotEmpty) {
      try {
        final client = ApiClient();
        await client
            .post('/messages', {'chatId': chatId, 'text': replyText})
            .timeout(const Duration(seconds: 10));
        debugPrint('✅ [NotificationService] Direct reply sent: $replyText');
      } catch (e) {
        debugPrint('❌ [NotificationService] Failed to send direct reply: $e');
      } finally {
        try {
          await plugin.cancel(id: chatId.hashCode.abs());
        } catch (_) {}
      }
    }
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_high_importance_channel',
    'Chat Messages',
    description: 'Real-time notifications for incoming chat messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'chat_reply_category',
          actions: [
            DarwinNotificationAction.text(
              'action_reply',
              'Reply',
              buttonTitle: 'Send',
              placeholder: 'Type a reply...',
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        await notificationTapBackground(details);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint(
      'NotificationService initialized with sound, reply action & channel',
    );
  }

  Future<void> showChatNotification({
    required int id,
    required String title,
    required String body,
    required String chatId,
    String? imageUrl,
  }) async {
    if (!_initialized) await initialize();

    ByteArrayAndroidBitmap? bigPictureBitmap;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final resolvedUrl = ApiClient.resolveUrl(imageUrl);
        final res = await http
            .get(Uri.parse(resolvedUrl))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          bigPictureBitmap = ByteArrayAndroidBitmap(res.bodyBytes);
        }
      } catch (e) {
        debugPrint('Failed to download image for notification preview: $e');
      }
    }

    final styleInformation = bigPictureBitmap != null
        ? BigPictureStyleInformation(
            bigPictureBitmap,
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: true,
          )
        : null;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: styleInformation,
      actions: const [
        AndroidNotificationAction(
          'action_reply',
          'Reply',
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          inputs: [AndroidNotificationActionInput(label: 'Type a reply...')],
          cancelNotification: true,
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'chat_reply_category',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: chatId,
    );
  }
}
