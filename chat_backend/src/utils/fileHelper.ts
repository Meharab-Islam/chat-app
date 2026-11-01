import path from 'path';
import mime from 'mime-types';
import { ALLOWED_FILE_CATEGORIES } from '../config/constants.js';

export type FileCategory = 'image' | 'video' | 'audio' | 'zip' | 'pdf' | 'apk' | 'file';

export const getFileCategory = (mimeType: string, filename = ''): FileCategory => {
  if (/\.apk$/i.test(filename) || mimeType === 'application/vnd.android.package-archive') {
    return 'apk';
  }
  if (/\.pdf$/i.test(filename) || mimeType === 'application/pdf') {
    return 'pdf';
  }
  if (
    mimeType.startsWith('audio/') ||
    ALLOWED_FILE_CATEGORIES.AUDIO.includes(mimeType) ||
    /\.(mp3|wav|ogg|aac|m4a|flac|weba)$/i.test(filename) ||
    (/^voice_/i.test(filename) && /\.(webm|weba|ogg|wav|mp3|m4a|aac)$/i.test(filename))
  ) {
    return 'audio';
  }
  if (ALLOWED_FILE_CATEGORIES.IMAGE.includes(mimeType) || /\.(jpe?g|png|gif|webp|svg|bmp)$/i.test(filename)) {
    return 'image';
  }
  if (
    mimeType.startsWith('video/') ||
    ALLOWED_FILE_CATEGORIES.VIDEO.includes(mimeType) ||
    /\.(mp4|webm|mov|mkv|avi|3gp)$/i.test(filename)
  ) {
    return 'video';
  }
  if (ALLOWED_FILE_CATEGORIES.ARCHIVE.includes(mimeType) || /\.(zip|rar|7z|tar|gz|bz2)$/i.test(filename)) {
    return 'zip';
  }
  return 'file';
};

export const sanitizeFileName = (originalName: string): string => {
  const ext = path.extname(originalName);
  const base = path.basename(originalName, ext).replace(/[^a-zA-Z0-9_-]/g, '_');
  return `${base}${ext}`;
};

export const isGalleryMedia = (fileType: string): boolean => {
  return fileType === 'image' || fileType === 'video';
};

export const getFileMimeType = (filePath: string): string => {
  return (mime.lookup(filePath) as string) || 'application/octet-stream';
};

