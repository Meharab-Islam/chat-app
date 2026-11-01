import { Router } from 'express';
import { MediaController } from './media.controller.js';
import { authenticate } from '../../middlewares/auth.middleware.js';

const router = Router();

// All media download & stream endpoints require authentication
router.use(authenticate as any);

router.get('/download/:attachmentId', MediaController.download);
router.get('/stream/:attachmentId', MediaController.stream);

export default router;

