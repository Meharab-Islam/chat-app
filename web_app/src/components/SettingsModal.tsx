import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { resolveMediaUrl } from '../services/api';
import { X, Camera, Check, User, Info, Loader2 } from 'lucide-react';

interface Props {
  isOpen: boolean;
  onClose: () => void;
}

const PRESET_AVATARS = [
  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
  'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
];

export const SettingsModal: React.FC<Props> = ({ isOpen, onClose }) => {
  const { user, updateProfile, updateAvatar } = useAuth();
  const [name, setName] = useState(user?.name || '');
  const [status, setStatus] = useState(user?.status || '');
  const [bio, setBio] = useState(user?.bio || '');
  const [isSaving, setIsSaving] = useState(false);
  const [isUploading, setIsUploading] = useState(false);

  if (!isOpen || !user) return null;

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      await updateProfile({ name: name.trim(), status: status.trim(), bio: bio.trim() });
      onClose();
    } catch (err) {
      console.error(err);
    } finally {
      setIsSaving(false);
    }
  };

  const handleAvatarFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsUploading(true);
    try {
      await updateAvatar(file);
    } catch (err) {
      console.error(err);
    } finally {
      setIsUploading(false);
    }
  };

  const handlePresetSelect = async (url: string) => {
    setIsUploading(true);
    try {
      await updateProfile({ avatarUrl: url });
    } catch (err) {
      console.error(err);
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-md bg-zinc-900 border border-zinc-800 rounded-2xl p-6 shadow-2xl flex flex-col max-h-[90vh]">
        <div className="flex items-center justify-between pb-4 border-b border-zinc-800">
          <h2 className="text-lg font-semibold text-white">Profile & Settings</h2>
          <button onClick={onClose} className="p-1 rounded-lg text-zinc-400 hover:text-white hover:bg-zinc-800">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSave} className="mt-5 space-y-4 overflow-y-auto pr-1">
          {/* Avatar Upload */}
          <div className="flex flex-col items-center gap-3">
            <div className="relative group cursor-pointer">
              <img
                src={resolveMediaUrl(user.avatarUrl) || `https://api.dicebear.com/7.x/avataaars/svg?seed=${user.name}`}
                alt={user.name}
                className="w-20 h-20 rounded-full object-cover border-2 border-indigo-500/50"
              />
              <label className="absolute inset-0 bg-black/50 rounded-full opacity-0 group-hover:opacity-100 flex items-center justify-center transition cursor-pointer">
                <Camera className="w-6 h-6 text-white" />
                <input type="file" accept="image/*" onChange={handleAvatarFile} className="hidden" />
              </label>
              {isUploading && (
                <div className="absolute inset-0 bg-black/70 rounded-full flex items-center justify-center">
                  <Loader2 className="w-6 h-6 text-indigo-400 animate-spin" />
                </div>
              )}
            </div>
            <div className="text-xs text-zinc-400">Click photo to upload new avatar</div>

            {/* Presets */}
            <div className="flex items-center gap-2 pt-1">
              {PRESET_AVATARS.map((url, i) => (
                <button
                  key={i}
                  type="button"
                  onClick={() => handlePresetSelect(url)}
                  className="w-8 h-8 rounded-full overflow-hidden border border-zinc-700 hover:border-indigo-500 transition"
                >
                  <img src={url} alt="preset" className="w-full h-full object-cover" />
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-zinc-400 flex items-center gap-1.5 mb-1">
              <User className="w-3.5 h-3.5 text-indigo-400" /> Display Name
            </label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3.5 py-2 bg-zinc-800/80 border border-zinc-700/60 rounded-xl text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div>
            <label className="text-xs font-medium text-zinc-400 flex items-center gap-1.5 mb-1">
              <Info className="w-3.5 h-3.5 text-indigo-400" /> Status / About
            </label>
            <input
              type="text"
              placeholder="e.g. Available, At work, In a meeting"
              value={status}
              onChange={(e) => setStatus(e.target.value)}
              className="w-full px-3.5 py-2 bg-zinc-800/80 border border-zinc-700/60 rounded-xl text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div>
            <label className="text-xs font-medium text-zinc-400 block mb-1">Bio (Extended)</label>
            <textarea
              rows={2}
              placeholder="Tell others a little about yourself..."
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              className="w-full px-3.5 py-2 bg-zinc-800/80 border border-zinc-700/60 rounded-xl text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500 resize-none"
            />
          </div>

          <div className="pt-2 text-xs text-zinc-500">
            Account Email: <span className="text-zinc-300 font-mono">{user.email}</span>
          </div>

          <div className="pt-4 border-t border-zinc-800 flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm text-zinc-400 hover:text-white rounded-xl hover:bg-zinc-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSaving || !name.trim()}
              className="px-5 py-2 text-sm bg-indigo-600 hover:bg-indigo-500 text-white font-medium rounded-xl transition flex items-center gap-2 disabled:opacity-50"
            >
              <Check className="w-4 h-4" />
              {isSaving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

