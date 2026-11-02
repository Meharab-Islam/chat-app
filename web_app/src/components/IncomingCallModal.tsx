import React from 'react';
import { useCall } from '../context/CallContext';
import { resolveMediaUrl } from '../services/api';
import { Phone, PhoneOff, Video, Users } from 'lucide-react';

export const IncomingCallModal: React.FC = () => {
  const { incomingCall, acceptCall, rejectCall } = useCall();

  if (!incomingCall) return null;

  const isVideo = incomingCall.callType === 'video';
  const caller = incomingCall.caller;

  return (
    <div className="fixed top-6 right-6 z-50 animate-bounce-short">
      <div className="bg-zinc-900/95 border border-indigo-500/50 rounded-2xl p-5 shadow-2xl backdrop-blur-xl max-w-sm w-80 text-white border-glow">
        <div className="flex items-center gap-4">
          <div className="relative">
            <img
              src={resolveMediaUrl(caller.avatar) || `https://api.dicebear.com/7.x/avataaars/svg?seed=${caller.name}`}
              alt={caller.name}
              className="w-14 h-14 rounded-full object-cover border-2 border-indigo-500 ring-4 ring-indigo-500/20 animate-pulse"
            />
            <div className="absolute -bottom-1 -right-1 bg-indigo-600 rounded-full p-1.5 shadow">
              {isVideo ? <Video className="w-3.5 h-3.5" /> : <Phone className="w-3.5 h-3.5" />}
            </div>
          </div>

          <div className="flex-1 min-w-0">
            <h4 className="font-semibold text-white truncate text-base">{caller.name}</h4>
            <div className="flex items-center gap-1.5 text-xs text-zinc-400 mt-0.5">
              {incomingCall.isGroup && (
                <span className="flex items-center gap-1 text-indigo-400">
                  <Users className="w-3 h-3" /> {incomingCall.chatName || 'Group'}
                </span>
              )}
              <span>• Incoming {isVideo ? 'Video' : 'Audio'} Call</span>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between gap-3 mt-5">
          <button
            onClick={rejectCall}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-red-500/20 hover:bg-red-500/30 text-red-400 border border-red-500/30 font-medium text-sm transition"
          >
            <PhoneOff className="w-4 h-4" />
            Decline
          </button>
          <button
            onClick={acceptCall}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-medium text-sm shadow-lg shadow-emerald-600/30 transition animate-pulse"
          >
            {isVideo ? <Video className="w-4 h-4" /> : <Phone className="w-4 h-4" />}
            Accept
          </button>
        </div>
      </div>
    </div>
  );
};

