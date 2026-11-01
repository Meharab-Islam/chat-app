import { Request, Response } from 'express';
import { AuthService } from './auth.service.js';
import { sendSuccess, sendError } from '../../utils/response.js';
import { verifyToken, generateAccessToken } from '../../utils/token.js';

export class AuthController {
  /**
   * Google OAuth2 Login
   */
  static async googleLogin(req: Request, res: Response): Promise<void> {
    try {
      const { idToken } = req.body;
      const result = await AuthService.loginWithGoogle(idToken);
      sendSuccess(res, result, 'Successfully authenticated with Google', 200);
    } catch (error: any) {
      sendError(res, error.message || 'Google login failed', 400);
    }
  }

  /**
   * Quick Login for Web
   */
  static async quickLogin(req: Request, res: Response): Promise<void> {
    try {
      const { email, name, avatarUrl } = req.body;
      if (!email) {
        sendError(res, 'Email is required', 400);
        return;
      }
      const result = await AuthService.quickLogin(email, name, avatarUrl);
      sendSuccess(res, result, 'Quick login successful', 200);
    } catch (error: any) {
      sendError(res, error.message || 'Login failed', 400);
    }
  }

  /**
   * Refresh expired access token using valid refresh token
   */
  static async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      const { refreshToken } = req.body;
      const payload = verifyToken(refreshToken);
      const newAccessToken = generateAccessToken({
        userId: payload.userId,
        email: payload.email,
      });

      sendSuccess(res, { accessToken: newAccessToken }, 'Token refreshed', 200);
    } catch (error) {
      sendError(res, 'Invalid or expired refresh token', 401);
    }
  }
}

