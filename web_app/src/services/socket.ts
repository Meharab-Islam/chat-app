import { io, Socket } from 'socket.io-client';
import { SERVER_URL } from './api';

let socket: Socket | null = null;

export const initSocket = (token: string): Socket => {
  if (socket) {
    socket.disconnect();
  }

  socket = io(SERVER_URL, {
    auth: { token },
    transports: ['websocket', 'polling'],
    reconnection: true,
    reconnectionAttempts: 10,
    reconnectionDelay: 1000,
  });

  socket.on('connect', () => {
    console.log('[Socket] Connected with ID:', socket?.id);
  });

  socket.on('disconnect', (reason) => {
    console.log('[Socket] Disconnected:', reason);
  });

  return socket;
};

export const getSocket = (): Socket | null => socket;

export const disconnectSocket = () => {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
};

