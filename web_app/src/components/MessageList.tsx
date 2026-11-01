import React, { useEffect, useRef } from 'react';
import { Message } from '../types';
import { MessageItem } from './MessageItem';

interface Props {
  messages: Message[];
  searchQuery?: string;
  onReply: (msg: Message) => void;
}

export const MessageList: React.FC<Props> = ({ messages, searchQuery, onReply }) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  const uniqueMessages = React.useMemo(() => {
    const seen = new Set<string>();
    // Strictly sort ascending by createdAt (oldest at top, newest at bottom)
    const sorted = [...messages].sort(
      (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
    );
    return sorted.filter((m) => {
      if (seen.has(m.id)) return false;
      seen.add(m.id);
      return true;
    });
  }, [messages]);

  const filteredMessages = uniqueMessages.filter((m) => {
    if (!searchQuery?.trim()) return true;
    const q = searchQuery.toLowerCase();
    const textMatch = m.text?.toLowerCase().includes(q);
    const fileMatch = m.attachments?.some((a) => a.fileName.toLowerCase().includes(q));
    return textMatch || fileMatch;
  });

  const scrollToBottom = (behavior: ScrollBehavior = 'smooth') => {
    if (containerRef.current) {
      containerRef.current.scrollTo({
        top: containerRef.current.scrollHeight,
        behavior,
      });
    } else {
      bottomRef.current?.scrollIntoView({ behavior });
    }
  };

  useEffect(() => {
    if (!searchQuery) {
      scrollToBottom('auto');
      const timer = setTimeout(() => scrollToBottom('smooth'), 40);
      return () => clearTimeout(timer);
    }
  }, [filteredMessages.length, searchQuery]);

  return (
    <div ref={containerRef} className="flex-1 overflow-y-auto p-4 sm:p-6 select-text">
      <div className="min-h-full flex flex-col justify-end space-y-2">
        {filteredMessages.length === 0 ? (
          <div className="my-auto flex flex-col items-center justify-center text-zinc-500 text-sm">
            <div className="w-12 h-12 rounded-2xl bg-zinc-800/60 flex items-center justify-center mb-3 text-zinc-400">
              💬
            </div>
            {searchQuery ? 'No matching messages found in this chat' : 'No messages yet. Say hello! 👋'}
          </div>
        ) : (
          filteredMessages.map((msg, index) => {
            const prevMsg = filteredMessages[index - 1];
            const isDifferentDay =
              !prevMsg ||
              new Date(msg.createdAt).toDateString() !== new Date(prevMsg.createdAt).toDateString();

            return (
              <React.Fragment key={msg.id}>
                {isDifferentDay && (
                  <div className="flex items-center justify-center my-4">
                    <span className="px-3 py-1 rounded-full bg-zinc-800/90 text-[11px] text-zinc-300 font-medium shadow-sm border border-zinc-700/50">
                      {new Date(msg.createdAt).toLocaleDateString([], {
                        weekday: 'short',
                        month: 'short',
                        day: 'numeric',
                      })}
                    </span>
                  </div>
                )}
                <MessageItem message={msg} onReply={onReply} />
              </React.Fragment>
            );
          })
        )}
        <div ref={bottomRef} className="h-1" />
      </div>
    </div>
  );
};

