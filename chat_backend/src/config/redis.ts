import { Redis } from 'ioredis';
import { ENV } from './env.js';
import { logger } from '../utils/logger.js';

let redisClient: Redis | null = null;
let isRedisConnected = false;

// In-memory fallback cache when Redis is unavailable
const memoryFallback = new Map<string, { value: string; expiresAt: number | null }>();

export const getRedisClient = (): Redis => {
  if (!redisClient) {
    const options = {
      host: ENV.REDIS_HOST,
      port: ENV.REDIS_PORT,
      password: ENV.REDIS_PASSWORD,
      retryStrategy: (times: number) => {
        if (times > 3) {
          return null; // Stop retrying if Redis is not running locally; use in-memory fallback
        }
        return Math.min(times * 500, 2000);
      },
      maxRetriesPerRequest: 3,
      lazyConnect: true,
    };

    redisClient = ENV.REDIS_URL ? new Redis(ENV.REDIS_URL, options) : new Redis(options);

    redisClient.on('connect', () => {
      isRedisConnected = true;
      logger.info('Connected to Redis Cache');
    });

    redisClient.on('ready', () => {
      isRedisConnected = true;
    });

    redisClient.on('error', (err: any) => {
      isRedisConnected = false;
      logger.warn(`Redis connection error (fallback in-memory active): ${err.message}`);
    });

    redisClient.on('close', () => {
      isRedisConnected = false;
    });
  }

  return redisClient;
};

export const initRedis = async (): Promise<void> => {
  try {
    const client = getRedisClient();
    await client.connect();
  } catch (err) {
    logger.warn('Initial Redis connect failed, memory fallback will be used.');
  }
};

export const isRedisReady = (): boolean => isRedisConnected;
export const getMemoryFallback = () => memoryFallback;
