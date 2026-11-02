import { Response } from 'express';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';
import { UserService } from './user.service.js';
import { sendSuccess, sendError } from '../../utils/response.js';

export class UserController {
  /**
   * Get current authenticated user profile and settings
   */
  static async getMe(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const [profile, settings] = await Promise.all([
        UserService.getProfile(userId),
        UserService.getSettings(userId),
      ]);
      sendSuccess(res, { ...profile, settings }, 'Profile fetched successfully');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch user profile', 400);
    }
  }

  /**
   * Get any user profile by ID (cached)
   */
  static async getProfileById(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = req.params.id as string;
      const profile = await UserService.getProfile(id);
      sendSuccess(res, profile, 'User fetched successfully');
    } catch (error: any) {
      sendError(res, error.message || 'User not found', 404);
    }
  }

  /**
   * Update current user profile
   */
  static async updateProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const updated = await UserService.updateProfile(userId, req.body);
      sendSuccess(res, updated, 'Profile updated successfully');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to update profile', 400);
    }
  }

  /**
   * Update profile image
   */
  static async updateAvatar(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      if (!req.file) {
        sendError(res, 'No avatar image file uploaded', 400);
        return;
      }
      const avatarUrl = `/uploads/avatars/${req.file.filename}`;
      const updated = await UserService.updateAvatar(userId, avatarUrl);
      sendSuccess(res, updated, 'Avatar updated successfully');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to update avatar', 400);
    }
  }

  /**
   * Update settings (Auto-save to gallery, etc.)
   */
  static async updateSettings(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const updated = await UserService.updateSettings(userId, req.body);
      sendSuccess(res, updated, 'Settings updated successfully');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to update settings', 400);
    }
  }

  /**
   * Save device FCM push notification token
   */
  static async updateFcmToken(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const { fcmToken } = req.body;
      if (!fcmToken) {
        sendError(res, 'fcmToken is required', 400);
        return;
      }
      await UserService.updateFcmToken(userId, fcmToken);
      sendSuccess(res, null, 'FCM token updated');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to update FCM token', 400);
    }
  }

  /**
   * Search users to start new chat
   */
  static async searchUsers(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const query = ((req.query.q as string) || '').trim();
      const users = await UserService.searchUsers(query, req.user!.userId);
      sendSuccess(res, users, 'Users retrieved');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to search users', 400);
    }
  }
}
