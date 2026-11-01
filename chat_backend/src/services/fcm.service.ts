import { logger } from '../utils/logger.js';

export interface PushNotificationPayload {
  token: string;
  title: string;
  body: string;
  imageUrl?: string;
  data: Record<string, string>;
}

export class FcmService {
  /**
   * Send high-priority FCM notification/data payload to wake device in background
   */
  static async sendNotification(payload: PushNotificationPayload): Promise<boolean> {
    try {
      const fcmKey = process.env.FCM_SERVER_KEY;
      if (!fcmKey) {
        logger.debug(
          `[FCM Mock] Push message prepared for token [${payload.token.substring(0, 15)}...]: ${payload.title} - ${payload.body}`
        );
        return true;
      }

      const response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `key=${fcmKey}`,
        },
        body: JSON.stringify({
          to: payload.token,
          priority: 'high',
          content_available: true,
          data: {
            ...payload.data,
            title: payload.title,
            body: payload.body,
            ...(payload.imageUrl ? { imageUrl: payload.imageUrl } : {}),
          },
          notification: {
            title: payload.title,
            body: payload.body,
            sound: 'default',
            android_channel_id: 'chat_high_importance_channel',
            ...(payload.imageUrl ? { image: payload.imageUrl } : {}),
          },
        }),
      });

      return response.ok;
    } catch (err) {
      logger.error('Failed to send FCM push notification:', err);
      return false;
    }
  }
}

