import React, { useState, useRef, useEffect } from 'react';
import { Message } from '../types';
import { useAuth } from '../context/AuthContext';
import { useChat } from '../context/ChatContext';
import { resolveMediaUrl } from '../services/api';
import { VoiceWavePlayer } from './VoiceWavePlayer';
import { Check, CheckCheck, Reply, Ban, Trash2, Smile, FileText, Download, Smartphone, FileArchive, MoreVertical } from 'lucide-react';

interface Props {
  message: Message;
  onReply: (msg: Message) => void;
}

export const MessageItem: React.FC<Props> = ({ message, onReply }) => {
  const { user } = useAuth();
  const { unsendMessage, deleteForMe, reactToMessage } = useChat();
  const [showMenu, setShowMenu] = useState(false);
  const [showReactions, setShowReactions] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  const isMe = message.senderId === user?.id;
  const reactions = message.reactions || [];

  useEffect(() => {
    if (!showMenu && !showReactions) return;
    const handleOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setShowMenu(false);
        setShowReactions(false);
      }
    };
    document.addEventListener('mousedown', handleOutside);
    return () => document.removeEventListener('mousedown', handleOutside);
  }, [showMenu, showReactions]);

  const renderAttachment = (att: any) => {
    const url = resolveMediaUrl(att.fileUrl);
    const type = att.fileType;
    const name = att.fileName || 'File';
    const sizeStr = `${(att.fileSize / (1024 * 1024)).toFixed(1)} MB`;

    if (type === 'image') {
      return (
        <a key={att.id || url} href={url} target="_blank" rel="noreferrer" className="block rounded-xl overflow-hidden mt-1 max-w-sm">
          <img src={url} alt={name} className="w-full max-h-60 object-cover hover:scale-105 transition duration-300" />
        </a>
      );
    }

    if (type === 'video') {
      return (
        <div key={att.id || url} className="mt-1 max-w-sm rounded-xl overflow-hidden">
          <video src={url} controls className="w-full max-h-60 rounded-xl bg-black" />
        </div>
      );
    }

    if (type === 'audio') {
      return <VoiceWavePlayer key={att.id || url} audioUrl={url} isMe={isMe} />;
    }

    const isApk = type === 'apk' || name.toLowerCase().endsWith('.apk');
    const isZip = type === 'zip' || name.toLowerCase().endsWith('.zip');

    return (
      <a
        key={att.id || url}
        href={url}
        download={name}
        target="_blank"
        rel="noreferrer"
        className="mt-1 flex items-center justify-between p-2.5 rounded-xl bg-black/25 hover:bg-black/40 transition border border-white/10 w-68 group"
      >
        <div className="flex items-center gap-2.5 min-w-0">
          <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-white shrink-0 ${isApk ? 'bg-emerald-600' : isZip ? 'bg-amber-600' : 'bg-red-600'}`}>
            {isApk ? <Smartphone className="w-4 h-4" /> : isZip ? <FileArchive className="w-4 h-4" /> : <FileText className="w-4 h-4" />}
          </div>
          <div className="min-w-0">
            <div className="text-xs font-semibold text-white truncate">{name}</div>
            <div className="text-[10px] text-zinc-300 flex items-center gap-1">
              <span className="uppercase font-bold tracking-wider">{type}</span> • <span>{sizeStr}</span>
            </div>
          </div>
        </div>
        <Download className="w-4 h-4 text-white/70 group-hover:text-white shrink-0 ml-2" />
      </a>
    );
  };

  return (
    <div className={`flex flex-col mb-1.5 group select-text ${isMe ? 'items-end' : 'items-start'}`}>
      <div className={`relative max-w-md sm:max-w-lg rounded-2xl px-3.5 py-2 shadow-sm transition ${
        message.isUnsent
          ? isMe
            ? 'bg-zinc-900/90 text-zinc-400 border border-zinc-800 rounded-br-xs'
            : 'bg-zinc-900/90 text-zinc-400 border border-zinc-800 rounded-bl-xs'
          : isMe
            ? 'bg-gradient-to-br from-indigo-600 to-indigo-700 text-white rounded-br-xs shadow-indigo-950/20'
            : 'bg-zinc-800/95 text-zinc-100 rounded-bl-xs border border-zinc-700/60 shadow-black/20'
      }`}>
        {/* Sender Name in Group */}
        {!isMe && message.sender && !message.isUnsent && (
          <div className="text-[11px] font-semibold text-indigo-400 mb-0.5">
            {message.sender.name}
          </div>
        )}

        {/* Reply Quote Banner */}
        {message.replyTo && !message.isUnsent && (
          <div className="mb-1.5 p-2 rounded-lg bg-black/20 border-l-2 border-indigo-300 text-xs text-zinc-200">
            <span className="font-semibold">{message.replyTo.sender?.name}:</span> {message.replyTo.text}
          </div>
        )}

        {/* Attachments */}
        {!message.isUnsent && message.attachments && message.attachments.length > 0 && (
          <div className="space-y-1">{message.attachments.map(renderAttachment)}</div>
        )}

        {/* Message Content or Unsent Notice */}
        {message.isUnsent ? (
          <div className="text-xs italic flex items-center gap-1.5 py-0.5 opacity-80">
            <Ban className="w-3.5 h-3.5 text-zinc-400 inline shrink-0" />
            <span>{isMe ? 'Unsent by you' : 'This message was unsent'}</span>
          </div>
        ) : (
          message.text && (
            <div className="text-sm break-words whitespace-pre-wrap leading-relaxed">
              {message.text}
            </div>
          )
        )}

        {/* Footer: Time & Status & 3-Dot Trigger */}
        <div className={`flex items-center justify-end gap-1.5 mt-0.5 text-[10px] select-none ${isMe ? 'text-indigo-200' : 'text-zinc-400'}`}>
          <span>{new Date(message.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
          {isMe && !message.isUnsent && (
            <span className="flex items-center">
              {message.status === 'read' ? (
                <CheckCheck className="w-3.5 h-3.5 text-cyan-300" />
              ) : message.status === 'delivered' ? (
                <CheckCheck className="w-3.5 h-3.5 text-white/80" />
              ) : (
                <Check className="w-3.5 h-3.5 text-white/70" />
              )}
            </span>
          )}

          {/* 3-Dot Menu Button */}
          <button
            onClick={(e) => {
              e.stopPropagation();
              setShowMenu((prev) => !prev);
              setShowReactions(false);
            }}
            title="Message options"
            className="p-0.5 rounded-full hover:bg-black/20 text-current opacity-70 hover:opacity-100 transition ml-0.5"
          >
            <MoreVertical className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* 3-Dot Dropdown Menu */}
        {showMenu && (
          <div
            ref={menuRef}
            className={`absolute top-full mt-1.5 ${isMe ? 'right-0' : 'left-0'} min-w-[145px] bg-zinc-900/95 backdrop-blur-md border border-zinc-700/80 rounded-xl p-1 shadow-2xl z-30 flex flex-col text-xs text-zinc-200 select-none animate-in fade-in duration-100`}
          >
            {!message.isUnsent && (
              <>
                <button
                  onClick={() => { setShowReactions(true); setShowMenu(false); }}
                  className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg hover:bg-zinc-800 text-left transition"
                >
                  <Smile className="w-3.5 h-3.5 text-amber-400" />
                  <span>React</span>
                </button>
                <button
                  onClick={() => { onReply(message); setShowMenu(false); }}
                  className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg hover:bg-zinc-800 text-left transition"
                >
                  <Reply className="w-3.5 h-3.5 text-indigo-400" />
                  <span>Reply</span>
                </button>
                {isMe && (
                  <button
                    onClick={() => { unsendMessage(message.id); setShowMenu(false); }}
                    className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg hover:bg-red-500/15 text-red-400 text-left transition"
                  >
                    <Ban className="w-3.5 h-3.5" />
                    <span>Unsend</span>
                  </button>
                )}
              </>
            )}
            <button
              onClick={() => { deleteForMe(message.id); setShowMenu(false); }}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg hover:bg-red-500/15 text-red-400 text-left transition"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Delete for me</span>
            </button>
          </div>
        )}

        {/* Reaction Picker Popup */}
        {showReactions && (
          <div
            ref={menuRef}
            className="absolute -top-11 left-0 bg-zinc-900/95 backdrop-blur-md border border-zinc-700/90 rounded-2xl p-1 flex gap-1 shadow-2xl z-30"
          >
            {['👍', '❤️', '😂', '😮', '😢', '🔥'].map((emoji) => (
              <button
                key={emoji}
                onClick={() => {
                  reactToMessage(message.id, emoji);
                  setShowReactions(false);
                }}
                className="hover:scale-125 transition text-base p-1"
              >
                {emoji}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Reactions Bar */}
      {reactions.length > 0 && (
        <div className="flex gap-1 mt-1 px-1">
          {reactions.map((r) => (
            <span key={r.id} className="text-xs px-2 py-0.5 rounded-full bg-zinc-800 border border-zinc-700 text-zinc-300 shadow-sm">
              {r.emoji}
            </span>
          ))}
        </div>
      )}
    </div>
  );
};
