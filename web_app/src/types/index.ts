export interface User {
  id: string;
  name: string;
  email: string;
  avatarUrl?: string;
  bio?: string;
  status?: string;
  isOnline?: boolean;
  lastSeen?: string;
}

export interface Attachment {
  id: string;
  fileName: string;
  fileUrl: string;
  fileType: 'image' | 'video' | 'audio' | 'pdf' | 'apk' | 'zip' | 'file';
  mimeType: string;
  fileSize: number;
}

export interface MessageReaction {
  id: string;
  messageId: string;
  userId: string;
  emoji: string;
  user?: { id: string; name: string };
}

export interface Message {
  id: string;
  chatId: string;
  senderId: string;
  text?: string;
  type: string;
  status: 'sent' | 'delivered' | 'read';
  deliveredAt?: string;
  readAt?: string;
  isForwarded?: boolean;
  isUnsent?: boolean;
  createdAt: string;
  replyToId?: string;
  replyTo?: { id: string; text?: string; sender: { id: string; name: string } };
  sender?: User;
  attachments?: Attachment[];
  reactions?: MessageReaction[];
}

export interface Chat {
  id: string;
  type: 'direct' | 'group';
  name?: string;
  avatarUrl?: string;
  otherUser?: User;
  lastMessage?: Message;
  unreadCount?: number;
  lastReadMessageId?: string;
  members?: Array<{ id: string; userId: string; role: string; user: User }>;
  updatedAt: string;
}

