import { Server } from 'socket.io';
import { AuthenticatedSocket } from './socket.auth.js';
import { SOCKET_EVENTS } from './socket.events.js';
import { PresenceService } from './socket.presence.js';
import { prisma } from '../../config/database.js';
import { CacheService } from '../../services/cache.service.js';
import { emitToUser, emitToChat } from './socket.server.js';
import { logger } from '../../utils/logger.js';

export const registerSocketHandlers = (io: Server, socket: AuthenticatedSocket) => {
  const userId = socket.user!.userId;

  // 1. Join personal user notification room
  socket.join(`user:${userId}`);

  // Auto-join all existing chats for this user so they receive real-time messages!
  prisma.chatMember.findMany({
    where: { userId },
    select: { chatId: true },
  }).then((memberships) => {
    for (const m of memberships) {
      socket.join(`chat:${m.chatId}`);
    }
    logger.debug(`User [${userId}] auto-joined ${memberships.length} chat rooms`);
  }).catch((err) => {
    logger.error('Failed to auto-join user chat rooms:', err);
  });

  // 2. Track online presence & mark pending messages as DELIVERED
  PresenceService.setUserOnline(userId);
  PresenceService.markPendingMessagesDelivered(userId);
  socket.broadcast.emit(SOCKET_EVENTS.USER_ONLINE, { userId });

  logger.info(`User connected to socket: [${userId}] (socketId: ${socket.id})`);

  // 3. Join / Leave specific chat room
  socket.on(SOCKET_EVENTS.JOIN_CHAT, (chatId: string) => {
    socket.join(`chat:${chatId}`);
    logger.debug(`User [${userId}] joined chat room [${chatId}]`);
  });

  socket.on(SOCKET_EVENTS.LEAVE_CHAT, (chatId: string) => {
    socket.leave(`chat:${chatId}`);
    logger.debug(`User [${userId}] left chat room [${chatId}]`);
  });

  // 4. Message Delivered Ack (Client received message via background notification / app)
  socket.on(
    SOCKET_EVENTS.MESSAGE_DELIVERED,
    async ({ messageId, chatId }: { messageId: string; chatId: string }) => {
      try {
        const msg = await prisma.message.update({
          where: { id: messageId },
          data: { status: 'delivered', deliveredAt: new Date() },
        });
        emitToUser(msg.senderId, SOCKET_EVENTS.MESSAGE_DELIVERED, {
          messageId,
          chatId,
          recipientId: userId,
          deliveredAt: msg.deliveredAt,
        });
        await CacheService.delPattern(`chat:messages:${chatId}:*`);
      } catch (err) {
        logger.error('Error handling message delivered ack:', err);
      }
    }
  );

  // 5. Message Seen / Read (Client opened chat screen and saw up to messageId)
  socket.on(
    SOCKET_EVENTS.MESSAGE_READ,
    async ({
      chatId,
      lastReadMessageId,
    }: {
      chatId: string;
      lastReadMessageId?: string;
    }) => {
      try {
        const now = new Date();

        // Update member's last read pointer
        await prisma.chatMember.updateMany({
          where: { chatId, userId },
          data: {
            lastReadAt: now,
            lastReadMessageId: lastReadMessageId || null,
          },
        });

        // Mark messages in this chat from others as 'read'
        await prisma.message.updateMany({
          where: {
            chatId,
            senderId: { not: userId },
            status: { in: ['sent', 'delivered'] },
          },
          data: { status: 'read', readAt: now },
        });

        // Broadcast to other chat members in room so sender sees blue ticks & last seen marker
        socket.to(`chat:${chatId}`).emit(SOCKET_EVENTS.MESSAGE_READ, {
          chatId,
          readerId: userId,
          lastReadMessageId,
          readAt: now,
        });

        // Invalidate Redis caches
        await Promise.all([
          CacheService.delPattern(`chat:messages:${chatId}:*`),
          CacheService.delPattern('user:chats:*'),
        ]);
      } catch (err) {
        logger.error('Error handling message read event:', err);
      }
    }
  );

  // 6. Typing indicators
  socket.on(SOCKET_EVENTS.TYPING_START, ({ chatId }: { chatId: string }) => {
    socket.to(`chat:${chatId}`).emit(SOCKET_EVENTS.TYPING_START, { chatId, userId });
  });

  socket.on(SOCKET_EVENTS.TYPING_STOP, ({ chatId }: { chatId: string }) => {
    socket.to(`chat:${chatId}`).emit(SOCKET_EVENTS.TYPING_STOP, { chatId, userId });
  });

  // 7. LiveKit Group & 1-to-1 Call Signaling
  socket.on(
    SOCKET_EVENTS.CALL_INITIATE,
    async ({
      callId,
      chatId,
      callType = 'video',
    }: {
      callId: string;
      chatId: string;
      callType?: 'audio' | 'video';
    }) => {
      try {
        const [caller, chat] = await Promise.all([
          prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, name: true, avatar: true },
          }),
          prisma.chat.findUnique({
            where: { id: chatId },
            select: { id: true, name: true, isGroup: true },
          }),
        ]);

        if (!caller || !chat) return;

        // Broadcast incoming call event to all members in the chat room
        socket.to(`chat:${chatId}`).emit(SOCKET_EVENTS.CALL_INCOMING, {
          callId,
          chatId,
          caller: {
            id: caller.id,
            name: caller.name,
            avatar: caller.avatar,
          },
          callType,
          isGroup: chat.isGroup,
          chatName: chat.name || (chat.isGroup ? 'Group Call' : caller.name),
        });

        logger.info(`Call initiated: [${callId}] in chat [${chatId}] by [${userId}]`);
      } catch (err) {
        logger.error('Error handling call initiate:', err);
      }
    }
  );

  socket.on(SOCKET_EVENTS.CALL_ACCEPT, ({ callId, chatId }: { callId: string; chatId: string }) => {
    socket.to(`chat:${chatId}`).emit(SOCKET_EVENTS.CALL_ACCEPTED, {
      callId,
      chatId,
      userId,
    });
  });

  socket.on(
    SOCKET_EVENTS.CALL_REJECT,
    ({ callId, chatId, reason }: { callId: string; chatId: string; reason?: string }) => {
      socket.to(`chat:${chatId}`).emit(SOCKET_EVENTS.CALL_REJECTED, {
        callId,
        chatId,
        userId,
        reason: reason || 'declined',
      });
    }
  );

  socket.on(SOCKET_EVENTS.CALL_END, ({ callId, chatId }: { callId: string; chatId: string }) => {
    socket.to(`chat:${chatId}`).emit(SOCKET_EVENTS.CALL_ENDED, {
      callId,
      chatId,
      userId,
    });
  });

  // 8. Disconnection
  socket.on(SOCKET_EVENTS.DISCONNECT, () => {
    logger.info(`User disconnected from socket: [${userId}]`);
    PresenceService.setUserOffline(userId);
    socket.broadcast.emit(SOCKET_EVENTS.USER_OFFLINE, {
      userId,
      lastSeen: new Date(),
    });
  });
};
