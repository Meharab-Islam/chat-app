import path from 'path';
import fs from 'fs';
import { prisma } from '../../config/database.js';
import { UserService } from '../user/user.service.js';
import { isGalleryMedia } from '../../utils/fileHelper.js';

export class MediaService {
  /**
   * Resolve attachment and evaluate auto-save to gallery header
   */
  static async getAttachmentDetails(attachmentId: string, userId: string) {
    const attachment = await prisma.attachment.findUnique({
      where: { id: attachmentId },
    });

    if (!attachment) {
      throw new Error('Attachment not found');
    }

    // Check user settings for auto-save gallery preference
    const settings = await UserService.getSettings(userId);
    const canSaveToGallery = Boolean(settings?.autoSaveToGallery && isGalleryMedia(attachment.fileType));

    // Resolve local file path
    const relativePath = attachment.fileUrl.startsWith('/')
      ? attachment.fileUrl.slice(1)
      : attachment.fileUrl;
    const filePath = path.join(process.cwd(), relativePath);

    if (!fs.existsSync(filePath)) {
      throw new Error('File does not exist on server storage');
    }

    return {
      attachment,
      filePath,
      canSaveToGallery,
    };
  }
}

