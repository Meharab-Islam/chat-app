import React, { useState, useEffect } from 'react';
import { useCall } from '../context/CallContext';
import { ParticipantTile } from './ParticipantTile';
import { Participant, RoomEvent } from 'livekit-client';
import {
  Mic,
  MicOff,
  Video,
  VideoOff,
  Monitor,
  PhoneOff,
  Users,
  Loader2,
} from 'lucide-react';

export const ActiveCallModal: React.FC = () => {
  const {
    activeCall,
    room,
    isConnecting,
    isMuted,
    isCameraOff,
    isScreenSharing,
    endCall,
    toggleMute,
    toggleCamera,
    toggleScreenShare,
  } = useCall();

  const [participants, setParticipants] = useState<Participant[]>([]);
  const [duration, setDuration] = useState(0);

  useEffect(() => {
    if (!activeCall) {
      setDuration(0);
      return;
    }
    const timer = setInterval(() => setDuration((d) => d + 1), 1000);
    return () => clearInterval(timer);
  }, [activeCall]);

  useEffect(() => {
    if (!room) return;

    const updateParticipants = () => {
      setParticipants(Array.from(room.remoteParticipants.values()));
    };

    updateParticipants();

    room.on(RoomEvent.ParticipantConnected, updateParticipants);
    room.on(RoomEvent.ParticipantDisconnected, updateParticipants);

    return () => {
      room.off(RoomEvent.ParticipantConnected, updateParticipants);
      room.off(RoomEvent.ParticipantDisconnected, updateParticipants);
    };
  }, [room]);

  if (!activeCall) return null;

  const formatDuration = (secs: number) => {
    const mins = Math.floor(secs / 60);
    const remainingSecs = secs % 60;
    return `${mins.toString().padStart(2, '0')}:${remainingSecs.toString().padStart(2, '0')}`;
  };

  const allCount = participants.length + (room?.localParticipant ? 1 : 0);

  const getGridCols = (count: number) => {
    if (count <= 1) return 'grid-cols-1 max-w-2xl';
    if (count === 2) return 'grid-cols-1 md:grid-cols-2 max-w-4xl';
    if (count <= 4) return 'grid-cols-2 max-w-4xl';
    return 'grid-cols-2 md:grid-cols-3 max-w-5xl';
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-zinc-950/95 backdrop-blur-2xl text-white">
      {/* Top Header */}
      <div className="h-16 px-6 flex items-center justify-between border-b border-zinc-800/80 bg-zinc-900/50">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center text-indigo-400">
            <Users className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-semibold text-white text-sm md:text-base flex items-center gap-2">
              {activeCall.chatName}
              <span className="text-xs font-normal text-zinc-400">
                ({allCount} {allCount === 1 ? 'person' : 'people'})
              </span>
            </h3>
            <div className="text-xs text-emerald-400 font-mono">
              {isConnecting ? 'Connecting LiveKit WebRTC...' : formatDuration(duration)}
            </div>
          </div>
        </div>
      </div>

      {/* Grid of video / audio tiles */}
      <div className="flex-1 overflow-y-auto p-4 md:p-6 flex items-center justify-center">
        {isConnecting ? (
          <div className="flex flex-col items-center gap-4 text-center">
            <Loader2 className="w-12 h-12 text-indigo-500 animate-spin" />
            <p className="text-zinc-400 text-sm">Joining secure encrypted room...</p>
          </div>
        ) : (
          <div className={`grid gap-4 w-full mx-auto ${getGridCols(allCount)}`}>
            {room?.localParticipant && (
              <ParticipantTile participant={room.localParticipant} isLocal={true} />
            )}
            {participants.map((p) => (
              <ParticipantTile key={p.identity} participant={p} isLocal={false} />
            ))}
          </div>
        )}
      </div>

      {/* Bottom Floating Controls Bar */}
      <div className="h-24 px-6 flex items-center justify-center gap-4 bg-zinc-900/80 border-t border-zinc-800/80">
        <button
          onClick={toggleMute}
          title={isMuted ? 'Microphone Muted (Click to Unmute)' : 'Microphone Active (Click to Mute)'}
          className={`relative p-4 rounded-full transition-all duration-200 ${
            isMuted
              ? 'bg-red-500/20 text-red-400 border border-red-500/40 hover:bg-red-500/30'
              : 'bg-zinc-800 text-emerald-400 hover:bg-zinc-700 ring-1 ring-emerald-500/30'
          }`}
        >
          {isMuted ? <MicOff className="w-6 h-6" /> : <Mic className="w-6 h-6" />}
          {!isMuted && (
            <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          )}
        </button>

        <button
          onClick={toggleCamera}
          title={isCameraOff ? 'Camera Off (Click to Turn On)' : 'Camera On (Click to Turn Off)'}
          className={`relative p-4 rounded-full transition-all duration-200 ${
            isCameraOff
              ? 'bg-red-500/20 text-red-400 border border-red-500/40 hover:bg-red-500/30'
              : 'bg-zinc-800 text-indigo-400 hover:bg-zinc-700 ring-1 ring-indigo-500/30'
          }`}
        >
          {isCameraOff ? <VideoOff className="w-6 h-6" /> : <Video className="w-6 h-6" />}
          {!isCameraOff && (
            <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-indigo-500" />
          )}
        </button>

        <button
          onClick={toggleScreenShare}
          title={isScreenSharing ? 'Stop screen share' : 'Share screen'}
          className={`p-4 rounded-full transition-all duration-200 ${
            isScreenSharing
              ? 'bg-indigo-600 text-white hover:bg-indigo-500'
              : 'bg-zinc-800 text-zinc-300 hover:bg-zinc-700'
          }`}
        >
          <Monitor className="w-6 h-6" />
        </button>

        <button
          onClick={endCall}
          title="End Call"
          className="p-4 rounded-full bg-red-600 hover:bg-red-500 text-white shadow-lg shadow-red-600/30 transition-all duration-200 hover:scale-105"
        >
          <PhoneOff className="w-6 h-6" />
        </button>
      </div>
    </div>
  );
};

