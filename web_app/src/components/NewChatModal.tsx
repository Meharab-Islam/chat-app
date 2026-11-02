import React, { useState, useEffect } from 'react';
import { User } from '../types';
import { api, resolveMediaUrl } from '../services/api';
import { useChat } from '../context/ChatContext';
import { X, Search, MessageSquare, Loader2 } from 'lucide-react';

interface Props {
  isOpen: boolean;
  onClose: () => void;
}

export const NewChatModal: React.FC<Props> = ({ isOpen, onClose }) => {
  const { createDirectChat } = useChat();
  const [query, setQuery] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isCreating, setIsCreating] = useState(false);

  useEffect(() => {
    if (!isOpen) return;
    const fetchUsers = async () => {
      setIsLoading(true);
      try {
        const list = await api.searchUsers(query.trim());
        setUsers(list);
      } catch (err) {
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    };
    const t = setTimeout(fetchUsers, 250);
    return () => clearTimeout(t);
  }, [query, isOpen]);

  if (!isOpen) return null;

  const handleSelectUser = async (u: User) => {
    setIsCreating(true);
    try {
      await createDirectChat(u.id);
      onClose();
    } catch (err) {
      console.error(err);
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-md bg-zinc-900 border border-zinc-800 rounded-2xl p-6 shadow-2xl flex flex-col max-h-[85vh]">
        <div className="flex items-center justify-between pb-4 border-b border-zinc-800">
          <h2 className="text-lg font-semibold text-white">Start New Chat</h2>
          <button onClick={onClose} className="p-1 rounded-lg text-zinc-400 hover:text-white hover:bg-zinc-800">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="mt-4 relative">
          <Search className="w-4 h-4 absolute left-3.5 top-3 text-zinc-400" />
          <input
            type="text"
            autoFocus
            placeholder="Search people by name or email..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-zinc-800/80 border border-zinc-700/60 rounded-xl text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500"
          />
        </div>

        <div className="mt-4 flex-1 overflow-y-auto space-y-2 pr-1 min-h-[200px]">
          {isLoading ? (
            <div className="flex items-center justify-center py-10 text-zinc-500">
              <Loader2 className="w-6 h-6 animate-spin" />
            </div>
          ) : users.length === 0 ? (
            <div className="text-center py-10 text-sm text-zinc-500">No users found</div>
          ) : (
            users.map((u) => (
              <button
                key={u.id}
                disabled={isCreating}
                onClick={() => handleSelectUser(u)}
                className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-zinc-800/60 transition group text-left border border-transparent hover:border-zinc-700/50"
              >
                <div className="flex items-center gap-3">
                  <div className="relative">
                    <img
                      src={resolveMediaUrl(u.avatarUrl) || `https://api.dicebear.com/7.x/avataaars/svg?seed=${u.name}`}
                      alt={u.name}
                      className="w-10 h-10 rounded-full object-cover bg-zinc-700"
                    />
                    {u.isOnline && (
                      <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border-2 border-zinc-900 rounded-full" />
                    )}
                  </div>
                  <div>
                    <div className="text-sm font-semibold text-zinc-200 group-hover:text-white">{u.name}</div>
                    <div className="text-xs text-zinc-400">{u.status || u.email}</div>
                  </div>
                </div>
                <div className="p-2 rounded-lg bg-indigo-500/10 text-indigo-400 group-hover:bg-indigo-600 group-hover:text-white transition">
                  <MessageSquare className="w-4 h-4" />
                </div>
              </button>
            ))
          )}
        </div>
      </div>
    </div>
  );
};

