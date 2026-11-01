import React, { useState } from 'react';
import { useChat } from '../context/ChatContext';
import { Message } from '../types';
import { ChatHeader } from './ChatHeader';
import { MessageList } from './MessageList';
import { MessageInput } from './MessageInput';
import { MessageSquareDashed } from 'lucide-react';

export const ChatArea: React.FC = () => {
  const { activeChat, messages } = useChat();
  const [isSearching, setIsSearching] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [replyingTo, setReplyingTo] = useState<Message | null>(null);

  if (!activeChat) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-8 bg-zinc-900/20 text-center select-none">
        <div className="w-16 h-16 rounded-2xl bg-zinc-800/80 flex items-center justify-center text-zinc-500 mb-4 border border-zinc-700/50">
          <MessageSquareDashed className="w-8 h-8" />
        </div>
        <h3 className="text-lg font-semibold text-white mb-1">Select a conversation</h3>
        <p className="text-sm text-zinc-500 max-w-sm">
          Choose an existing chat or click the new message button to start talking.
        </p>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col h-full bg-zinc-950/90 relative overflow-hidden bg-[radial-gradient(#27272a_1px,transparent_1px)] [background-size:24px_24px]">
      <ChatHeader
        isSearching={isSearching}
        searchQuery={searchQuery}
        onToggleSearch={setIsSearching}
        onSearchChange={setSearchQuery}
      />
      <MessageList
        messages={messages}
        searchQuery={isSearching ? searchQuery : undefined}
        onReply={(msg) => setReplyingTo(msg)}
      />
      <MessageInput
        replyingTo={replyingTo}
        onCancelReply={() => setReplyingTo(null)}
      />
    </div>
  );
};

