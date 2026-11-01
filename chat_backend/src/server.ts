import http from 'http';
import { createApp } from './app.js';
import { ENV } from './config/env.js';
import { connectDatabase, prisma } from './config/database.js';
import { initRedis, getRedisClient } from './config/redis.js';
import { initSocketServer } from './modules/socket/socket.server.js';
import { logger } from './utils/logger.js';

const startServer = async () => {
  try {
    // 1. Connect to Database & Cache
    await connectDatabase();
    await initRedis();

    // 2. Setup Express & HTTP Server
    const app = createApp();
    const server = http.createServer(app);

    server.on('error', (err: any) => {
      logger.error('HTTP Server startup error:', err.message);
    });

    // 3. Setup WebSockets
    initSocketServer(server);

    // 4. Start Listening
    server.listen(ENV.PORT, '0.0.0.0', () => {
      logger.info(`Chat API Server is running on http://localhost:${ENV.PORT}`);
      logger.info(`Master API Router mounted at: http://localhost:${ENV.PORT}/api`);
      logger.info(`Router status endpoint: http://localhost:${ENV.PORT}/api/status`);
      logger.info(`Network URL: http://0.0.0.0:${ENV.PORT}/api`);
      logger.info(`Environment: ${ENV.NODE_ENV}`);
    });

    // 5. Graceful Shutdown
    const shutdown = async (signal: string) => {
      logger.info(`Received ${signal}. Gracefully shutting down...`);
      server.close(async () => {
        try {
          await prisma.$disconnect();
          const redis = getRedisClient();
          await redis.quit();
        } catch (_) {}
        logger.info('Cleaned up resources. Goodbye!');
        process.exit(0);
      });
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
