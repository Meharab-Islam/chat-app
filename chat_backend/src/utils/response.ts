import { Response } from 'express';

export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  errors?: unknown;
}

export const sendSuccess = <T>(
  res: Response,
  data?: T,
  message = 'Success',
  statusCode = 200
): Response => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

export const sendError = (
  res: Response,
  message = 'An error occurred',
  statusCode = 500,
  errors?: unknown
): Response => {
  return res.status(statusCode).json({
    success: false,
    message,
    errors,
  });
};

