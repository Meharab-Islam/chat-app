import { prisma } from '../../config/database.js';
import { CacheService } from '../../services/cache.service.js';
import { emitToChat, emitToUser } from '../socket/socket.server.js';
import { SOCKET_EVENTS } from '../socket/socket.events.js';

export class MessageActionService {
  /**
   * Unsend message (Delete for everyone)
   */
  static async unsendMessage(userId: string, messageId: string) {
    const message = await prisma.message.findUnique({ where: { id: messageId } });
    if (!message) throw new Error('Message not found');
    if (message.senderId !== userId) {
      throw new Error('You can only unsend your own messages');
    }

    const updated = await prisma.message.update({
      where: { id: messageId },
      data: { isUnsent: true, text: null },
    });

    await Promise.all([
      CacheService.delPattern(`chat:messages:${message.chatId}:*`),
      CacheService.delPattern('user:chats:*'),
    ]);

    emitToChat(message.chatId, SOCKET_EVENTS.MESSAGE_UNSENT, {
      messageId,
      chatId: message.chatId,
    });

    return updated;
  }

  /**
   * Delete for me (hide message only for current user)
   */
  static async deleteForMe(userId: string, messageId: string) {
    const message = await prisma.message.findUnique({ where: { id: messageId } });
    if (!message) throw new Error('Message not found');

    await prisma.deletedMessage.upsert({
      where: { messageId_userId: { messageId, userId } },
      create: { messageId, userId },
      update: {},
    });

    await CacheService.delPattern(`chat:messages:${message.chatId}:*`);
    return { messageId, deletedForUserId: userId };
  }

  /**
   * React to message (Toggle emoji reaction)
   */
  static async reactToMessage(userId: string, messageId: string, emoji: string) {
    const message = await prisma.message.findUnique({ where: { id: messageId } });
    if (!message) throw new Error('Message not found');

    const existing = await prisma.messageReaction.findUnique({
      where: { messageId_userId_emoji: { messageId, userId, emoji } },
    });

    let action: 'added' | 'removed' = 'added';
    if (existing) {
      await prisma.messageReaction.delete({ where: { id: existing.id } });
      action = 'removed';
    } else {
      await prisma.messageReaction.create({
        data: { messageId, userId, emoji },
      });
      action = 'added';
    }

    await CacheService.delPattern(`chat:messages:${message.chatId}:*`);

    emitToChat(message.chatId, SOCKET_EVENTS.MESSAGE_REACTION, {
      messageId,
      userId,
      emoji,
      action,
    });

    return { messageId, userId, emoji, action };
  }

  /**
   * HTTP Delivery Acknowledgment (called by background FCM worker when app is killed)
   */
  static async acknowledgeDelivery(recipientId: string, messageId: string) {
    const message = await prisma.message.findUnique({ where: { id: messageId } });
    if (!message) throw new Error('Message not found');

    const now = new Date();
    const updated = await prisma.message.update({
      where: { id: messageId },
      data: { status: 'delivered', deliveredAt: now },
    });

    await CacheService.delPattern(`chat:messages:${message.chatId}:*`);

    emitToUser(message.senderId, SOCKET_EVENTS.MESSAGE_DELIVERED, {
      messageId,
      chatId: message.chatId,
      recipientId,
      deliveredAt: now,
    });

    return updated;
  }

  /**
   * Mark all unread messages as read in conversation
   */
  static async markAsRead(userId: string, chatId: string, lastReadMessageId?: string) {
    const now = new Date();
    await prisma.chatMember.updateMany({
      where: { chatId, userId },
      data: { lastReadAt: now, lastReadMessageId: lastReadMessageId || null },
    });

    await prisma.message.updateMany({
      where: {
        chatId,
        senderId: { not: userId },
        status: { in: ['sent', 'delivered'] },
      },
      data: { status: 'read', readAt: now },
    });

    emitToChat(chatId, SOCKET_EVENTS.MESSAGE_READ, {
      chatId,
      readerId: userId,
      lastReadMessageId,
      readAt: now,
    });

    await Promise.all([
      CacheService.delPattern(`chat:messages:${chatId}:*`),
      CacheService.delPattern('user:chats:*'),
    ]);

    return { chatId, readAt: now };
  }
}
