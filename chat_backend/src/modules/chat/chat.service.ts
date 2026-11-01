import { prisma } from '../../config/database.js';
import { CacheService } from '../../services/cache.service.js';
import { REDIS_KEYS, CACHE_TTL } from '../../config/constants.js';

export class ChatService {
  /**
   * Get user chat list - Served directly from Redis Cache
   */
  static async getUserChats(userId: string) {
    const cacheKey = REDIS_KEYS.USER_CHATS(userId);

    return CacheService.getOrSet(
      cacheKey,
      async () => {
        const chats = await prisma.chat.findMany({
          where: { members: { some: { userId } } },
          include: {
            members: {
              include: {
                user: {
                  select: {
                    id: true,
                    name: true,
                    avatarUrl: true,
                    isOnline: true,
                    lastSeen: true,
                  },
                },
              },
            },
            messages: {
              where: { deletedFor: { none: { userId } } },
              orderBy: { createdAt: 'desc' },
              take: 1,
              include: {
                attachments: true,
                sender: { select: { id: true, name: true } },
              },
            },
          },
          orderBy: { updatedAt: 'desc' },
        });

        return chats.map((chat) => {
          const myMembership = chat.members.find((m) => m.userId === userId);
          const otherMembers = chat.members.filter((m) => m.userId !== userId);
          const lastMsg = chat.messages[0] || null;

          return {
            id: chat.id,
            type: chat.type,
            name: chat.type === 'direct' ? otherMembers[0]?.user.name : chat.name,
            avatarUrl:
              chat.type === 'direct'
                ? otherMembers[0]?.user.avatarUrl
                : chat.avatarUrl,
            otherUser: chat.type === 'direct' ? otherMembers[0]?.user : null,
            members: chat.members,
            lastReadMessageId: myMembership?.lastReadMessageId || null,
            lastReadAt: myMembership?.lastReadAt || null,
            lastMessage: lastMsg
              ? {
                  id: lastMsg.id,
                  text: lastMsg.isUnsent ? 'This message was unsent' : lastMsg.text,
                  type: lastMsg.type,
                  status: lastMsg.status,
                  sender: lastMsg.sender,
                  createdAt: lastMsg.createdAt,
                  isUnsent: lastMsg.isUnsent,
                  hasAttachments: lastMsg.attachments.length > 0,
                }
              : null,
            updatedAt: chat.updatedAt,
          };
        });
      },
      CACHE_TTL.USER_CHATS
    );
  }

  /**
   * Get or create 1-on-1 direct chat
   */
  static async getOrCreateDirectChat(userId: string, recipientId: string) {
    if (userId === recipientId) {
      throw new Error('Cannot create chat with yourself');
    }

    const existing = await prisma.chat.findFirst({
      where: {
        type: 'direct',
        AND: [
          { members: { some: { userId } } },
          { members: { some: { userId: recipientId } } },
        ],
      },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, name: true, avatarUrl: true, isOnline: true },
            },
          },
        },
      },
    });

    if (existing) return existing;

    const newChat = await prisma.chat.create({
      data: {
        type: 'direct',
        members: {
          create: [{ userId, role: 'member' }, { userId: recipientId, role: 'member' }],
        },
      },
      include: {
        members: {
          include: {
            user: { select: { id: true, name: true, avatarUrl: true, isOnline: true } },
          },
        },
      },
    });

    await Promise.all([
      CacheService.del(REDIS_KEYS.USER_CHATS(userId)),
      CacheService.del(REDIS_KEYS.USER_CHATS(recipientId)),
    ]);

    return newChat;
  }

  /**
   * Create group chat
   */
  static async createGroupChat(userId: string, name: string, memberIds: string[]) {
    const allMembers = Array.from(new Set([userId, ...memberIds]));

    const groupChat = await prisma.chat.create({
      data: {
        type: 'group',
        name,
        members: {
          create: allMembers.map((id) => ({
            userId: id,
            role: id === userId ? 'admin' : 'member',
          })),
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, name: true, avatarUrl: true, isOnline: true },
            },
          },
        },
      },
    });

    await Promise.all(
      allMembers.map((mId) => CacheService.del(REDIS_KEYS.USER_CHATS(mId)))
    );

    return groupChat;
  }

  /**
   * Get chat details (served from Redis Cache)
   */
  static async getChatDetails(chatId: string) {
    const cacheKey = REDIS_KEYS.CHAT_DETAILS(chatId);

    return CacheService.getOrSet(
      cacheKey,
      async () => {
        const chat = await prisma.chat.findUnique({
          where: { id: chatId },
          include: {
            members: {
              include: {
                user: {
                  select: {
                    id: true,
                    name: true,
                    avatarUrl: true,
                    status: true,
                    isOnline: true,
                    lastSeen: true,
                  },
                },
              },
            },
          },
        });
        if (!chat) throw new Error('Chat not found');
        return chat;
      },
      CACHE_TTL.CHAT_DETAILS
    );
  }

  /**
   * Delete or leave chat for user
   */
  static async deleteChat(userId: string, chatId: string) {
    const member = await prisma.chatMember.findFirst({
      where: { chatId, userId },
    });
    if (!member) throw new Error('Not a member of this chat');

    await prisma.chatMember.deleteMany({
      where: { chatId, userId },
    });

    const messages = await prisma.message.findMany({
      where: { chatId },
      select: { id: true },
    });

    if (messages.length > 0) {
      await prisma.deletedMessage.createMany({
        data: messages.map((m) => ({ messageId: m.id, userId })),
        skipDuplicates: true,
      });
    }

    const remaining = await prisma.chatMember.count({ where: { chatId } });
    if (remaining === 0) {
      await prisma.chat.delete({ where: { id: chatId } });
    }

    await Promise.all([
      CacheService.del(REDIS_KEYS.USER_CHATS(userId)),
      CacheService.del(REDIS_KEYS.CHAT_DETAILS(chatId)),
      CacheService.delPattern(`chat:messages:${chatId}:*`),
    ]);

    return { chatId, deleted: true };
  }
}
