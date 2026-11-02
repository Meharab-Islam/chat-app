import React, { useState } from 'react';
import { useChat } from '../context/ChatContext';
import { resolveMediaUrl } from '../services/api';
import { EditGroupModal } from './EditGroupModal';
import { Search, X, Users, Settings } from 'lucide-react';

interface Props {
  isSearching: boolean;
  searchQuery: string;
  onToggleSearch: (searching: boolean) => void;
  onSearchChange: (q: string) => void;
}

export const ChatHeader: React.FC<Props> = ({
  isSearching,
  searchQuery,
  onToggleSearch,
  onSearchChange,
}) => {
  const { activeChat, isPeerTyping } = useChat();
  const [isEditGroupOpen, setIsEditGroupOpen] = useState(false);

  if (!activeChat) return null;

  const isDirect = activeChat.type === 'direct';
  const peer = isDirect ? activeChat.otherUser : null;
  const title = isDirect ? peer?.name : activeChat.name;
  const avatar = isDirect ? peer?.avatarUrl : activeChat.avatarUrl;
  const isOnline = peer?.isOnline;

  return (
    <>
      <div className="h-16 px-6 border-b border-zinc-800/80 bg-zinc-900/70 backdrop-blur-md flex items-center justify-between flex-shrink-0 z-10 shadow-sm">
        {isSearching ? (
          <div className="flex-1 flex items-center gap-3">
            <Search className="w-4 h-4 text-zinc-400" />
            <input
              type="text"
              autoFocus
              placeholder="Search messages in this conversation..."
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              className="flex-1 bg-transparent text-sm text-white placeholder-zinc-500 focus:outline-none"
            />
            <button
              onClick={() => {
                onToggleSearch(false);
                onSearchChange('');
              }}
              className="p-1 rounded-lg text-zinc-400 hover:text-white hover:bg-zinc-800"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        ) : (
          <>
            <div
              className={`flex items-center gap-3 ${!isDirect ? 'cursor-pointer group' : ''}`}
              onClick={() => !isDirect && setIsEditGroupOpen(true)}
              title={!isDirect ? 'Click to view members or edit group' : undefined}
            >
              <div className="relative">
                <img
                  src={resolveMediaUrl(avatar) || `https://api.dicebear.com/7.x/avataaars/svg?seed=${title || 'chat'}`}
                  alt={title || 'chat'}
                  className="w-10 h-10 rounded-full object-cover bg-zinc-800 border border-zinc-700/80 shadow-sm group-hover:border-indigo-500 transition"
                />
                {isOnline && (
                  <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border-2 border-zinc-950 rounded-full shadow-[0_0_8px_rgba(16,185,129,0.7)]" />
                )}
              </div>
              <div>
                <div className="text-sm font-semibold text-white flex items-center gap-2 group-hover:text-indigo-300 transition">
                  {title}
                  {!isDirect && (
                    <span className="text-[10px] bg-zinc-800/90 text-zinc-400 px-1.5 py-0.5 rounded font-normal flex items-center gap-1 border border-zinc-700/50">
                      <Users className="w-3 h-3" /> Group
                    </span>
                  )}
                </div>
                <div className="text-xs">
                  {isPeerTyping ? (
                    <span className="text-emerald-400 font-medium flex items-center gap-1.5 animate-pulse">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block" /> typing...
                    </span>
                  ) : isDirect ? (
                    <span className={isOnline ? 'text-emerald-400 font-medium' : 'text-zinc-500'}>
                      {isOnline ? 'Online' : 'Offline'}
                    </span>
                  ) : (
                    <span className="text-zinc-400 group-hover:text-indigo-400 transition flex items-center gap-1">
                      {activeChat.members?.length || 2} members • Click to edit
                    </span>
                  )}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              {!isDirect && (
                <button
                  onClick={() => setIsEditGroupOpen(true)}
                  title="Group settings"
                  className="p-2 rounded-xl text-zinc-400 hover:text-white hover:bg-zinc-800 transition"
                >
                  <Settings className="w-5 h-5" />
                </button>
              )}
              <button
                onClick={() => onToggleSearch(true)}
                title="Search in chat"
                className="p-2 rounded-xl text-zinc-400 hover:text-white hover:bg-zinc-800 transition"
              >
                <Search className="w-5 h-5" />
              </button>
            </div>
          </>
        )}
      </div>

      {!isDirect && (
        <EditGroupModal
          isOpen={isEditGroupOpen}
          onClose={() => setIsEditGroupOpen(false)}
        />
      )}
    </>
  );
};

