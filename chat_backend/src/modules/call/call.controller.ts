import { Response } from 'express';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';
import { CallService } from './call.service.js';
import { sendSuccess, sendError } from '../../utils/response.js';

export class CallController {
  static async getToken(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        return sendError(res, 'Unauthorized', 401);
      }

      const { chatId, callType = 'video' } = req.body;
      if (!chatId) {
        return sendError(res, 'chatId is required', 400);
      }

      const tokenData = await CallService.generateToken(
        userId,
        chatId,
        callType === 'audio' ? 'audio' : 'video'
      );

      return sendSuccess(res, tokenData, 'Call token generated successfully');
    } catch (err: any) {
      return sendError(res, err.message || 'Failed to generate call token', err.statusCode || 500);
    }
  }
}
