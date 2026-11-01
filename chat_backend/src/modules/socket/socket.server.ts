import { Server as HttpServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { socketAuthMiddleware, AuthenticatedSocket } from './socket.auth.js';
import { registerSocketHandlers } from './socket.handler.js';
import { ENV } from '../../config/env.js';
import { logger } from '../../utils/logger.js';

let io: SocketIOServer | null = null;

export const initSocketServer = (httpServer: HttpServer): SocketIOServer => {
  io = new SocketIOServer(httpServer, {
    cors: {
      origin: ENV.CLIENT_URL === '*' ? '*' : [ENV.CLIENT_URL],
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
  });

  // Apply authentication middleware
  io.use(socketAuthMiddleware as any);

  // Connection handler
  io.on('connection', (socket: AuthenticatedSocket) => {
    registerSocketHandlers(io!, socket);
  });

  logger.info('Socket.IO real-time server initialized');
  return io;
};

export const getIO = (): SocketIOServer => {
  if (!io) {
    throw new Error('Socket.io has not been initialized yet');
  }
  return io;
};

export const emitToChat = (chatId: string, event: string, data: unknown) => {
  if (io) {
    io.to(`chat:${chatId}`).emit(event, data);
  }
};

export const emitToUser = (userId: string, event: string, data: unknown) => {
  if (io) {
    io.to(`user:${userId}`).emit(event, data);
  }
};

