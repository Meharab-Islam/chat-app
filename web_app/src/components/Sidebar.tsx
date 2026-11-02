import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useChat } from '../context/ChatContext';
import { resolveMediaUrl } from '../services/api';
import { Chat } from '../types';
import {
  MessageSquarePlus,
  Users,
  Settings,
  LogOut,
  Search,
  CheckCheck,
  Check,
  Trash2,
  Image as ImageIcon,
  Mic,
  FileText,
} from 'lucide-react';

interface Props {
  onOpenNewChat: () => void;
  onOpenCreateGroup: () => void;
  onOpenSettings: () => void;
}

export const Sidebar: React.FC<Props> = ({ onOpenNewChat, onOpenCreateGroup, onOpenSettings }) => {
  const { user, logout } = useAuth();
  const {
    chats,
    activeChat,
    selectChat,
    deleteChat,
    activeFilter,
    setActiveFilter,
    markAllAsRead,
  } = useChat();
  const [searchQuery, setSearchQuery] = useState('');

  const totalUnread = chats.reduce((acc, c) => acc + (c.unreadCount || 0), 0);

  const filteredChats = chats.filter((c) => {
    if (activeFilter === 'unread' && (!c.unreadCount || c.unreadCount <= 0)) return false;
    if (activeFilter === 'groups' && c.type !== 'group') return false;

    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    const name = (c.type === 'direct' ? c.otherUser?.name : c.name) || '';
    const lastMsg = c.lastMessage?.text || '';
    return name.toLowerCase().includes(q) || lastMsg.toLowerCase().includes(q);
  });

  const renderLastMessageSnippet = (chat: Chat) => {
    const msg = chat.lastMessage;
    if (!msg) return <span className="text-zinc-500 italic">No messages yet</span>;
    if (msg.isUnsent) {
      return (
        <span className="text-zinc-500 italic">
          {msg.senderId === user?.id ? 'Unsent by you' : 'This message was unsent'}
        </span>
      );
    }

    const hasAtt = (msg as any).hasAttachments || (msg.attachments && msg.attachments.length > 0) || msg.type === 'media' || msg.type === 'audio' || msg.type === 'file';
    let icon = null;
    if (msg.type === 'media' || msg.attachments?.[0]?.fileType === 'image') icon = <ImageIcon className="w-3.5 h-3.5 inline mr-1 text-zinc-400 shrink-0" />;
    else if (msg.type === 'audio' || msg.attachments?.[0]?.fileType === 'audio') icon = <Mic className="w-3.5 h-3.5 inline mr-1 text-zinc-400 shrink-0" />;
    else if (hasAtt) icon = <FileText className="w-3.5 h-3.5 inline mr-1 text-zinc-400 shrink-0" />;

    const text = msg.text || (hasAtt ? 'Attachment' : '');

    return (
      <span className="flex items-center truncate text-zinc-400">
        {icon}
        <span className="truncate">{text || 'Attachment'}</span>
      </span>
    );
  };

  return (
    <div className="w-80 sm:w-96 h-full flex flex-col bg-zinc-950 border-r border-zinc-800/80 select-none">
      {/* Top Profile Header */}
      <div className="p-4 flex items-center justify-between border-b border-zinc-800/80 bg-zinc-900/40">
        <div className="flex items-center gap-3">
          <div className="relative cursor-pointer" onClick={onOpenSettings}>
            <img
              src={resolveMediaUrl(user?.avatarUrl) || `https://api.dicebear.com/7.x/avataaars/svg?seed=${user?.name}`}
              alt={user?.name}
              className="w-10 h-10 rounded-full object-cover border border-zinc-700"
            />
            <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border-2 border-zinc-950 rounded-full" />
          </div>
          <div>
            <div className="text-sm font-semibold text-white truncate max-w-[120px]">{user?.name}</div>
            <div className="text-xs text-zinc-400 truncate max-w-[120px]">{user?.status || 'Online'}</div>
          </div>
        </div>

        <div className="flex items-center gap-1">
          <button onClick={onOpenNewChat} title="New Chat" className="p-2 rounded-xl text-zinc-400 hover:text-white hover:bg-zinc-800 transition">
            <MessageSquarePlus className="w-5 h-5" />
          </button>
          <button onClick={onOpenCreateGroup} title="New Group" className="p-2 rounded-xl text-zinc-400 hover:text-white hover:bg-zinc-800 transition">
            <Users className="w-5 h-5" />
          </button>
          <button onClick={onOpenSettings} title="Settings" className="p-2 rounded-xl text-zinc-400 hover:text-white hover:bg-zinc-800 transition">
            <Settings className="w-5 h-5" />
          </button>
          <button onClick={logout} title="Sign Out" className="p-2 rounded-xl text-red-400 hover:text-red-300 hover:bg-red-500/10 transition">
            <LogOut className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Search & Filter */}
      <div className="p-3 space-y-3">
        <div className="relative">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-zinc-500" />
          <input
            type="text"
            placeholder="Search conversations..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500"
          />
        </div>

        {/* Filter Pills */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-1.5">
            {(['all', 'unread', 'groups'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setActiveFilter(f)}
                className={`px-3 py-1 rounded-full font-medium transition ${
                  activeFilter === f
                    ? 'bg-indigo-600 text-white'
                    : 'bg-zinc-900 text-zinc-400 hover:text-zinc-200'
                }`}
              >
                {f === 'all' ? 'All' : f === 'unread' ? `Unread ${totalUnread > 0 ? `(${totalUnread})` : ''}` : 'Groups'}
              </button>
            ))}
          </div>

          {totalUnread > 0 && (
            <button
              onClick={markAllAsRead}
              title="Mark all as read"
              className="text-xs text-indigo-400 hover:text-indigo-300 flex items-center gap-1"
            >
              <CheckCheck className="w-3.5 h-3.5" /> Read All
            </button>
          )}
        </div>
      </div>

      {/* Conversations List */}
      <div className="flex-1 overflow-y-auto divide-y divide-zinc-900/60">
        {filteredChats.length === 0 ? (
          <div className="p-8 text-center text-sm text-zinc-500">No chats found</div>
        ) : (
          filteredChats.map((c) => {
            const isActive = activeChat?.id === c.id;
            const peer = c.type === 'direct' ? c.otherUser : null;
            const title = c.type === 'direct' ? peer?.name : c.name;
            const avatar = c.type === 'direct' ? peer?.avatarUrl : c.avatarUrl;
            const isOnline = peer?.isOnline;

            return (
              <div
                key={c.id}
                onClick={() => selectChat(c)}
                className={`group flex items-center justify-between p-3.5 cursor-pointer transition ${
                  isActive ? 'bg-zinc-800/80 border-l-4 border-indigo-500' : 'hover:bg-zinc-900/60'
                }`}
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className="relative flex-shrink-0">
                    <img
                      src={resolveMediaUrl(avatar) || `https://api.dicebear.com/7.x/avataaars/svg?seed=${title || 'chat'}`}
                      alt={title || 'chat'}
                      className="w-12 h-12 rounded-full object-cover bg-zinc-800"
                    />
                    {isOnline && (
                      <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-zinc-950 rounded-full" />
                    )}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center justify-between gap-1 mb-1">
                      <span className="text-sm font-semibold text-white truncate">{title}</span>
                    </div>
                    <div className="text-xs truncate">{renderLastMessageSnippet(c)}</div>
                  </div>
                </div>

                <div className="flex flex-col items-end gap-1.5 ml-2 flex-shrink-0">
                  <span className="text-[10px] text-zinc-500">
                    {c.updatedAt ? new Date(c.updatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : ''}
                  </span>
                  <div className="flex items-center gap-1.5">
                    {c.lastMessage && c.lastMessage.senderId === user?.id && (
                      <span>
                        {c.lastMessage.status === 'read' ? (
                          <CheckCheck className="w-3.5 h-3.5 text-cyan-400" />
                        ) : c.lastMessage.status === 'delivered' ? (
                          <CheckCheck className="w-3.5 h-3.5 text-zinc-400" />
                        ) : (
                          <Check className="w-3.5 h-3.5 text-zinc-500" />
                        )}
                      </span>
                    )}
                    {(c.unreadCount || 0) > 0 && (
                      <span className="min-w-[18px] h-[18px] px-1 rounded-full bg-indigo-600 text-white text-[10px] font-bold flex items-center justify-center">
                        {c.unreadCount}
                      </span>
                    )}
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        if (confirm(`Delete chat with ${title}?`)) deleteChat(c.id);
                      }}
                      className="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-zinc-700/80 text-zinc-400 hover:text-red-400 transition"
                      title="Delete chat"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};

