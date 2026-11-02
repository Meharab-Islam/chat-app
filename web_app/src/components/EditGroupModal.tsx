import React, { useState, useRef, useEffect } from 'react';
import { useChat } from '../context/ChatContext';
import { resolveMediaUrl } from '../services/api';
import { X, Camera, Users, Loader2, Check } from 'lucide-react';

interface Props {
  isOpen: boolean;
  onClose: () => void;
}

export const EditGroupModal: React.FC<Props> = ({ isOpen, onClose }) => {
  const { activeChat, updateGroup } = useChat();
  const [name, setName] = useState('');
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (activeChat) {
      setName(activeChat.name || '');
      setAvatarFile(null);
      setPreviewUrl(null);
    }
  }, [activeChat, isOpen]);

  if (!isOpen || !activeChat || activeChat.type !== 'group') return null;

  const currentAvatar = previewUrl || resolveMediaUrl(activeChat.avatarUrl) ||
    `https://api.dicebear.com/7.x/avataaars/svg?seed=${activeChat.name || 'group'}`;

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setAvatarFile(file);
      setPreviewUrl(URL.createObjectURL(file));
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    setIsSubmitting(true);
    try {
      await updateGroup(activeChat.id, name.trim(), avatarFile || undefined);
      onClose();
    } catch (err) {
      console.error('Failed to update group:', err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const members = activeChat.members || [];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-md bg-zinc-900 border border-zinc-800 rounded-2xl p-6 shadow-2xl flex flex-col max-h-[85vh]">
        <div className="flex items-center justify-between pb-4 border-b border-zinc-800">
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-white">Group Info & Settings</h2>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg text-zinc-400 hover:text-white hover:bg-zinc-800">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSave} className="flex-1 overflow-y-auto mt-4 space-y-4 pr-1">
          {/* Avatar Upload */}
          <div className="flex flex-col items-center gap-2">
            <div className="relative group cursor-pointer" onClick={() => fileInputRef.current?.click()}>
              <img
                src={currentAvatar}
                alt="Group Avatar"
                className="w-20 h-20 rounded-full object-cover border-2 border-indigo-500/50 shadow-lg group-hover:opacity-80 transition"
              />
              <div className="absolute inset-0 flex items-center justify-center bg-black/40 rounded-full opacity-0 group-hover:opacity-100 transition">
                <Camera className="w-6 h-6 text-white" />
              </div>
            </div>
            <input
              type="file"
              ref={fileInputRef}
              onChange={handleFileChange}
              accept="image/*"
              className="hidden"
            />
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="text-xs text-indigo-400 hover:text-indigo-300 font-medium"
            >
              Change Group Photo
            </button>
          </div>

          {/* Group Name Input */}
          <div>
            <label className="text-xs font-medium text-zinc-400 block mb-1.5">Group Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Enter group name..."
              required
              className="w-full bg-zinc-800/80 border border-zinc-700/80 rounded-xl px-3.5 py-2 text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500"
            />
          </div>

          {/* Members List Section */}
          <div className="pt-2 border-t border-zinc-800">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-zinc-300 uppercase tracking-wider">
                Members ({members.length})
              </span>
            </div>
            <div className="space-y-1.5 max-h-40 overflow-y-auto">
              {members.map((m: any) => {
                const u = m.user || {};
                const mAvatar = resolveMediaUrl(u.avatarUrl) ||
                  `https://api.dicebear.com/7.x/avataaars/svg?seed=${u.name || 'user'}`;
                return (
                  <div key={m.id || u.id} className="flex items-center justify-between p-2 rounded-xl bg-zinc-800/40 border border-zinc-800">
                    <div className="flex items-center gap-2.5">
                      <div className="relative">
                        <img src={mAvatar} alt={u.name} className="w-7 h-7 rounded-full object-cover" />
                        {u.isOnline && (
                          <span className="absolute bottom-0 right-0 w-2 h-2 bg-emerald-500 rounded-full border border-zinc-900" />
                        )}
                      </div>
                      <span className="text-sm font-medium text-white">{u.name || 'Member'}</span>
                    </div>
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-zinc-700/60 text-zinc-300 font-medium capitalize">
                      {m.role || 'member'}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="pt-3 border-t border-zinc-800 flex justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-xl text-sm font-medium text-zinc-300 hover:bg-zinc-800 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting || !name.trim()}
              className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-semibold bg-indigo-600 hover:bg-indigo-500 text-white disabled:opacity-50 transition shadow-lg shadow-indigo-600/30"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" /> Saving...
                </>
              ) : (
                <>
                  <Check className="w-4 h-4" /> Save Changes
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

