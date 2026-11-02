import React, { useState } from 'react';
import { useAuth } from './context/AuthContext';
import { LoginView } from './components/LoginView';
import { Sidebar } from './components/Sidebar';
import { ChatArea } from './components/ChatArea';
import { NewChatModal } from './components/NewChatModal';
import { CreateGroupModal } from './components/CreateGroupModal';
import { SettingsModal } from './components/SettingsModal';
import { IncomingCallModal } from './components/IncomingCallModal';
import { ActiveCallModal } from './components/ActiveCallModal';
import { Loader2 } from 'lucide-react';

export const App: React.FC = () => {
  const { user, isLoading } = useAuth();
  const [isNewChatOpen, setIsNewChatOpen] = useState(false);
  const [isCreateGroupOpen, setIsCreateGroupOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-zinc-950 flex items-center justify-center text-indigo-500">
        <Loader2 className="w-8 h-8 animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <LoginView />;
  }

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-zinc-950 font-sans text-zinc-100">
      <Sidebar
        onOpenNewChat={() => setIsNewChatOpen(true)}
        onOpenCreateGroup={() => setIsCreateGroupOpen(true)}
        onOpenSettings={() => setIsSettingsOpen(true)}
      />
      <ChatArea />

      <NewChatModal isOpen={isNewChatOpen} onClose={() => setIsNewChatOpen(false)} />
      <CreateGroupModal isOpen={isCreateGroupOpen} onClose={() => setIsCreateGroupOpen(false)} />
      <SettingsModal isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} />

      <IncomingCallModal />
      <ActiveCallModal />
    </div>
  );
};

export default App;

