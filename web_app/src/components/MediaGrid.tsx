import React, { useState, useEffect } from 'react';
import { resolveMediaUrl } from '../services/api';
import { Play, X, ChevronLeft, ChevronRight, Download } from 'lucide-react';

interface MediaItem {
  id?: string;
  fileUrl: string;
  fileName?: string;
  fileType: string;
}

interface Props {
  items: MediaItem[];
}

export const MediaGrid: React.FC<Props> = ({ items }) => {
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);

  useEffect(() => {
    if (lightboxIndex === null) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setLightboxIndex(null);
      if (e.key === 'ArrowLeft') setLightboxIndex((prev) => (prev !== null && prev > 0 ? prev - 1 : items.length - 1));
      if (e.key === 'ArrowRight') setLightboxIndex((prev) => (prev !== null && prev < items.length - 1 ? prev + 1 : 0));
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [lightboxIndex, items.length]);

  if (!items || items.length === 0) return null;

  const count = items.length;
  const visibleItems = count > 4 ? items.slice(0, 4) : items;
  const remaining = count - 4;

  const renderTile = (item: MediaItem, index: number, className: string = '') => {
    const url = resolveMediaUrl(item.fileUrl);
    const isVideo = item.fileType === 'video' || item.fileName?.toLowerCase().endsWith('.mp4');
    const isLastWithMore = index === 3 && remaining > 0;

    return (
      <div
        key={item.id || item.fileUrl || index}
        onClick={() => setLightboxIndex(index)}
        className={`relative overflow-hidden cursor-pointer group bg-zinc-950/60 rounded-xl transition hover:brightness-105 ${className}`}
      >
        {isVideo ? (
          <div className="w-full h-full flex items-center justify-center bg-zinc-900 relative">
            <video src={url} className="w-full h-full object-cover pointer-events-none" preload="metadata" />
            <div className="absolute inset-0 flex items-center justify-center bg-black/30 group-hover:bg-black/20 transition">
              <div className="w-10 h-10 rounded-full bg-black/60 backdrop-blur-sm flex items-center justify-center text-white border border-white/20 shadow-lg">
                <Play className="w-5 h-5 ml-0.5 fill-white" />
              </div>
            </div>
          </div>
        ) : (
          <img
            src={url}
            alt={item.fileName || 'media'}
            className="w-full h-full object-cover transition duration-300 group-hover:scale-105"
            loading="lazy"
          />
        )}

        {isLastWithMore && (
          <div className="absolute inset-0 bg-black/65 backdrop-blur-[2px] flex items-center justify-center text-white font-bold text-xl tracking-wider select-none">
            +{remaining + 1}
          </div>
        )}
      </div>
    );
  };

  const renderGrid = () => {
    if (count === 1) {
      return (
        <div className="max-w-sm max-h-72 w-full rounded-2xl overflow-hidden mt-1 shadow-sm">
          {renderTile(items[0], 0, 'w-full max-h-72')}
        </div>
      );
    }

    if (count === 2) {
      return (
        <div className="grid grid-cols-2 gap-1.5 w-full max-w-md h-48 mt-1">
          {items.map((item, idx) => renderTile(item, idx, 'h-full'))}
        </div>
      );
    }

    if (count === 3) {
      return (
        <div className="grid grid-cols-2 gap-1.5 w-full max-w-md h-56 mt-1">
          {renderTile(items[0], 0, 'row-span-2 h-full')}
          {renderTile(items[1], 1, 'h-full')}
          {renderTile(items[2], 2, 'h-full')}
        </div>
      );
    }

    return (
      <div className="grid grid-cols-2 gap-1.5 w-full max-w-md h-64 mt-1">
        {visibleItems.map((item, idx) => renderTile(item, idx, 'h-full'))}
      </div>
    );
  };

  const activeMedia = lightboxIndex !== null ? items[lightboxIndex] : null;
  const activeUrl = activeMedia ? resolveMediaUrl(activeMedia.fileUrl) : '';
  const isCurrentVideo = activeMedia?.fileType === 'video' || activeMedia?.fileName?.toLowerCase().endsWith('.mp4');

  return (
    <>
      {renderGrid()}

      {/* Full-screen Lightbox */}
      {lightboxIndex !== null && activeMedia && (
        <div className="fixed inset-0 z-[100] bg-black/90 backdrop-blur-md flex items-center justify-center p-4 animate-in fade-in duration-200">
          <div className="absolute top-4 right-4 flex items-center gap-3 z-10">
            <a
              href={activeUrl}
              download={activeMedia.fileName || 'media'}
              target="_blank"
              rel="noreferrer"
              className="p-2.5 rounded-full bg-white/10 hover:bg-white/20 text-white transition backdrop-blur-sm"
              title="Download"
            >
              <Download className="w-5 h-5" />
            </a>
            <button
              onClick={() => setLightboxIndex(null)}
              className="p-2.5 rounded-full bg-white/10 hover:bg-white/20 text-white transition backdrop-blur-sm"
              title="Close (Esc)"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="absolute top-4 left-4 text-xs font-semibold text-white/80 select-none bg-black/40 px-3 py-1.5 rounded-full backdrop-blur-sm border border-white/10">
            {lightboxIndex + 1} / {count}
          </div>

          {count > 1 && (
            <>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setLightboxIndex((prev) => (prev !== null && prev > 0 ? prev - 1 : count - 1));
                }}
                className="absolute left-4 top-1/2 -translate-y-1/2 p-3 rounded-full bg-black/50 hover:bg-black/75 text-white transition backdrop-blur-sm border border-white/10"
              >
                <ChevronLeft className="w-6 h-6" />
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setLightboxIndex((prev) => (prev !== null && prev < count - 1 ? prev + 1 : 0));
                }}
                className="absolute right-4 top-1/2 -translate-y-1/2 p-3 rounded-full bg-black/50 hover:bg-black/75 text-white transition backdrop-blur-sm border border-white/10"
              >
                <ChevronRight className="w-6 h-6" />
              </button>
            </>
          )}

          <div className="max-w-4xl max-h-[85vh] w-full h-full flex items-center justify-center" onClick={(e) => e.stopPropagation()}>
            {isCurrentVideo ? (
              <video src={activeUrl} controls autoPlay className="max-w-full max-h-[85vh] rounded-2xl shadow-2xl bg-black" />
            ) : (
              <img src={activeUrl} alt={activeMedia.fileName || 'preview'} className="max-w-full max-h-[85vh] object-contain rounded-2xl shadow-2xl" />
            )}
          </div>
        </div>
      )}
    </>
  );
};

