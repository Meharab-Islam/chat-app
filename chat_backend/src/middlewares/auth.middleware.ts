import { Request, Response, NextFunction } from 'express';
import { verifyToken, TokenPayload } from '../utils/token.js';
import { sendError } from '../utils/response.js';

export interface AuthenticatedRequest extends Request {
  user?: TokenPayload;
}

export const authenticate = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    sendError(res, 'Authentication token missing or invalid format', 401);
    return;
  }

  const token = authHeader.split(' ')[1];
  try {
    const payload = verifyToken(token);
    req.user = payload;
    next();
  } catch (error) {
    sendError(res, 'Invalid or expired authentication token', 401);
  }
};

