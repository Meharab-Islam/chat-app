import { Response } from 'express';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';
import { MessageService } from './message.service.js';
import { MessageActionService } from './message.action.service.js';
import { sendSuccess, sendError } from '../../utils/response.js';

export class MessageController {
  /**
   * Get chat messages (served from Redis Cache)
   */
  static async getMessages(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const chatId = req.params.chatId as string;
      const page = parseInt((req.query.page as string) || '1', 10);
      const limit = parseInt((req.query.limit as string) || '30', 10);

      const messages = await MessageService.getChatMessages(userId, chatId, page, limit);
      sendSuccess(res, messages, 'Messages retrieved');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch messages', 400);
    }
  }

  /**
   * Search messages within chat
   */
  static async searchMessages(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const chatId = req.params.chatId as string;
      const query = (req.query.q as string) || '';
      const messages = await MessageService.searchMessages(userId, chatId, query);
      sendSuccess(res, messages, 'Search results');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to search messages', 400);
    }
  }

  /**
   * Mark all unread messages as read
   */
  static async markAsRead(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const chatId = req.params.chatId as string;
      const { lastReadMessageId } = req.body || {};
      const result = await MessageActionService.markAsRead(userId, chatId, lastReadMessageId);
      sendSuccess(res, result, 'Messages marked as read');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to mark as read', 400);
    }
  }

  /**
   * Send new message with text and/or multiple images, videos, zip, files
   */
  static async sendMessage(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const senderId = req.user!.userId;
      const { chatId, text, replyToId } = req.body;
      const files = (req.files as Express.Multer.File[]) || [];

      const message = await MessageService.sendMessage(
        senderId,
        chatId,
        text,
        files,
        replyToId
      );

      sendSuccess(res, message, 'Message sent successfully', 201);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to send message', 400);
    }
  }

  /**
   * Forward message without downloading
   */
  static async forwardMessage(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const senderId = req.user!.userId;
      const { messageId, targetChatIds, text } = req.body;

      const forwarded = await MessageService.forwardMessage(
        senderId,
        messageId,
        targetChatIds,
        text
      );

      sendSuccess(res, forwarded, 'Message forwarded successfully', 200);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to forward message', 400);
    }
  }

  /**
   * Unsend message (delete for everyone)
   */
  static async unsend(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const id = req.params.id as string;
      const result = await MessageActionService.unsendMessage(userId, id);
      sendSuccess(res, result, 'Message unsent');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to unsend message', 400);
    }
  }

  /**
   * Delete message for me
   */
  static async deleteForMe(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const id = req.params.id as string;
      const result = await MessageActionService.deleteForMe(userId, id);
      sendSuccess(res, result, 'Message deleted for you');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to delete message', 400);
    }
  }

  /**
   * React to message with emoji
   */
  static async react(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const id = req.params.id as string;
      const { emoji } = req.body;
      const result = await MessageActionService.reactToMessage(userId, id, emoji);
      sendSuccess(res, result, 'Reaction updated');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to update reaction', 400);
    }
  }

  /**
   * Background delivery acknowledgement (called by FCM background handler when app is killed)
   */
  static async ackDelivery(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const recipientId = req.user!.userId;
      const { messageId } = req.body;
      if (!messageId) {
        sendError(res, 'messageId is required', 400);
        return;
      }
      const result = await MessageActionService.acknowledgeDelivery(recipientId, messageId);
      sendSuccess(res, result, 'Delivery acknowledged');
    } catch (error: any) {
      sendError(res, error.message || 'Failed to acknowledge delivery', 400);
    }
  }
}
