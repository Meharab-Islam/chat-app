import { prisma } from '../../config/database.js';
import { CacheService } from '../../services/cache.service.js';
import { REDIS_KEYS, CACHE_TTL } from '../../config/constants.js';

export class UserService {
  /**
   * Get User Profile - Served directly from Redis Cache
   */
  static async getProfile(userId: string) {
    const cacheKey = REDIS_KEYS.USER_PROFILE(userId);

    return CacheService.getOrSet(
      cacheKey,
      async () => {
        const user = await prisma.user.findUnique({
          where: { id: userId },
          select: {
            id: true,
            email: true,
            name: true,
            avatarUrl: true,
            bio: true,
            status: true,
            isOnline: true,
            lastSeen: true,
            createdAt: true,
          },
        });
        if (!user) throw new Error('User not found');
        return user;
      },
      CACHE_TTL.USER_PROFILE
    );
  }

  /**
   * Get User Settings - Served directly from Redis Cache
   */
  static async getSettings(userId: string) {
    const cacheKey = REDIS_KEYS.USER_SETTINGS(userId);

    return CacheService.getOrSet(
      cacheKey,
      async () => {
        let settings = await prisma.userSettings.findUnique({
          where: { userId },
        });

        if (!settings) {
          settings = await prisma.userSettings.create({
            data: { userId, autoSaveToGallery: true, mediaAutoDownload: 'all' },
          });
        }
        return settings;
      },
      CACHE_TTL.USER_SETTINGS
    );
  }

  /**
   * Update Profile:
   * 1. Save to Database first
   * 2. Update Redis Cache immediately
   */
  static async updateProfile(
    userId: string,
    data: { name?: string; bio?: string; status?: string; avatarUrl?: string }
  ) {
    // 1. MySQL write first
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        bio: true,
        status: true,
        isOnline: true,
        lastSeen: true,
        createdAt: true,
      },
    });

    // 2. Update Redis Cache immediately
    await CacheService.set(
      REDIS_KEYS.USER_PROFILE(userId),
      updatedUser,
      CACHE_TTL.USER_PROFILE
    );

    return updatedUser;
  }

  /**
   * Update Avatar Image:
   * 1. Save new path in Database first
   * 2. Update Redis Cache immediately
   */
  static async updateAvatar(userId: string, avatarUrl: string) {
    // 1. Save to MySQL first
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { avatarUrl },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        bio: true,
        status: true,
      },
    });

    // 2. Sync to Redis Cache
    await CacheService.set(
      REDIS_KEYS.USER_PROFILE(userId),
      updatedUser,
      CACHE_TTL.USER_PROFILE
    );

    return updatedUser;
  }

  /**
   * Update User Settings (e.g. Auto-save to gallery on/off)
   * 1. Save to MySQL first
   * 2. Update Redis Cache immediately
   */
  static async updateSettings(
    userId: string,
    data: {
      autoSaveToGallery?: boolean;
      mediaAutoDownload?: string;
      notifications?: boolean;
    }
  ) {
    // 1. Save to Database first
    const updatedSettings = await prisma.userSettings.upsert({
      where: { userId },
      create: {
        userId,
        autoSaveToGallery: data.autoSaveToGallery ?? true,
        mediaAutoDownload: data.mediaAutoDownload ?? 'all',
        notifications: data.notifications ?? true,
      },
      update: data,
    });

    // 2. Sync to Redis Cache immediately
    await CacheService.set(
      REDIS_KEYS.USER_SETTINGS(userId),
      updatedSettings,
      CACHE_TTL.USER_SETTINGS
    );

    return updatedSettings;
  }

  static async updateFcmToken(userId: string, fcmToken: string) {
    return prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
  }

  /**
   * Search users by name or email
   */
  static async searchUsers(query: string, excludeUserId: string) {
    return prisma.user.findMany({
      where: {
        AND: [
          { id: { not: excludeUserId } },
          {
            OR: [
              { name: { contains: query } },
              { email: { contains: query } },
            ],
          },
        ],
      },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        status: true,
        isOnline: true,
      },
      take: 20,
    });
  }
}

