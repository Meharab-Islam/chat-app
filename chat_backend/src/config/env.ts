import dotenv from 'dotenv';
dotenv.config();

export const ENV = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: parseInt(process.env.PORT || '5050', 10),
  CLIENT_URL: process.env.CLIENT_URL || '*',
  
  // Database
  DATABASE_URL: process.env.DATABASE_URL || 'mysql://root:rootpassword@localhost:3306/chat_db',
  
  // Redis
  REDIS_URL: process.env.REDIS_URL || 'redis://localhost:6379',
  REDIS_HOST: process.env.REDIS_HOST || 'localhost',
  REDIS_PORT: parseInt(process.env.REDIS_PORT || '6379', 10),
  REDIS_PASSWORD: process.env.REDIS_PASSWORD || undefined,

  // Google OAuth
  GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID || '',

  // JWT
  JWT_SECRET: process.env.JWT_SECRET || 'super-secret-jwt-token-key-change-in-production',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
  JWT_REFRESH_EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN || '30d',

  // Upload Limits
  MAX_FILE_SIZE_MB: parseInt(process.env.MAX_FILE_SIZE_MB || '500', 10),
  MAX_FILES_PER_REQUEST: parseInt(process.env.MAX_FILES_PER_REQUEST || '10', 10),
  UPLOAD_DIR: process.env.UPLOAD_DIR || 'uploads',

  // LiveKit Group Calling
  LIVEKIT_URL: process.env.LIVEKIT_URL || 'wss://sp-live-77aj0nb6.livekit.cloud',
  LIVEKIT_API_KEY: process.env.LIVEKIT_API_KEY || 'API8RXeTebwtkfg',
  LIVEKIT_API_SECRET: process.env.LIVEKIT_API_SECRET || 'G9lYenZnHxa5FUiXvkFBDa5n1a6WUq7hJecNA5OS8I0',
};
