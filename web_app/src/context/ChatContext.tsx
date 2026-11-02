import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { Chat, Message } from '../types';
import { api } from '../services/api';
import { getSocket } from '../services/socket';
import { useAuth } from './AuthContext';
import { useChatSocket } from './useChatSocket';

interface ChatContextType {
  chats: Chat[];
  activeChat: Chat | null;
  messages: Message[];
  isLoadingChats: boolean;
  isLoadingMessages: boolean;
  isPeerTyping: boolean;
  activeFilter: 'all' | 'unread' | 'groups';
  setActiveFilter: (filter: 'all' | 'unread' | 'groups') => void;
  selectChat: (chat: Chat) => void;
  sendMessage: (
    text?: string,
    files?: File[],
    replyToId?: string,
    onProgress?: (pct: number, loaded: number, total: number) => void
  ) => Promise<void>;
  createDirectChat: (recipientId: string) => Promise<Chat>;
  createGroupChat: (name: string, memberIds: string[]) => Promise<Chat>;
  deleteChat: (chatId: string) => Promise<void>;
  markAsRead: (chatId: string) => Promise<void>;
  markAllAsRead: () => Promise<void>;
  unsendMessage: (messageId: string) => Promise<void>;
  deleteForMe: (messageId: string) => Promise<void>;
  reactToMessage: (messageId: string, emoji: string) => Promise<void>;
  emitTyping: (isTyping: boolean) => void;
  refreshChats: () => Promise<void>;
}

const ChatContext = createContext<ChatContextType | undefined>(undefined);

export const ChatProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const [chats, setChats] = useState<Chat[]>([]);
  const [activeChat, setActiveChat] = useState<Chat | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoadingChats, setIsLoadingChats] = useState<boolean>(false);
  const [isLoadingMessages, setIsLoadingMessages] = useState<boolean>(false);
  const [isPeerTyping, setIsPeerTyping] = useState<boolean>(false);
  const [activeFilter, setActiveFilter] = useState<'all' | 'unread' | 'groups'>('all');

  const refreshChats = useCallback(async () => {
    try {
      const data = await api.getMyChats();
      setChats(data);
    } catch (err) {
      console.error('Error fetching chats:', err);
    }
  }, []);

  useEffect(() => {
    if (user) {
      setIsLoadingChats(true);
      refreshChats().finally(() => setIsLoadingChats(false));
    } else {
      setChats([]);
      setActiveChat(null);
      setMessages([]);
    }
  }, [user, refreshChats]);

  const selectChat = useCallback(async (chat: Chat) => {
    setActiveChat(chat);
    setIsPeerTyping(false);
    setIsLoadingMessages(true);
    const socket = getSocket();
    if (socket) {
      socket.emit('chat:join', chat.id);
    }
    try {
      const msgs = await api.getMessages(chat.id);
      const sorted = [...msgs].sort(
        (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
      );
      setMessages(sorted);
      api.markAsRead(chat.id);
      if (socket) {
        socket.emit('message:read', { chatId: chat.id, lastReadMessageId: sorted[sorted.length - 1]?.id });
      }
      setChats((prev) => prev.map((c) => (c.id === chat.id ? { ...c, unreadCount: 0 } : c)));
    } finally {
      setIsLoadingMessages(false);
    }
  }, []);

  useChatSocket({
    user,
    activeChat,
    setMessages,
    setChats,
    setIsPeerTyping,
    refreshChats,
  });

  const sendMessage = async (
    text?: string,
    files?: File[],
    replyToId?: string,
    onProgress?: (pct: number, loaded: number, total: number) => void
  ) => {
    if (!activeChat) return;
    const msg = await api.sendMessage(activeChat.id, text, files, replyToId, onProgress);
    setMessages((prev) => {
      if (prev.some((m) => m.id === msg.id)) {
        return prev.map((m) => (m.id === msg.id ? { ...m, ...msg } : m));
      }
      return [...prev, msg];
    });
    refreshChats();
  };

  const createDirectChat = async (recipientId: string) => {
    const chat = await api.createDirectChat(recipientId);
    selectChat(chat);
    return chat;
  };

  const createGroupChat = async (name: string, memberIds: string[]) => {
    const chat = await api.createGroupChat(name, memberIds);
    await refreshChats();
    selectChat(chat);
    return chat;
  };

  const deleteChat = async (chatId: string) => {
    await api.deleteChat(chatId);
    setChats((prev) => prev.filter((c) => c.id !== chatId));
    if (activeChat?.id === chatId) {
      setActiveChat(null);
      setMessages([]);
    }
  };

  const markAsRead = async (chatId: string) => {
    await api.markAsRead(chatId);
    setChats((prev) => prev.map((c) => (c.id === chatId ? { ...c, unreadCount: 0 } : c)));
  };

  const markAllAsRead = async () => {
    for (const c of chats) {
      if ((c.unreadCount || 0) > 0) {
        await api.markAsRead(c.id);
      }
    }
    setChats((prev) => prev.map((c) => ({ ...c, unreadCount: 0 })));
  };

  const unsendMessage = async (messageId: string) => {
    await api.unsendMessage(messageId);
    setMessages((prev) =>
      prev.map((m) => (m.id === messageId ? { ...m, isUnsent: true, text: 'This message was unsent' } : m))
    );
  };

  const deleteForMe = async (messageId: string) => {
    await api.deleteForMe(messageId);
    setMessages((prev) => prev.filter((m) => m.id !== messageId));
  };

  const reactToMessage = async (messageId: string, emoji: string) => {
    await api.reactToMessage(messageId, emoji);
  };

  const emitTyping = (isTyping: boolean) => {
    const socket = getSocket();
    if (!socket || !activeChat) return;
    socket.emit(isTyping ? 'typing:start' : 'typing:stop', { chatId: activeChat.id });
  };

  return (
    <ChatContext.Provider
      value={{
        chats,
        activeChat,
        messages,
        isLoadingChats,
        isLoadingMessages,
        isPeerTyping,
        activeFilter,
        setActiveFilter,
        selectChat,
        sendMessage,
        createDirectChat,
        createGroupChat,
        deleteChat,
        markAsRead,
        markAllAsRead,
        unsendMessage,
        deleteForMe,
        reactToMessage,
        emitTyping,
        refreshChats,
      }}
    >
      {children}
    </ChatContext.Provider>
  );
};

export const useChat = () => {
  const ctx = useContext(ChatContext);
  if (!ctx) throw new Error('useChat must be used within ChatProvider');
  return ctx;
};
