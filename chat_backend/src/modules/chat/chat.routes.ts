import { Router } from 'express';
import { ChatController } from './chat.controller.js';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { uploadAvatar } from '../../middlewares/upload.middleware.js';
import { validateBody } from '../../middlewares/validate.middleware.js';
import { createDirectChatSchema, createGroupChatSchema } from './chat.validator.js';

const router = Router();

// All chat routes require authentication
router.use(authenticate as any);

router.get('/', ChatController.getMyChats);
router.post('/direct', validateBody(createDirectChatSchema), ChatController.createDirectChat);
router.post('/group', validateBody(createGroupChatSchema), ChatController.createGroupChat);
router.get('/:id', ChatController.getChatDetails);
router.put('/:id', uploadAvatar.single('avatar'), ChatController.updateGroup);
router.patch('/:id', uploadAvatar.single('avatar'), ChatController.updateGroup);
router.post('/:id/update', uploadAvatar.single('avatar'), ChatController.updateGroup);
router.delete('/:id', ChatController.deleteChat);

export default router;

