export const REDIS_KEYS = {
  USER_PROFILE: (userId: string) => `user:profile:${userId}`,
  USER_SETTINGS: (userId: string) => `user:settings:${userId}`,
  USER_CHATS: (userId: string) => `user:chats:${userId}`,
  CHAT_DETAILS: (chatId: string) => `chat:details:${chatId}`,
  CHAT_MESSAGES: (chatId: string, page: number) => `chat:messages:${chatId}:page:${page}`,
  ONLINE_USERS: 'presence:online_users',
  USER_SOCKET: (userId: string) => `user:socket:${userId}`,
};

export const CACHE_TTL = {
  USER_PROFILE: 3600,      // 1 hour
  USER_SETTINGS: 3600,     // 1 hour
  USER_CHATS: 300,         // 5 minutes
  CHAT_DETAILS: 1800,      // 30 minutes
  CHAT_MESSAGES: 900,      // 15 minutes
  SEARCH_USERS: 300,       // 5 minutes
};

export const ALLOWED_FILE_CATEGORIES = {
  IMAGE: ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'],
  VIDEO: ['video/mp4', 'video/webm', 'video/quicktime', 'video/x-matroska', 'video/avi'],
  AUDIO: ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/aac', 'audio/m4a'],
  ARCHIVE: [
    'application/zip',
    'application/x-zip-compressed',
    'application/x-rar-compressed',
    'application/x-7z-compressed',
    'application/x-tar',
    'application/gzip',
  ],
};

