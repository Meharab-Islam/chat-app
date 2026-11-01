import React, { useState, useEffect } from 'react';
import { User } from '../types';
import { api, resolveMediaUrl } from '../services/api';
import { useChat } from '../context/ChatContext';
import { X, Users, Check, Loader2 } from 'lucide-react';

interface Props {
  isOpen: boolean;
  onClose: () => void;
}

export const CreateGroupModal: React.FC<Props> = ({ isOpen, onClose }) => {
  const { createGroupChat } = useChat();
  const [name, setName] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (!isOpen) return;
    const fetchUsers = async () => {
      setIsLoading(true);
      try {
        const list = await api.searchUsers('a');
        setUsers(list);
      } catch (err) {
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    };
    fetchUsers();
  }, [isOpen]);

  if (!isOpen) return null;

  const toggleUser = (userId: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(userId)) next.delete(userId);
      else next.add(userId);
      return next;
    });
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || selectedIds.size === 0) return;
    setIsSubmitting(true);
    try {
      await createGroupChat(name.trim(), Array.from(selectedIds));
      onClose();
    } catch (err) {
      console.error(err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-md bg-zinc-900 border border-zinc-800 rounded-2xl p-6 shadow-2xl flex flex-col max-h-[85vh]">
        <div className="flex items-center justify-between pb-4 border-b border-zinc-800">
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-white">Create Group Chat</h2>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg text-zinc-400 hover:text-white hover:bg-zinc-800">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleCreate} className="mt-4 flex flex-col flex-1 overflow-hidden">
          <div>
            <label className="block text-xs font-medium text-zinc-400 mb-1">Group Name *</label>
            <input
              type="text"
              required
              placeholder="e.g. Design Team, Family, Hangout"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-zinc-800/80 border border-zinc-700/60 rounded-xl text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div className="mt-4 flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-zinc-400">
              Select Members ({selectedIds.size} selected)
            </span>
          </div>

          <div className="mt-2 flex-1 overflow-y-auto space-y-1 pr-1 min-h-[180px]">
            {isLoading ? (
              <div className="flex items-center justify-center py-10 text-zinc-500">
                <Loader2 className="w-6 h-6 animate-spin" />
              </div>
            ) : users.length === 0 ? (
              <div className="text-center py-10 text-sm text-zinc-500">No users found</div>
            ) : (
              users.map((u) => {
                const isSelected = selectedIds.has(u.id);
                return (
                  <div
                    key={u.id}
                    onClick={() => toggleUser(u.id)}
                    className={`flex items-center justify-between p-2.5 rounded-xl cursor-pointer transition border ${
                      isSelected
                        ? 'bg-indigo-600/10 border-indigo-500/50'
                        : 'hover:bg-zinc-800/60 border-transparent'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <img
                        src={resolveMediaUrl(u.avatarUrl) || `https://api.dicebear.com/7.x/avataaars/svg?seed=${u.name}`}
                        alt={u.name}
                        className="w-9 h-9 rounded-full object-cover bg-zinc-700"
                      />
                      <div>
                        <div className="text-sm font-medium text-white">{u.name}</div>
                        <div className="text-xs text-zinc-400">{u.email}</div>
                      </div>
                    </div>
                    <div
                      className={`w-5 h-5 rounded-md flex items-center justify-center border transition ${
                        isSelected
                          ? 'bg-indigo-600 border-indigo-600 text-white'
                          : 'border-zinc-700 bg-zinc-800'
                      }`}
                    >
                      {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                    </div>
                  </div>
                );
              })
            )}
          </div>

          <div className="mt-5 pt-4 border-t border-zinc-800 flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm text-zinc-400 hover:text-white rounded-xl hover:bg-zinc-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting || !name.trim() || selectedIds.size === 0}
              className="px-5 py-2 text-sm bg-indigo-600 hover:bg-indigo-500 text-white font-medium rounded-xl transition disabled:opacity-50 flex items-center gap-2"
            >
              {isSubmitting ? 'Creating...' : 'Create Group'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

