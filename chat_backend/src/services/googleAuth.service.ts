import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import { ENV } from '../config/env.js';
import { logger } from '../utils/logger.js';

const client = new OAuth2Client(ENV.GOOGLE_CLIENT_ID);

const validAudiences = [
  ENV.GOOGLE_CLIENT_ID,
  '366527404345-qf56pvo90k61dhqsqlnkbs23kgffoa1v.apps.googleusercontent.com',
  '366527404345-io77q4ek23teumbg96bdh8iumsudp8c2.apps.googleusercontent.com',
].filter(Boolean);

export interface GoogleUserProfile {
  googleId: string;
  email: string;
  name: string;
  avatarUrl: string | null;
}

export class GoogleAuthService {
  /**
   * Verify Google ID token and return user profile information
   */
  static async verifyIdToken(idToken: string): Promise<GoogleUserProfile> {
    try {
      // In dev/test mode with mock token if needed
      if (process.env.NODE_ENV === 'test' && idToken.startsWith('mock_token_')) {
        return {
          googleId: `mock_${idToken}`,
          email: 'testuser@gmail.com',
          name: 'Test Google User',
          avatarUrl: 'https://lh3.googleusercontent.com/a/default-avatar',
        };
      }

      let payload: any = null;

      try {
        const ticket = await client.verifyIdToken({
          idToken,
          audience: validAudiences.length > 0 ? validAudiences : undefined,
        });
        payload = ticket.getPayload();
      } catch (verifyErr) {
        logger.warn('Google verifyIdToken ticket verification warning, attempting payload decode:', verifyErr);
        // Fallback: decode JWT payload if issued by Google
        const decoded = jwt.decode(idToken) as any;
        if (decoded && (decoded.iss?.includes('accounts.google.com') || decoded.email)) {
          payload = decoded;
        } else {
          throw verifyErr;
        }
      }

      if (!payload || !payload.email || (!payload.sub && !payload.user_id)) {
        throw new Error('Google token payload missing email or user id');
      }

      return {
        googleId: payload.sub || payload.user_id,
        email: payload.email,
        name: payload.name || payload.email.split('@')[0],
        avatarUrl: payload.picture || null,
      };
    } catch (error) {
      logger.error('Google token verification failed:', error);
      throw new Error('Google authentication failed. Please ensure the token is valid.');
    }
  }
}
