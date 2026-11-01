import { prisma } from '../../config/database.js';
import { CacheService } from '../../services/cache.service.js';
import { REDIS_KEYS } from '../../config/constants.js';
import { emitToUser, emitToChat } from './socket.server.js';
import { SOCKET_EVENTS } from './socket.events.js';
import { logger } from '../../utils/logger.js';

export class PresenceService {
  /**
   * Set user online in MySQL first, then update Redis
   */
  static async setUserOnline(userId: string) {
    try {
      await prisma.user.updateMany({
        where: { id: userId },
        data: { isOnline: true },
      });
      await CacheService.del(REDIS_KEYS.USER_PROFILE(userId));
    } catch (err) {
      logger.error(`Failed to set user online for [${userId}]:`, err);
    }
  }

  /**
   * Set user offline in MySQL first, then update Redis
   */
  static async setUserOffline(userId: string) {
    try {
      await prisma.user.updateMany({
        where: { id: userId },
        data: { isOnline: false, lastSeen: new Date() },
      });
      await CacheService.del(REDIS_KEYS.USER_PROFILE(userId));
    } catch (err) {
      logger.error(`Failed to set user offline for [${userId}]:`, err);
    }
  }

  /**
   * When user turns on phone internet & connects to socket:
   * Mark all un-delivered messages in their chats as DELIVERED
   * and notify senders with real-time double ticks!
   */
  static async markPendingMessagesDelivered(userId: string) {
    try {
      // Find chats this user is a member of
      const userChats = await prisma.chatMember.findMany({
        where: { userId },
        select: { chatId: true },
      });

      const chatIds = userChats.map((c) => c.chatId);
      if (chatIds.length === 0) return;

      // Find sent messages from other users not yet delivered
      const pendingMessages = await prisma.message.findMany({
        where: {
          chatId: { in: chatIds },
          senderId: { not: userId },
          status: 'sent',
        },
        select: { id: true, chatId: true, senderId: true },
      });

      if (pendingMessages.length === 0) return;

      const now = new Date();
      await prisma.message.updateMany({
        where: {
          id: { in: pendingMessages.map((m) => m.id) },
        },
        data: {
          status: 'delivered',
          deliveredAt: now,
        },
      });

      // Notify each sender in real-time
      for (const msg of pendingMessages) {
        emitToUser(msg.senderId, SOCKET_EVENTS.MESSAGE_DELIVERED, {
          messageId: msg.id,
          chatId: msg.chatId,
          recipientId: userId,
          deliveredAt: now,
        });
      }

      // Invalidate chat message caches
      for (const chatId of new Set(pendingMessages.map((m) => m.chatId))) {
        await CacheService.delPattern(`chat:messages:${chatId}:*`);
      }
    } catch (err) {
      logger.error('Failed to mark pending messages delivered:', err);
    }
  }
}
