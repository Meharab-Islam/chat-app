import { Router } from 'express';
import { UserController } from './user.controller.js';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { uploadAvatar } from '../../middlewares/upload.middleware.js';
import { validateBody } from '../../middlewares/validate.middleware.js';
import { updateProfileSchema, updateSettingsSchema } from './user.validator.js';

const router = Router();

// All user routes require authentication
router.use(authenticate as any);

router.get('/me', UserController.getMe);
router.get('/search', UserController.searchUsers);
router.get('/:id', UserController.getProfileById);
router.put('/profile', validateBody(updateProfileSchema), UserController.updateProfile);
router.post('/avatar', uploadAvatar.single('avatar'), UserController.updateAvatar);
router.put('/settings', validateBody(updateSettingsSchema), UserController.updateSettings);
router.put('/fcm-token', UserController.updateFcmToken);

export default router;

