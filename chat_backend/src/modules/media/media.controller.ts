import { Response } from 'express';
import fs from 'fs';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';
import { MediaService } from './media.service.js';
import { sendError } from '../../utils/response.js';

export class MediaController {
  /**
   * Download any media file (images, videos, zip, documents)
   * Sends headers indicating whether mobile/desktop app should auto-save to device gallery
   */
  static async download(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const attachmentId = req.params.attachmentId as string;

      const { attachment, filePath, canSaveToGallery } =
        await MediaService.getAttachmentDetails(attachmentId, userId);

      res.setHeader(
        'Content-Disposition',
        `attachment; filename="${encodeURIComponent(attachment.fileName)}"`
      );
      res.setHeader('Content-Type', attachment.mimeType);
      res.setHeader('X-Auto-Save-Gallery', canSaveToGallery ? 'true' : 'false');
      res.setHeader('X-File-Type', attachment.fileType);
      res.setHeader('X-Original-Filename', attachment.fileName);

      const fileStream = fs.createReadStream(filePath);
      fileStream.pipe(res);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to download file', 404);
    }
  }

  /**
   * Stream video or audio with HTTP 206 Partial Content support
   */
  static async stream(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const attachmentId = req.params.attachmentId as string;

      const { attachment, filePath } = await MediaService.getAttachmentDetails(
        attachmentId,
        userId
      );

      const stat = fs.statSync(filePath);
      const fileSize = stat.size;
      const range = req.headers.range;

      if (range) {
        const parts = range.replace(/bytes=/, '').split('-');
        const start = parseInt(parts[0], 10);
        const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
        const chunkSize = end - start + 1;
        const fileStream = fs.createReadStream(filePath, { start, end });

        res.writeHead(206, {
          'Content-Range': `bytes ${start}-${end}/${fileSize}`,
          'Accept-Ranges': 'bytes',
          'Content-Length': chunkSize,
          'Content-Type': attachment.mimeType,
        });
        fileStream.pipe(res);
      } else {
        res.writeHead(200, {
          'Content-Length': fileSize,
          'Content-Type': attachment.mimeType,
        });
        fs.createReadStream(filePath).pipe(res);
      }
    } catch (error: any) {
      sendError(res, error.message || 'Failed to stream media', 404);
    }
  }
}
