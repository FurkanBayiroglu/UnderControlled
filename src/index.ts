import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import serverless from 'serverless-http';
import dotenv from 'dotenv';

// Routes
import chatRoutes from './routes/chat';
import recommendationRoutes from './routes/recommendation';
import healthRoutes from './routes/health';

// Load environment variables
dotenv.config();

const app: Application = express();

// Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }
}));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req: Request, _res: Response, next: NextFunction) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Routes
app.use('/api/chat', chatRoutes);
app.use('/api/recommend', recommendationRoutes);
app.use('/api/health', healthRoutes);

// Root endpoint
app.get('/', (_req: Request, res: Response) => {
  res.json({
    name: 'UnderControl AI Backend',
    version: '2.0.0',
    status: 'running',
    endpoints: {
      health: '/api/health',
      chat: '/api/chat',
      recommend: '/api/recommend'
    }
  });
});

// 404 handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Endpoint bulunamadı' });
});

// Error handler
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error('Server error:', err);
  res.status(500).json({ 
    error: 'Sunucu hatası',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Local development
if (process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  });
}

// Lambda handler
export const handler = serverless(app);
export default app;
