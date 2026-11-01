import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import path from 'path';

import { ENV } from './config/env.js';
import { notFoundHandler, errorHandler } from './middlewares/error.middleware.js';
import apiRouter from './routes/index.js';

export const createApp = (): Express => {
  const app = express();

  // Security and performance middlewares
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(
    cors({
      origin: ENV.CLIENT_URL === '*' ? '*' : [ENV.CLIENT_URL],
      credentials: true,
    })
  );
  app.use(compression());
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  if (ENV.NODE_ENV !== 'test') {
    app.use(morgan('dev'));
  }

  // Serve static uploaded files
  app.use(
    `/${ENV.UPLOAD_DIR}`,
    express.static(path.join(process.cwd(), ENV.UPLOAD_DIR), {
      maxAge: '7d',
      setHeaders: (res) => {
        res.setHeader('Access-Control-Allow-Origin', '*');
      },
    })
  );

  // Healthcheck endpoint
  app.get('/api/health', (_req, res) => {
    res.status(200).json({ status: 'ok', uptime: process.uptime(), timestamp: new Date() });
  });

  // Mount entire application under the master API Router
  app.use('/api', apiRouter);
  app.use('/api/v1', apiRouter);

  // Error handlers
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
