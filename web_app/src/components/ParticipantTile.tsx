import React, { useEffect, useRef, useState } from 'react';
import { Participant, Track, TrackPublication } from 'livekit-client';
import { Mic, MicOff } from 'lucide-react';

interface Props {
  participant: Participant;
  isLocal?: boolean;
}

export const ParticipantTile: React.FC<Props> = ({ participant, isLocal = false }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const audioRef = useRef<HTMLAudioElement>(null);
  const [isVideoEnabled, setIsVideoEnabled] = useState(participant.isCameraEnabled);
  const [isMuted, setIsMuted] = useState(!participant.isMicrophoneEnabled);
  const [isSpeaking, setIsSpeaking] = useState(participant.isSpeaking);

  useEffect(() => {
    const updateTracks = () => {
      setIsVideoEnabled(participant.isCameraEnabled);
      setIsMuted(!participant.isMicrophoneEnabled);
      setIsSpeaking(participant.isSpeaking);

      // Attach video
      const camPub = Array.from(participant.videoTrackPublications.values()).find(
        (p) => p.source === Track.Source.Camera || p.source === Track.Source.ScreenShare
      );
      if (camPub && camPub.track && videoRef.current) {
        camPub.track.attach(videoRef.current);
      }

      // Attach audio for remote participants
      if (!isLocal) {
        const micPub = Array.from(participant.audioTrackPublications.values()).find(
          (p) => p.source === Track.Source.Microphone
        );
        if (micPub && micPub.track && audioRef.current) {
          micPub.track.attach(audioRef.current);
        }
      }
    };

    updateTracks();

    participant.on('trackMuted', updateTracks);
    participant.on('trackUnmuted', updateTracks);
    participant.on('isSpeakingChanged', (speaking) => setIsSpeaking(speaking));

    return () => {
      participant.off('trackMuted', updateTracks);
      participant.off('trackUnmuted', updateTracks);
    };
  }, [participant, isLocal]);

  const name = participant.name || (isLocal ? 'You' : participant.identity);

  return (
    <div
      className={`relative bg-zinc-900 rounded-2xl overflow-hidden border flex items-center justify-center aspect-video w-full transition-all duration-300 ${
        isSpeaking ? 'border-emerald-500 shadow-[0_0_15px_rgba(16,185,129,0.3)] ring-2 ring-emerald-500/50' : 'border-zinc-800'
      }`}
    >
      <video
        ref={videoRef}
        autoPlay
        playsInline
        muted={isLocal}
        className={`w-full h-full object-cover ${isVideoEnabled ? 'block' : 'hidden'}`}
      />
      {!isLocal && <audio ref={audioRef} autoPlay />}

      {!isVideoEnabled && (
        <div className="flex flex-col items-center justify-center gap-3">
          <div
            className={`w-20 h-20 rounded-full flex items-center justify-center font-bold text-2xl text-white bg-gradient-to-tr from-indigo-600 to-violet-500 shadow-xl ${
              isSpeaking ? 'animate-pulse scale-105' : ''
            }`}
          >
            {name.charAt(0).toUpperCase()}
          </div>
        </div>
      )}

      {/* Participant name tag & mic indicator */}
      <div className="absolute bottom-3 left-3 flex items-center gap-2 bg-black/60 backdrop-blur-md px-3 py-1.5 rounded-lg text-xs text-white border border-white/10">
        <span>{name} {isLocal && '(You)'}</span>
        {isMuted ? (
          <MicOff className="w-3.5 h-3.5 text-red-400" />
        ) : (
          <Mic className={`w-3.5 h-3.5 ${isSpeaking ? 'text-emerald-400' : 'text-zinc-400'}`} />
        )}
      </div>
    </div>
  );
};
