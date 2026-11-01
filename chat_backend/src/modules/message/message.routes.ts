import { Router } from 'express';
import { MessageController } from './message.controller.js';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { uploadMedia } from '../../middlewares/upload.middleware.js';
import { validateBody } from '../../middlewares/validate.middleware.js';
import { forwardMessageSchema, reactMessageSchema } from './message.validator.js';

const router = Router();

// All message routes require authentication
router.use(authenticate as any);

router.get('/:chatId/search', MessageController.searchMessages);
router.put('/:chatId/read', MessageController.markAsRead);
router.get('/:chatId', MessageController.getMessages);
router.post('/', uploadMedia.array('files', 10), MessageController.sendMessage);
router.post('/forward', validateBody(forwardMessageSchema), MessageController.forwardMessage);
router.post('/ack-delivery', MessageController.ackDelivery);
router.delete('/:id/unsend', MessageController.unsend);
router.delete('/:id/delete-for-me', MessageController.deleteForMe);
router.post('/:id/react', validateBody(reactMessageSchema), MessageController.react);

export default router;
