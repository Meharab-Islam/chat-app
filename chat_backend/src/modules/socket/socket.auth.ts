import { Socket } from 'socket.io';
import { verifyToken, TokenPayload } from '../../utils/token.js';
import { logger } from '../../utils/logger.js';

export interface AuthenticatedSocket extends Socket {
  user?: TokenPayload;
}

export const socketAuthMiddleware = (
  socket: AuthenticatedSocket,
  next: (err?: Error) => void
) => {
  try {
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.headers?.authorization?.replace('Bearer ', '');

    if (!token) {
      return next(new Error('Authentication token missing'));
    }

    const payload = verifyToken(token);
    socket.user = payload;
    next();
  } catch (error) {
    logger.warn('Socket connection rejected due to invalid token');
    next(new Error('Unauthorized socket connection'));
  }
};

