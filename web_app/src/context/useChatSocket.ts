import { useEffect, useRef } from 'react';
import { Chat, Message, User } from '../types';
import { api } from '../services/api';
import { getSocket } from '../services/socket';

interface UseChatSocketProps {
  user: User | null;
  activeChat: Chat | null;
  setMessages: React.Dispatch<React.SetStateAction<Message[]>>;
  setChats: React.Dispatch<React.SetStateAction<Chat[]>>;
  setIsPeerTyping: (typing: boolean) => void;
  refreshChats: () => Promise<void>;
}

export const useChatSocket = ({
  user,
  activeChat,
  setMessages,
  setChats,
  setIsPeerTyping,
  refreshChats,
}: UseChatSocketProps) => {
  const activeChatRef = useRef<Chat | null>(activeChat);
  const userRef = useRef<User | null>(user);

  useEffect(() => {
    activeChatRef.current = activeChat;
  }, [activeChat]);

  useEffect(() => {
    userRef.current = user;
  }, [user]);

  useEffect(() => {
    const socket = getSocket();
    if (!socket || !user) return;

    const onNewMessage = (msg: Message) => {
      const currentActive = activeChatRef.current;
      const currentUser = userRef.current;

      if (currentActive && msg.chatId === currentActive.id) {
        setMessages((prev) => {
          if (prev.some((m) => m.id === msg.id)) {
            return prev.map((m) => (m.id === msg.id ? { ...m, ...msg } : m));
          }
          return [...prev, msg];
        });

        if (currentUser && msg.senderId !== currentUser.id) {
          api.markAsRead(currentActive.id, msg.id);
          socket.emit('message:read', { chatId: currentActive.id, lastReadMessageId: msg.id });
        }
      }

      setChats((prev) => {
        const idx = prev.findIndex((c) => c.id === msg.chatId);
        if (idx !== -1) {
          const isCurrentChat = currentActive?.id === msg.chatId;
          const isSender = currentUser && msg.senderId === currentUser.id;
          const updatedChat = {
            ...prev[idx],
            lastMessage: msg,
            unreadCount: isCurrentChat || isSender ? 0 : (prev[idx].unreadCount || 0) + 1,
            updatedAt: msg.createdAt,
          };
          return [updatedChat, ...prev.filter((_, i) => i !== idx)];
        }
        refreshChats();
        return prev;
      });
    };

    const onDelivered = (data: { messageId: string; chatId: string }) => {
      setMessages((prev) =>
        prev.map((m) => (m.id === data.messageId ? { ...m, status: 'delivered' } : m))
      );
    };

    const onRead = (data: { chatId: string }) => {
      const currentActive = activeChatRef.current;
      const currentUser = userRef.current;
      if (currentActive?.id === data.chatId && currentUser) {
        setMessages((prev) => prev.map((m) => (m.senderId === currentUser.id ? { ...m, status: 'read' } : m)));
      }
    };

    const onUnsent = (data: { messageId: string }) => {
      setMessages((prev) =>
        prev.map((m) => (m.id === data.messageId ? { ...m, isUnsent: true, text: 'This message was unsent' } : m))
      );
    };

    const onReaction = () => {
      const currentActive = activeChatRef.current;
      if (currentActive) api.getMessages(currentActive.id).then(setMessages);
    };

    const onOnline = ({ userId }: { userId: string }) => {
      setChats((prev) =>
        prev.map((c) => (c.otherUser?.id === userId ? { ...c, otherUser: { ...c.otherUser, isOnline: true } } : c))
      );
    };

    const onOffline = ({ userId }: { userId: string }) => {
      setChats((prev) =>
        prev.map((c) => (c.otherUser?.id === userId ? { ...c, otherUser: { ...c.otherUser, isOnline: false } } : c))
      );
    };

    const onTypingStart = (data: { chatId: string; userId: string }) => {
      const currentActive = activeChatRef.current;
      const currentUser = userRef.current;
      if (currentActive?.id === data.chatId && currentUser && data.userId !== currentUser.id) {
        setIsPeerTyping(true);
      }
    };

    const onTypingStop = (data: { chatId: string; userId: string }) => {
      const currentActive = activeChatRef.current;
      const currentUser = userRef.current;
      if (currentActive?.id === data.chatId && currentUser && data.userId !== currentUser.id) {
        setIsPeerTyping(false);
      }
    };

    const onChatUpdated = () => {
      refreshChats();
    };

    socket.on('message:new', onNewMessage);
    socket.on('message:delivered', onDelivered);
    socket.on('message:read', onRead);
    socket.on('message:unsent', onUnsent);
    socket.on('message:reaction', onReaction);
    socket.on('chat:updated', onChatUpdated);
    socket.on('presence:user_online', onOnline);
    socket.on('presence:user_offline', onOffline);
    socket.on('typing:start', onTypingStart);
    socket.on('typing:stop', onTypingStop);

    return () => {
      socket.off('message:new', onNewMessage);
      socket.off('message:delivered', onDelivered);
      socket.off('message:read', onRead);
      socket.off('message:unsent', onUnsent);
      socket.off('message:reaction', onReaction);
      socket.off('chat:updated', onChatUpdated);
      socket.off('presence:user_online', onOnline);
      socket.off('presence:user_offline', onOffline);
      socket.off('typing:start', onTypingStart);
      socket.off('typing:stop', onTypingStop);
    };
  }, [user, refreshChats, setMessages, setChats, setIsPeerTyping]);
};

