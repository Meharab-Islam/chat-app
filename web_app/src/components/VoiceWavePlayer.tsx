import React, { useState, useRef, useEffect } from 'react';
import { Play, Pause, Mic } from 'lucide-react';

interface Props {
  audioUrl: string;
  isMe: boolean;
}

// 28 waveform bars with varying heights (in px) simulating an audio waveform
const WAVE_BARS = [
  10, 16, 24, 14, 28, 20, 12, 26, 32, 18, 22, 12, 20, 30,
  26, 14, 18, 26, 28, 16, 22, 26, 14, 10, 22, 16, 12, 18,
];

export const VoiceWavePlayer: React.FC<Props> = ({ audioUrl, isMe }) => {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const onLoadedMetadata = () => {
      if (audio.duration && !isNaN(audio.duration)) {
        setDuration(audio.duration);
      }
    };

    const onTimeUpdate = () => {
      setCurrentTime(audio.currentTime);
    };

    const onEnded = () => {
      setIsPlaying(false);
      setCurrentTime(0);
    };

    audio.addEventListener('loadedmetadata', onLoadedMetadata);
    audio.addEventListener('timeupdate', onTimeUpdate);
    audio.addEventListener('ended', onEnded);

    return () => {
      audio.removeEventListener('loadedmetadata', onLoadedMetadata);
      audio.removeEventListener('timeupdate', onTimeUpdate);
      audio.removeEventListener('ended', onEnded);
    };
  }, []);

  const togglePlay = () => {
    const audio = audioRef.current;
    if (!audio) return;
    if (isPlaying) {
      audio.pause();
      setIsPlaying(false);
    } else {
      audio.play().then(() => setIsPlaying(true)).catch((e) => console.error(e));
    }
  };

  const handleSeek = (e: React.MouseEvent<HTMLDivElement>) => {
    const audio = audioRef.current;
    if (!audio || !duration) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const pct = Math.max(0, Math.min(1, clickX / rect.width));
    const newTime = pct * duration;
    audio.currentTime = newTime;
    setCurrentTime(newTime);
  };

  const formatTime = (secs: number) => {
    if (isNaN(secs) || secs < 0) return '0:00';
    const m = Math.floor(secs / 60);
    const s = Math.floor(secs % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  const progress = duration > 0 ? currentTime / duration : 0;

  return (
    <div className={`mt-1 flex items-center gap-3 p-2 rounded-2xl w-64 select-none ${
      isMe ? 'bg-white/10' : 'bg-black/30'
    }`}>
      <audio ref={audioRef} src={audioUrl} preload="metadata" />

      {/* Play/Pause Button */}
      <button
        onClick={togglePlay}
        className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 transition shadow hover:scale-105 active:scale-95 ${
          isMe
            ? 'bg-white text-indigo-600'
            : 'bg-indigo-600 text-white hover:bg-indigo-500'
        }`}
      >
        {isPlaying ? (
          <Pause className="w-4 h-4 fill-current" />
        ) : (
          <Play className="w-4 h-4 fill-current ml-0.5" />
        )}
      </button>

      {/* Waveform Visualization */}
      <div className="flex-1 flex flex-col justify-center gap-1.5 cursor-pointer py-1" onClick={handleSeek}>
        <div className="flex items-center gap-[2.5px] h-8">
          {WAVE_BARS.map((height, i) => {
            const barPct = i / WAVE_BARS.length;
            const isPlayed = barPct <= progress;
            return (
              <span
                key={i}
                style={{ height: `${height}px` }}
                className={`w-[3px] rounded-full transition-all duration-150 ${
                  isPlayed
                    ? isMe ? 'bg-white shadow-[0_0_8px_rgba(255,255,255,0.6)]' : 'bg-indigo-400'
                    : isMe ? 'bg-white/35' : 'bg-zinc-600'
                } ${isPlaying && isPlayed ? 'animate-pulse' : ''}`}
              />
            );
          })}
        </div>

        {/* Duration & Mic Icon */}
        <div className="flex items-center justify-between text-[10px] font-medium opacity-80">
          <span>{formatTime(isPlaying ? currentTime : (duration || 0))}</span>
          <Mic className="w-3 h-3 opacity-60" />
        </div>
      </div>
    </div>
  );
};

