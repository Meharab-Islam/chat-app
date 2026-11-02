import { Response } from 'express';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';
import { ChatService } from './chat.service.js';
import { sendSuccess, sendError } from '../../utils/response.js';

export class ChatController {
  /**
   * Get all conversations for current user (served from Redis Cache)
   */
  static async getMyChats(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const chats = await ChatService.getUserChats(userId);
      sendSuccess(res, chats, 'Chats retrieved successfully');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch chats', 400);
    }
  }

  /**
   * Create or retrieve direct 1-on-1 chat
   */
  static async createDirectChat(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const { recipientId } = req.body;
      const chat = await ChatService.getOrCreateDirectChat(userId, recipientId);
      sendSuccess(res, chat, 'Direct chat initialized', 201);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to initialize direct chat', 400);
    }
  }

  /**
   * Create group chat
   */
  static async createGroupChat(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const { name, memberIds } = req.body;
      const chat = await ChatService.createGroupChat(userId, name, memberIds);
      sendSuccess(res, chat, 'Group chat created', 201);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to create group chat', 400);
    }
  }

  /**
   * Get chat details (served from Redis Cache)
   */
  static async getChatDetails(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = req.params.id as string;
      const chat = await ChatService.getChatDetails(id);
      sendSuccess(res, chat, 'Chat details retrieved');
    } catch (error: any) {
      sendError(res, error.message || 'Chat not found', 404);
    }
  }

  /**
   * Update group name or avatar - Any member can update
   */
  static async updateGroup(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const id = req.params.id as string;
      const name = req.body?.name as string | undefined;
      let avatarUrl = req.body?.avatarUrl as string | undefined;

      if (req.file) {
        avatarUrl = `/uploads/avatars/${req.file.filename}`;
      }

      const updated = await ChatService.updateGroup(userId, id, { name, avatarUrl });
      sendSuccess(res, updated, 'Group updated successfully');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to update group', 400);
    }
  }

  /**
   * Delete or leave chat
   */
  static async deleteChat(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const id = req.params.id as string;
      const result = await ChatService.deleteChat(userId, id);
      sendSuccess(res, result, 'Chat deleted successfully');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to delete chat', 400);
    }
  }
}
