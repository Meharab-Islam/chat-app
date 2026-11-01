import { prisma } from '../../config/database.js';
import { GoogleAuthService } from '../../services/googleAuth.service.js';
import { CacheService } from '../../services/cache.service.js';
import { REDIS_KEYS, CACHE_TTL } from '../../config/constants.js';
import { generateAccessToken, generateRefreshToken } from '../../utils/token.js';

export class AuthService {
  /**
   * Handle Google Single Sign-On
   * 1. Verifies Google ID Token
   * 2. Persists/updates user in MySQL database
   * 3. Syncs profile to Redis cache
   * 4. Returns JWT tokens and user profile
   */
  static async loginWithGoogle(idToken: string) {
    const googleProfile = await GoogleAuthService.verifyIdToken(idToken);

    // 1. Database operation first
    let user = await prisma.user.findFirst({
      where: {
        OR: [{ googleId: googleProfile.googleId }, { email: googleProfile.email }],
      },
      include: {
        settings: true,
      },
    });

    if (!user) {
      // Create new user and default settings
      user = await prisma.user.create({
        data: {
          email: googleProfile.email,
          googleId: googleProfile.googleId,
          name: googleProfile.name,
          avatarUrl: googleProfile.avatarUrl,
          settings: {
            create: {
              autoSaveToGallery: true,
              mediaAutoDownload: 'all',
              notifications: true,
            },
          },
        },
        include: {
          settings: true,
        },
      });
    } else {
      // Update existing user profile if changed
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          googleId: googleProfile.googleId,
          avatarUrl: user.avatarUrl || googleProfile.avatarUrl,
          lastSeen: new Date(),
        },
        include: {
          settings: true,
        },
      });
    }

    // 2. Update Redis Cache immediately (Write-Through)
    const { settings, ...profileData } = user;
    await CacheService.set(
      REDIS_KEYS.USER_PROFILE(user.id),
      profileData,
      CACHE_TTL.USER_PROFILE
    );

    if (settings) {
      await CacheService.set(
        REDIS_KEYS.USER_SETTINGS(user.id),
        settings,
        CACHE_TTL.USER_SETTINGS
      );
    }

    // 3. Issue Tokens
    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        status: user.status,
        settings,
      },
      tokens: {
        accessToken,
        refreshToken,
      },
    };
  }

  /**
   * Quick Sign-In for Web & Multi-Tab Testing
   */
  static async quickLogin(email: string, name?: string, avatarUrl?: string) {
    let user = await prisma.user.findFirst({
      where: { email },
      include: { settings: true },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email,
          googleId: `web_${Date.now()}_${Math.random().toString(36).substring(7)}`,
          name: name || email.split('@')[0],
          avatarUrl: avatarUrl || `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(name || email)}`,
          settings: {
            create: {
              autoSaveToGallery: true,
              mediaAutoDownload: 'all',
              notifications: true,
            },
          },
        },
        include: { settings: true },
      });
    }

    const { settings, ...profileData } = user;
    await CacheService.set(
      REDIS_KEYS.USER_PROFILE(user.id),
      profileData,
      CACHE_TTL.USER_PROFILE
    );

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        status: user.status,
        settings,
      },
      tokens: { accessToken, refreshToken },
    };
  }
}

