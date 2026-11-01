import multer from 'multer';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { ENV } from '../config/env.js';
import { getFileCategory, sanitizeFileName } from '../utils/fileHelper.js';

// Ensure base upload directories exist
const uploadDirs = ['images', 'videos', 'files', 'avatars', 'audio'];
uploadDirs.forEach((dir) => {
  const fullPath = path.join(process.cwd(), ENV.UPLOAD_DIR, dir);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
});

const storage = multer.diskStorage({
  destination: (_req, file, cb) => {
    let subfolder = 'files';
    if (file.fieldname === 'avatar') {
      subfolder = 'avatars';
    } else {
      const category = getFileCategory(file.mimetype, file.originalname);
      if (category === 'image') subfolder = 'images';
      else if (category === 'video') subfolder = 'videos';
      else if (category === 'audio') subfolder = 'audio';
      else subfolder = 'files';
    }
    const dest = path.join(process.cwd(), ENV.UPLOAD_DIR, subfolder);
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    cb(null, dest);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname);
    const uniqueName = `${crypto.randomUUID()}${ext}`;
    cb(null, uniqueName);
  },
});

export const uploadMedia = multer({
  storage,
  limits: {
    fileSize: ENV.MAX_FILE_SIZE_MB * 1024 * 1024, // in bytes
    files: ENV.MAX_FILES_PER_REQUEST,
  },
});

export const uploadAvatar = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max for avatar
    files: 1,
  },
  fileFilter: (_req, file, cb) => {
    if (
      file.mimetype.startsWith('image/') ||
      /\.(jpe?g|png|webp|gif|bmp|heic|heif)$/i.test(file.originalname)
    ) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed for avatar'));
    }
  },
});

