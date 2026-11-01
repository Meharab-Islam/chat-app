import { Router } from 'express';
import { AuthController } from './auth.controller.js';
import { validateBody } from '../../middlewares/validate.middleware.js';
import { googleLoginSchema, refreshTokenSchema } from './auth.validator.js';

const router = Router();

router.post('/google', validateBody(googleLoginSchema), AuthController.googleLogin);
router.post('/quick-login', AuthController.quickLogin);
router.post('/refresh', validateBody(refreshTokenSchema), AuthController.refreshToken);

export default router;

