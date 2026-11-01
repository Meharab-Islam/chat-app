import React, { useState, useRef, useEffect } from 'react';
import { Message } from '../types';
import { useChat } from '../context/ChatContext';
import { Send, Paperclip, Mic, X, Image as ImageIcon, FileText, StopCircle, Trash2 } from 'lucide-react';

interface Props {
  replyingTo: Message | null;
  onCancelReply: () => void;
}

export const MessageInput: React.FC<Props> = ({ replyingTo, onCancelReply }) => {
  const { sendMessage, emitTyping } = useChat();
  const [text, setText] = useState('');
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [isRecording, setIsRecording] = useState(false);
  const [recordSeconds, setRecordSeconds] = useState(0);
  const [isSending, setIsSending] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<{
    pct: number;
    loaded: number;
    total: number;
    fileName: string;
  } | null>(null);

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const recordTimerRef = useRef<any>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    emitTyping(text.trim().length > 0);
  }, [text, emitTyping]);

  const handleSend = async () => {
    if (isSending || (!text.trim() && selectedFiles.length === 0)) return;
    setIsSending(true);
    const filesToSend = [...selectedFiles];
    const textToSend = text.trim();
    setText('');
    setSelectedFiles([]);
    onCancelReply();

    const fileName = filesToSend[0]?.name || 'file';

    try {
      await sendMessage(
        textToSend || undefined,
        filesToSend,
        replyingTo?.id,
        filesToSend.length > 0
          ? (pct, loaded, total) => setUploadProgress({ pct, loaded, total, fileName })
          : undefined
      );
    } catch (err: any) {
      alert(`Upload failed: ${err.message || 'File size exceeds limit or network error'}`);
    } finally {
      setIsSending(false);
      setUploadProgress(null);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files);
      setSelectedFiles((prev) => [...prev, ...files]);
    }
  };

  const removeFile = (idx: number) => {
    setSelectedFiles((prev) => prev.filter((_, i) => i !== idx));
  };

  // Voice recording via MediaRecorder
  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorder = new MediaRecorder(stream);
      mediaRecorderRef.current = recorder;
      audioChunksRef.current = [];

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) audioChunksRef.current.push(e.data);
      };

      recorder.onstop = async () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/webm' });
        const audioFile = new File([audioBlob], `voice_${Date.now()}.webm`, { type: 'audio/webm' });
        await sendMessage(undefined, [audioFile], replyingTo?.id);
        stream.getTracks().forEach((track) => track.stop());
      };

      recorder.start();
      setIsRecording(true);
      setRecordSeconds(0);
      recordTimerRef.current = setInterval(() => {
        setRecordSeconds((s) => s + 1);
      }, 1000);
    } catch (err) {
      console.error('Error recording audio:', err);
      alert('Microphone permission denied or not supported');
    }
  };

  const stopAndSendRecording = () => {
    clearInterval(recordTimerRef.current);
    mediaRecorderRef.current?.stop();
    setIsRecording(false);
  };

  const cancelRecording = () => {
    clearInterval(recordTimerRef.current);
    if (mediaRecorderRef.current) {
      mediaRecorderRef.current.onstop = null;
      mediaRecorderRef.current.stop();
      mediaRecorderRef.current.stream.getTracks().forEach((t) => t.stop());
    }
    setIsRecording(false);
  };

  const formatTimer = (s: number) =>
    `${Math.floor(s / 60).toString().padStart(2, '0')}:${(s % 60).toString().padStart(2, '0')}`;

  return (
    <div className="border-t border-zinc-800/80 bg-zinc-950 p-4">
      {/* Replying banner */}
      {replyingTo && (
        <div className="mb-2 p-2.5 rounded-xl bg-zinc-900 border border-zinc-800 flex items-center justify-between text-xs text-zinc-300">
          <div className="flex items-center gap-2 truncate">
            <span className="font-semibold text-indigo-400">Replying to {replyingTo.sender?.name}:</span>
            <span className="truncate text-zinc-400">{replyingTo.text || 'Attachment'}</span>
          </div>
          <button onClick={onCancelReply} className="p-1 hover:text-white">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Upload progress banner */}
      {uploadProgress && (
        <div className="mb-2 p-2.5 rounded-xl bg-zinc-900 border border-indigo-500/40 shadow-lg select-none">
          <div className="flex items-center justify-between text-xs mb-1">
            <span className="font-semibold text-zinc-200 truncate">Uploading {uploadProgress.fileName}</span>
            <span className="text-indigo-400 font-bold ml-2">{uploadProgress.pct}%</span>
          </div>
          <div className="w-full bg-zinc-800 rounded-full h-1.5 overflow-hidden">
            <div
              className="bg-indigo-500 h-full rounded-full transition-all duration-150"
              style={{ width: `${uploadProgress.pct}%` }}
            />
          </div>
          <div className="mt-1 flex justify-between text-[10px] text-zinc-400">
            <span>{(uploadProgress.loaded / (1024 * 1024)).toFixed(1)} MB / {(uploadProgress.total / (1024 * 1024)).toFixed(1)} MB</span>
            <span>Uploading to server...</span>
          </div>
        </div>
      )}

      {/* Selected file badges */}
      {selectedFiles.length > 0 && (
        <div className="flex gap-2 mb-2 overflow-x-auto pb-1">
          {selectedFiles.map((f, i) => (
            <div key={i} className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-zinc-800 text-xs text-zinc-200 border border-zinc-700">
              {f.type.startsWith('image/') ? <ImageIcon className="w-3.5 h-3.5 text-indigo-400" /> : <FileText className="w-3.5 h-3.5 text-zinc-400" />}
              <span className="max-w-[120px] truncate">{f.name}</span>
              <button onClick={() => removeFile(i)} className="hover:text-red-400">
                <X className="w-3 h-3" />
              </button>
            </div>
          ))}
        </div>
      )}

      {isRecording ? (
        <div className="flex items-center justify-between p-3 rounded-2xl bg-zinc-900 border border-red-500/30">
          <div className="flex items-center gap-3">
            <span className="w-3 h-3 rounded-full bg-red-500 animate-pulse" />
            <span className="text-sm font-semibold text-white">Recording Voice {formatTimer(recordSeconds)}</span>
          </div>
          <div className="flex items-center gap-2">
            <button onClick={cancelRecording} title="Cancel" className="p-2 rounded-xl text-zinc-400 hover:text-red-400 hover:bg-zinc-800">
              <Trash2 className="w-5 h-5" />
            </button>
            <button onClick={stopAndSendRecording} title="Stop and Send" className="px-3 py-1.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold flex items-center gap-1.5">
              <StopCircle className="w-4 h-4" /> Send Note
            </button>
          </div>
        </div>
      ) : (
        <div className="flex items-end gap-2 bg-zinc-900 border border-zinc-800 rounded-2xl p-2 focus-within:border-indigo-500 transition">
          <input ref={fileInputRef} type="file" multiple onChange={handleFileSelect} className="hidden" />

          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            title="Attach images, video, APK, PDF, ZIP"
            className="p-2 text-zinc-400 hover:text-indigo-400 hover:bg-zinc-800 rounded-xl transition"
          >
            <Paperclip className="w-5 h-5" />
          </button>

          <textarea
            rows={1}
            placeholder="Type a message... (Enter to send, Shift+Enter for new line)"
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={handleKeyDown}
            className="flex-1 bg-transparent text-sm text-white placeholder-zinc-500 focus:outline-none resize-none max-h-32 py-2"
          />

          {text.trim() || selectedFiles.length > 0 ? (
            <button
              onClick={handleSend}
              disabled={isSending}
              className="p-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white transition shadow-lg shadow-indigo-600/20"
            >
              <Send className="w-5 h-5" />
            </button>
          ) : (
            <button
              type="button"
              onClick={startRecording}
              title="Record voice message"
              className="p-2 text-zinc-400 hover:text-indigo-400 hover:bg-zinc-800 rounded-xl transition"
            >
              <Mic className="w-5 h-5" />
            </button>
          )}
        </div>
      )}
    </div>
  );
};
