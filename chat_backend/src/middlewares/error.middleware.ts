import { Request, Response, NextFunction } from 'express';
import { MulterError } from 'multer';
import { sendError } from '../utils/response.js';
import { logger } from '../utils/logger.js';

export const notFoundHandler = (req: Request, res: Response): void => {
  sendError(res, `Route not found: ${req.method} ${req.originalUrl}`, 404);
};

export const errorHandler = (
  err: any,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  logger.error('Unhandled API Error:', err);

  if (err instanceof MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      sendError(res, 'File size exceeds maximum allowed limit', 400);
      return;
    }
    if (err.code === 'LIMIT_FILE_COUNT') {
      sendError(res, 'Too many files uploaded in a single request', 400);
      return;
    }
    sendError(res, `File upload error: ${err.message}`, 400);
    return;
  }

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';
  sendError(res, message, statusCode);
};

