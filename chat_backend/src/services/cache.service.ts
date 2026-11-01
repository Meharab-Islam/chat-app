import { getRedisClient, isRedisReady, getMemoryFallback } from '../config/redis.js';
import { logger } from '../utils/logger.js';

export class CacheService {
  /**
   * Get cached data by key
   */
  static async get<T>(key: string): Promise<T | null> {
    try {
      if (isRedisReady()) {
        const client = getRedisClient();
        const data = await client.get(key);
        if (!data) return null;
        return JSON.parse(data) as T;
      }

      // Memory fallback
      const fallback = getMemoryFallback();
      const entry = fallback.get(key);
      if (!entry) return null;
      if (entry.expiresAt && Date.now() > entry.expiresAt) {
        fallback.delete(key);
        return null;
      }
      return JSON.parse(entry.value) as T;
    } catch (err) {
      logger.error(`Cache get error for key [${key}]:`, err);
      return null;
    }
  }

  /**
   * Store data in cache with TTL (in seconds)
   */
  static async set(key: string, value: unknown, ttlSeconds = 300): Promise<void> {
    try {
      const serialized = JSON.stringify(value);
      if (isRedisReady()) {
        const client = getRedisClient();
        await client.set(key, serialized, 'EX', ttlSeconds);
        return;
      }

      // Memory fallback
      const fallback = getMemoryFallback();
      fallback.set(key, {
        value: serialized,
        expiresAt: ttlSeconds > 0 ? Date.now() + ttlSeconds * 1000 : null,
      });
    } catch (err) {
      logger.error(`Cache set error for key [${key}]:`, err);
    }
  }

  /**
   * Delete a cache key
   */
  static async del(key: string): Promise<void> {
    try {
      if (isRedisReady()) {
        const client = getRedisClient();
        await client.del(key);
        return;
      }
      getMemoryFallback().delete(key);
    } catch (err) {
      logger.error(`Cache del error for key [${key}]:`, err);
    }
  }

  /**
   * Delete all keys matching a pattern (e.g. chat:messages:123:*)
   */
  static async delPattern(pattern: string): Promise<void> {
    try {
      if (isRedisReady()) {
        const client = getRedisClient();
        const keys = await client.keys(pattern);
        if (keys.length > 0) {
          await client.del(...keys);
        }
        return;
      }

      const fallback = getMemoryFallback();
      const regex = new RegExp(`^${pattern.replace(/\*/g, '.*')}$`);
      for (const k of fallback.keys()) {
        if (regex.test(k)) {
          fallback.delete(k);
        }
      }
    } catch (err) {
      logger.error(`Cache delPattern error for [${pattern}]:`, err);
    }
  }

  /**
   * High performance Cache-Aside pattern:
   * 1. Checks Redis cache first
   * 2. If HIT -> returns cached data immediately
   * 3. If MISS -> calls fetcher, stores result in Redis with TTL, and returns
   */
  static async getOrSet<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttlSeconds = 300
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null && cached !== undefined) {
      return cached;
    }

    const freshData = await fetcher();
    if (freshData !== null && freshData !== undefined) {
      await this.set(key, freshData, ttlSeconds);
    }
    return freshData;
  }
}

