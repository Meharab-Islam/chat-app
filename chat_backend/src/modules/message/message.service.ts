import { prisma } from '../../config/database.js';
import { CacheService } from '../../services/cache.service.js';
import { REDIS_KEYS, CACHE_TTL } from '../../config/constants.js';
import { getFileCategory } from '../../utils/fileHelper.js';
import { emitToChat, emitToUser } from '../socket/socket.server.js';
import { SOCKET_EVENTS } from '../socket/socket.events.js';
import { FcmService } from '../../services/fcm.service.js';

export class MessageService {
  /**
   * Get chat messages - Served from Redis Cache first
   */
  static async getChatMessages(userId: string, chatId: string, page = 1, limit = 30) {
    const cacheKey = REDIS_KEYS.CHAT_MESSAGES(chatId, page);

    const messages = await CacheService.getOrSet(
      cacheKey,
      async () => {
        const rows = await prisma.message.findMany({
          where: { chatId },
          include: {
            sender: { select: { id: true, name: true, avatarUrl: true } },
            attachments: true,
            reactions: {
              include: { user: { select: { id: true, name: true } } },
            },
            replyTo: {
              select: {
                id: true,
                text: true,
                sender: { select: { id: true, name: true } },
              },
            },
            deletedFor: { select: { userId: true } },
          },
          orderBy: { createdAt: 'desc' },
          skip: (page - 1) * limit,
          take: limit,
        });
        return rows.reverse();
      },
      CACHE_TTL.CHAT_MESSAGES
    );

    return messages.filter(
      (msg: any) => !msg.deletedFor?.some((d: any) => d.userId === userId)
    );
  }

  /**
   * Send new message with optional multiple images, videos, ZIPs, or documents
   */
  static async sendMessage(
    senderId: string,
    chatId: string,
    text?: string,
    files: Express.Multer.File[] = [],
    replyToId?: string
  ) {
    if (!text && files.length === 0) {
      throw new Error('Message must have text or at least one attachment');
    }

    const attachmentsData = files.map((file) => {
      let subfolder = 'files';
      const category = getFileCategory(file.mimetype, file.originalname);
      if (category === 'image') subfolder = 'images';
      else if (category === 'video') subfolder = 'videos';
      else if (category === 'audio') subfolder = 'audio';

      return {
        fileName: file.originalname,
        fileUrl: `/uploads/${subfolder}/${file.filename}`,
        fileType: category,
        mimeType: file.mimetype,
        fileSize: file.size,
      };
    });

    let messageType = 'text';
    if (files.length > 0) {
      const firstCat = getFileCategory(files[0].mimetype, files[0].originalname);
      if (firstCat === 'audio') messageType = 'audio';
      else if (firstCat === 'image' || firstCat === 'video') messageType = 'media';
      else if (firstCat === 'pdf') messageType = 'pdf';
      else if (firstCat === 'apk') messageType = 'apk';
      else if (firstCat === 'zip') messageType = 'zip';
      else messageType = 'file';
    }

    const message = await prisma.message.create({
      data: {
        chatId,
        senderId,
        text: text || null,
        type: messageType,
        replyToId: replyToId || null,
        attachments: { create: attachmentsData },
      },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
        attachments: true,
        reactions: true,
        replyTo: {
          select: {
            id: true,
            text: true,
            sender: { select: { id: true, name: true } },
          },
        },
      },
    });

    await prisma.chat.update({
      where: { id: chatId },
      data: { updatedAt: new Date() },
    });

    await Promise.all([
      CacheService.delPattern(`chat:messages:${chatId}:*`),
      CacheService.delPattern('user:chats:*'),
    ]);

    emitToChat(chatId, SOCKET_EVENTS.MESSAGE_NEW, message);

    // Send FCM high-priority background data notification to other members
    prisma.chatMember.findMany({
      where: { chatId, userId: { not: senderId } },
      include: { user: true },
    }).then((members) => {
      const firstImage = message.attachments?.find((a: any) => a.fileType === 'IMAGE');
      const imagePreviewUrl = firstImage?.fileUrl;
      const bodyText = text || (firstImage ? 'Sent a photo' : files.length > 0 ? 'Sent an attachment' : 'New message');
      for (const m of members) {
        emitToUser(m.userId, SOCKET_EVENTS.MESSAGE_NEW, message);
        const user = m.user as any;
        if (user?.fcmToken) {
          FcmService.sendNotification({
            token: user.fcmToken,
            title: message.sender.name,
            body: bodyText,
            imageUrl: imagePreviewUrl,
            data: {
              type: 'NEW_MESSAGE',
              messageId: message.id,
              chatId,
            },
          }).catch(() => {});
        }
      }
    }).catch(() => {});

    return message;
  }

  /**
   * Forward message without re-downloading or re-uploading
   */
  static async forwardMessage(
    senderId: string,
    messageId: string,
    targetChatIds: string[],
    customText?: string
  ) {
    const original = await prisma.message.findUnique({
      where: { id: messageId },
      include: { attachments: true },
    });
    if (!original) throw new Error('Original message not found');

    const forwardedMessages = [];

    for (const targetChatId of targetChatIds) {
      const msg = await prisma.message.create({
        data: {
          chatId: targetChatId,
          senderId,
          text: customText || original.text,
          type: original.type,
          isForwarded: true,
          attachments: {
            create: original.attachments.map((att) => ({
              fileName: att.fileName,
              fileUrl: att.fileUrl,
              fileType: att.fileType,
              mimeType: att.mimeType,
              fileSize: att.fileSize,
            })),
          },
        },
        include: {
          sender: { select: { id: true, name: true, avatarUrl: true } },
          attachments: true,
          reactions: true,
        },
      });

      await prisma.chat.update({
        where: { id: targetChatId },
        data: { updatedAt: new Date() },
      });

      await Promise.all([
        CacheService.delPattern(`chat:messages:${targetChatId}:*`),
        CacheService.delPattern('user:chats:*'),
      ]);

      emitToChat(targetChatId, SOCKET_EVENTS.MESSAGE_NEW, msg);
      forwardedMessages.push(msg);
    }

    return forwardedMessages;
  }

  /**
   * Search messages within a specific conversation
   */
  static async searchMessages(userId: string, chatId: string, query: string) {
    if (!query || !query.trim()) return [];

    return prisma.message.findMany({
      where: {
        chatId,
        isUnsent: false,
        text: { contains: query.trim() },
        deletedFor: { none: { userId } },
      },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
        attachments: true,
        reactions: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }
}
