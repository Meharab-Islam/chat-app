import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import { Room, RoomEvent, Track } from 'livekit-client';
import { api } from '../services/api';
import { getSocket } from '../services/socket';
import { soundService } from '../utils/sound';
import { IncomingCall } from '../types';

interface CallContextType {
  incomingCall: IncomingCall | null;
  activeCall: {
    chatId: string;
    callType: 'audio' | 'video';
    isGroup: boolean;
    chatName: string;
    callId: string;
  } | null;
  room: Room | null;
  isConnecting: boolean;
  isMuted: boolean;
  isCameraOff: boolean;
  isScreenSharing: boolean;
  startCall: (chatId: string, callType: 'audio' | 'video', chatName: string, isGroup: boolean) => Promise<void>;
  acceptCall: () => Promise<void>;
  rejectCall: () => void;
  endCall: () => void;
  toggleMute: () => Promise<void>;
  toggleCamera: () => Promise<void>;
  toggleScreenShare: () => Promise<void>;
}

const CallContext = createContext<CallContextType | undefined>(undefined);

export const CallProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [incomingCall, setIncomingCall] = useState<IncomingCall | null>(null);
  const [activeCall, setActiveCall] = useState<CallContextType['activeCall']>(null);
  const [room, setRoom] = useState<Room | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [isCameraOff, setIsCameraOff] = useState(false);
  const [isScreenSharing, setIsScreenSharing] = useState(false);
  const roomRef = useRef<Room | null>(null);

  const endCall = useCallback(() => {
    soundService.playEndSound();
    if (roomRef.current) {
      roomRef.current.disconnect();
      roomRef.current = null;
    }
    setRoom(null);
    if (activeCall) {
      const socket = getSocket();
      socket?.emit('call:end', { callId: activeCall.callId, chatId: activeCall.chatId });
    }
    setActiveCall(null);
    setIsConnecting(false);
    setIsMuted(false);
    setIsCameraOff(false);
    setIsScreenSharing(false);
  }, [activeCall]);

  const connectToRoom = async (chatId: string, callType: 'audio' | 'video') => {
    setIsConnecting(true);
    try {
      const data = await api.getCallToken(chatId, callType);
      const newRoom = new Room({
        adaptiveStream: true,
        dynacast: true,
      });

      newRoom.on(RoomEvent.Disconnected, () => {
        endCall();
      });

      await newRoom.connect(data.url, data.token);
      try {
        await newRoom.localParticipant.setMicrophoneEnabled(true);
      } catch (micErr) {
        console.warn('Microphone permission or device error:', micErr);
        setIsMuted(true);
      }
      if (callType === 'video') {
        try {
          await newRoom.localParticipant.setCameraEnabled(true);
        } catch (camErr) {
          console.warn('Camera permission or device error:', camErr);
          setIsCameraOff(true);
        }
      }

      roomRef.current = newRoom;
      setRoom(newRoom);
      setIsCameraOff(callType === 'audio');
      setIsMuted(false);
      return newRoom;
    } catch (err) {
      console.error('Failed to connect to LiveKit room:', err);
      endCall();
      throw err;
    } finally {
      setIsConnecting(false);
    }
  };

  const startCall = async (chatId: string, callType: 'audio' | 'video', chatName: string, isGroup: boolean) => {
    const callId = `call_${Date.now()}`;
    setActiveCall({ chatId, callType, isGroup, chatName, callId });
    const socket = getSocket();
    socket?.emit('call:initiate', { callId, chatId, callType });
    await connectToRoom(chatId, callType);
  };

  const acceptCall = async () => {
    if (!incomingCall) return;
    soundService.stopRinging();
    const current = incomingCall;
    setIncomingCall(null);
    setActiveCall({
      chatId: current.chatId,
      callType: current.callType,
      isGroup: current.isGroup,
      chatName: current.chatName || 'Group Call',
      callId: current.callId,
    });
    const socket = getSocket();
    socket?.emit('call:accept', { callId: current.callId, chatId: current.chatId });
    await connectToRoom(current.chatId, current.callType);
  };

  const rejectCall = () => {
    soundService.stopRinging();
    if (incomingCall) {
      const socket = getSocket();
      socket?.emit('call:reject', { callId: incomingCall.callId, chatId: incomingCall.chatId, reason: 'declined' });
      setIncomingCall(null);
    }
  };

  const toggleMute = async () => {
    if (!roomRef.current) return;
    const next = !isMuted;
    await roomRef.current.localParticipant.setMicrophoneEnabled(!next);
    setIsMuted(next);
  };

  const toggleCamera = async () => {
    if (!roomRef.current) return;
    const next = !isCameraOff;
    await roomRef.current.localParticipant.setCameraEnabled(!next);
    setIsCameraOff(next);
  };

  const toggleScreenShare = async () => {
    if (!roomRef.current) return;
    const next = !isScreenSharing;
    await roomRef.current.localParticipant.setScreenShareEnabled(next);
    setIsScreenSharing(next);
  };

  useEffect(() => {
    const interval = setInterval(() => {
      const socket = getSocket();
      if (!socket) return;
      clearInterval(interval);

      socket.on('call:incoming', (call: IncomingCall) => {
        if (roomRef.current) {
          socket.emit('call:reject', { callId: call.callId, chatId: call.chatId, reason: 'busy' });
          return;
        }
        setIncomingCall(call);
        soundService.startRinging();
      });

      socket.on('call:ended', () => {
        soundService.stopRinging();
        setIncomingCall(null);
      });

      socket.on('call:rejected', () => {
        // Peer declined
      });
    }, 500);

    return () => clearInterval(interval);
  }, []);

  return (
    <CallContext.Provider
      value={{
        incomingCall,
        activeCall,
        room,
        isConnecting,
        isMuted,
        isCameraOff,
        isScreenSharing,
        startCall,
        acceptCall,
        rejectCall,
        endCall,
        toggleMute,
        toggleCamera,
        toggleScreenShare,
      }}
    >
      {children}
    </CallContext.Provider>
  );
};

export const useCall = () => {
  const context = useContext(CallContext);
  if (!context) throw new Error('useCall must be used within a CallProvider');
  return context;
};

