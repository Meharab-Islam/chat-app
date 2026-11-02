export const SOCKET_EVENTS = {
  // Connection
  CONNECT: 'connect',
  DISCONNECT: 'disconnect',

  // Chat Rooms
  JOIN_CHAT: 'chat:join',
  LEAVE_CHAT: 'chat:leave',
  CHAT_UPDATED: 'chat:updated',

  // Messages Status & Delivery
  MESSAGE_NEW: 'message:new',
  MESSAGE_DELIVERED: 'message:delivered',
  MESSAGE_READ: 'message:read',
  MESSAGE_UNSENT: 'message:unsent',
  MESSAGE_REACTION: 'message:reaction',

  // Typing
  TYPING_START: 'typing:start',
  TYPING_STOP: 'typing:stop',

  // Presence
  USER_ONLINE: 'presence:user_online',
  USER_OFFLINE: 'presence:user_offline',
  PRESENCE_QUERY: 'presence:query',
};
