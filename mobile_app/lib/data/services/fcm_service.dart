import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'api_client.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('FCM background message received: ${message.messageId}');
  final messageId = message.data['messageId'];
  if (messageId != null && messageId.toString().isNotEmpty) {
    try {
      final client = ApiClient();
      await client.post('/messages/ack-delivery', {'messageId': messageId});
      debugPrint('Background delivery ACK sent for message: $messageId');
    } catch (e) {
      debugPrint('Error sending background delivery ack: $e');
    }
  }

  final title = message.notification?.title ?? message.data['title'] ?? 'New Message';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  final chatId = message.data['chatId'] ?? '';
  final imageUrl = message.data['imageUrl'] ?? message.notification?.android?.imageUrl;

  if (chatId.toString().isNotEmpty && message.notification == null) {
    try {
      await NotificationService.instance.showChatNotification(
        id: chatId.hashCode.abs(),
        title: title.toString(),
        body: body.toString(),
        chatId: chatId.toString(),
        imageUrl: imageUrl?.toString(),
      );
    } catch (e) {
      debugPrint('Error displaying background notification: $e');
    }
  }
}

class FcmService {
  final ApiClient apiClient;

  FcmService({required this.apiClient});

  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Listen for token registration / refresh (Firebase Messaging 17+)
      messaging.onRegistered.listen((token) {
        debugPrint('==================================================');
        debugPrint('🔥 FCM TOKEN (onRegistered): $token');
        debugPrint('==================================================');
        _registerTokenWithBackend(token);
      });

      // Generate FCM token on app launch and print it
      try {
        // ignore: deprecated_member_use
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint('==================================================');
          debugPrint('🔥 FCM TOKEN: $token');
          debugPrint('==================================================');
          await _registerTokenWithBackend(token);
        }
      } catch (e) {
        debugPrint('⚠️ FCM getToken error: $e');
      }

      try {
        await messaging.register();
      } catch (e) {
        debugPrint('FCM register note: $e');
      }

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM foreground message received: ${message.data}');
        final messageId = message.data['messageId'];
        if (messageId != null) {
          apiClient
              .post('/messages/ack-delivery', {'messageId': messageId})
              .catchError((_) {});
        }

        final title = message.notification?.title ?? message.data['title'] ?? 'New Message';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        final chatId = message.data['chatId'] ?? '';
        final imageUrl = message.data['imageUrl'] ?? message.notification?.android?.imageUrl;

        if (chatId.toString().isNotEmpty) {
          NotificationService.instance.showChatNotification(
            id: chatId.hashCode.abs(),
            title: title.toString(),
            body: body.toString(),
            chatId: chatId.toString(),
            imageUrl: imageUrl?.toString(),
          );
        }
      });
    } catch (e) {
      debugPrint('FCM service initialization error: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await apiClient.put('/users/fcm-token', {'fcmToken': token});
      debugPrint('FCM device token registered with backend');
    } catch (e) {
      debugPrint('Failed to register FCM token with backend: $e');
    }
  }
}
