import jwt, { SignOptions } from 'jsonwebtoken';
import { ENV } from '../config/env.js';

export interface TokenPayload {
  userId: string;
  email: string;
}

export const generateAccessToken = (payload: TokenPayload): string => {
  const options: SignOptions = {
    expiresIn: ENV.JWT_EXPIRES_IN as any,
  };
  return jwt.sign(payload, ENV.JWT_SECRET, options);
};

export const generateRefreshToken = (payload: TokenPayload): string => {
  const options: SignOptions = {
    expiresIn: ENV.JWT_REFRESH_EXPIRES_IN as any,
  };
  return jwt.sign(payload, ENV.JWT_SECRET, options);
};

export const verifyToken = (token: string): TokenPayload => {
  return jwt.verify(token, ENV.JWT_SECRET) as TokenPayload;
};

