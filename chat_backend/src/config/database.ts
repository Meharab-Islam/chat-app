import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger.js';

declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined;
}

export const prisma =
  global.__prisma ||
  new PrismaClient({
    log:
      process.env.NODE_ENV === 'development'
        ? ['warn', 'error']
        : ['error'],
  });

if (process.env.NODE_ENV !== 'production') {
  global.__prisma = prisma;
}

export const connectDatabase = async (): Promise<void> => {
  try {
    await prisma.$connect();
    logger.info('Connected to MySQL database via Prisma');
  } catch (error) {
    logger.error('Failed to connect to MySQL database:', error);
  }
};

