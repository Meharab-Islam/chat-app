import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { sendError } from '../utils/response.js';

export const validateBody = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const formatted = error.issues.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        sendError(res, 'Validation error', 400, formatted);
        return;
      }
      sendError(res, 'Invalid request data', 400);
    }
  };
};

