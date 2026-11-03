/**
 * @axioledger/server-runtime
 *
 * Express application factory with hardened defaults:
 *  - Helmet for HTTP security headers
 *  - CORS with allowlist configuration
 *  - JSON body parsing (limit: 1 mb)
 *  - Centralised error-handling pipeline
 *  - Zod-validated request body middleware
 */
import express, {
  type Application,
  type Request,
  type Response,
  type NextFunction,
  type RequestHandler,
} from 'express';
import helmet from 'helmet';
import cors, { type CorsOptions } from 'cors';
import { ZodError, type ZodSchema } from 'zod';

// ── Application factory ───────────────────────────────────────────────────────

export interface ServerOptions {
  cors?: CorsOptions;
}

export function createServer(options: ServerOptions = {}): Application {
  const app = express();

  app.use(helmet());
  app.use(cors(options.cors));
  app.use(express.json({ limit: '1mb' }));

  // Centralised error handler (must be registered after all routes)
  app.use(
    (err: unknown, _req: Request, res: Response, _next: NextFunction): void => {
      if (err instanceof ZodError) {
        res.status(400).json({ error: 'Validation failed', issues: err.issues });
        return;
      }
      const message = err instanceof Error ? err.message : 'Internal server error';
      res.status(500).json({ error: message });
    },
  );

  return app;
}

// ── Body-validation middleware factory ───────────────────────────────────────

export function validateBody<T>(schema: ZodSchema<T>): RequestHandler {
  return (req: Request, res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      res.status(400).json({ error: 'Validation failed', issues: result.error.issues });
      return;
    }
    (req as Request & { validatedBody: T }).validatedBody = result.data;
    next();
  };
}

export { express };
export type { Application, Request, Response, NextFunction, RequestHandler };
