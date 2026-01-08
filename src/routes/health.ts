import { Router, Request, Response } from 'express';
import { firestoreService } from '../services/firestoreService';

const router = Router();

/**
 * GET /api/health
 * Basit health check
 */
router.get('/', async (_req: Request, res: Response) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    services: {
      api: 'healthy',
      firestore: firestoreService.isConnected() ? 'connected' : 'disconnected',
      groq: process.env.GROQ_API_KEY ? 'configured' : 'missing'
    }
  };

  const httpStatus = health.services.groq === 'configured' ? 200 : 503;
  return res.status(httpStatus).json(health);
});

/**
 * GET /api/health/detailed
 * Detaylı health check
 */
router.get('/detailed', async (_req: Request, res: Response) => {
  const startTime = Date.now();
  
  // Firestore test
  let firestoreStatus = 'unknown';
  let firestoreLatency = 0;
  let roomCount = 0;
  
  try {
    const fsStart = Date.now();
    const testResult = await firestoreService.testConnection();
    firestoreLatency = Date.now() - fsStart;
    firestoreStatus = testResult.success ? 'healthy' : 'error';
    roomCount = testResult.roomCount || 0;
  } catch (error) {
    firestoreStatus = 'error';
  }

  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '2.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: {
      seconds: Math.floor(process.uptime()),
      formatted: formatUptime(process.uptime())
    },
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
      unit: 'MB'
    },
    services: {
      api: {
        status: 'healthy',
        latency: `${Date.now() - startTime}ms`
      },
      firestore: {
        status: firestoreStatus,
        latency: `${firestoreLatency}ms`,
        connected: firestoreService.isConnected(),
        roomCount
      },
      groq: {
        status: process.env.GROQ_API_KEY ? 'configured' : 'missing',
        model: 'llama-3.3-70b-versatile'
      }
    },
    config: {
      projectId: process.env.FIREBASE_PROJECT_ID || 'not-set',
      region: process.env.AWS_REGION || 'eu-central-1'
    }
  };

  return res.json(health);
});

/**
 * GET /api/health/ping
 */
router.get('/ping', (_req: Request, res: Response) => {
  return res.status(200).send('pong');
});

function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  const parts = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  parts.push(`${secs}s`);

  return parts.join(' ');
}

export default router;
