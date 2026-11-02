import { Router } from 'express';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { CallController } from './call.controller.js';

const router = Router();

// Generate LiveKit token for user to join room
router.post('/token', authenticate, CallController.getToken);

export default router;
