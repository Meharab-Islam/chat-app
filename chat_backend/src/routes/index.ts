import { Router } from 'express';
import authRoutes from '../modules/auth/auth.routes.js';
import userRoutes from '../modules/user/user.routes.js';
import chatRoutes from '../modules/chat/chat.routes.js';
import messageRoutes from '../modules/message/message.routes.js';
import mediaRoutes from '../modules/media/media.routes.js';

const apiRouter = Router();

// Router health & status endpoint
apiRouter.get('/status', (_req, res) => {
  res.status(200).json({
    status: 'online',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      chats: '/api/chats',
      messages: '/api/messages',
      media: '/api/media',
    },
  });
});

// Mount module sub-routers under master router
apiRouter.use('/auth', authRoutes);
apiRouter.use('/users', userRoutes);
apiRouter.use('/chats', chatRoutes);
apiRouter.use('/messages', messageRoutes);
apiRouter.use('/media', mediaRoutes);

export default apiRouter;

