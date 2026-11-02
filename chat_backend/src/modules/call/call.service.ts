import { AccessToken } from 'livekit-server-sdk';
import { prisma } from '../../config/database.js';
import { ENV } from '../../config/env.js';

export class CallError extends Error {
  statusCode: number;
  constructor(statusCode: number, message: string) {
    super(message);
    this.statusCode = statusCode;
  }
}

export class CallService {
  /**
   * Generates a signed LiveKit AccessToken for joining a group or direct call
   */
  static async generateToken(userId: string, chatId: string, callType: 'audio' | 'video' = 'video') {
    // 1. Verify user exists
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, name: true, avatar: true },
    });

    if (!user) {
      throw new CallError(404, 'User not found');
    }

    // 2. Verify chat membership
    const membership = await prisma.chatMember.findUnique({
      where: {
        chatId_userId: { chatId, userId },
      },
      include: {
        chat: {
          select: { id: true, isGroup: true, name: true },
        },
      },
    });

    if (!membership) {
      throw new CallError(403, 'You are not a member of this chat');
    }

    // 3. Room name is based on chatId
    const roomName = `room_${chatId}`;

    // 4. Create Access Token
    const at = new AccessToken(ENV.LIVEKIT_API_KEY, ENV.LIVEKIT_API_SECRET, {
      identity: user.id,
      name: user.name,
      metadata: JSON.stringify({
        avatar: user.avatar,
        callType,
      }),
      ttl: '2h',
    });

    at.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    const token = await at.toJwt();

    return {
      token,
      url: ENV.LIVEKIT_URL,
      roomName,
      callType,
      user: {
        id: user.id,
        name: user.name,
        avatar: user.avatar,
      },
      chat: {
        id: membership.chat.id,
        name: membership.chat.name,
        isGroup: membership.chat.isGroup,
      },
    };
  }
}
