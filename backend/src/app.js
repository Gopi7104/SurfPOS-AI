'use strict';

// Express app instance — routes + middleware wiring only, no `listen()` call, so the app is
// testable without binding a port (server.js does that) — see docs/07_CODING_RULES.md § 15.

const { randomUUID } = require('crypto');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const pinoHttp = require('pino-http');

const config = require('./config');
const { logger } = require('./utils/logger');
const { NotFoundError } = require('./utils/errors');
const { API_ROUTES, MESSAGES } = require('./constants');
const errorMiddleware = require('./middleware/error.middleware');
const { createRateLimiter } = require('./middleware/rateLimit.middleware');
const healthRoutes = require('./routes/health.routes');

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: config.corsAllowedOrigins === '*' ? true : config.corsAllowedOrigins }));
app.use(compression());
app.use(express.json());

app.use(
  pinoHttp({
    logger,
    genReqId: (req, res) => {
      const requestId = req.headers['x-request-id'] || randomUUID();
      res.setHeader('X-Request-Id', requestId);
      return requestId;
    },
    // quietReqLogger surfaces the request id as a flat `requestId` field (renamed below) instead
    // of nested inside `req` — see docs/07_CODING_RULES.md § 9 for the required per-line fields.
    quietReqLogger: true,
    customAttributeKeys: { reqId: 'requestId' },
    // req.ip/req.headers/req.user are only reliably populated on the live Express request here —
    // pino-http's req/res serializers below receive a plain snapshot, not the live object.
    customProps: (req) => ({
      ip: req.ip,
      userAgent: req.headers['user-agent'],
      merchantId: req.user?.merchantId,
      userId: req.user?.uid,
    }),
    serializers: {
      req(req) {
        return { method: req.method, url: req.url };
      },
      res(res) {
        return { statusCode: res.statusCode };
      },
    },
  }),
);

// Liveness probe stays outside the rate limiter — see docs/04_API_DOCUMENTATION.md § 13.
app.use(API_ROUTES.HEALTH, healthRoutes);

app.use(createRateLimiter());

app.use((req, res, next) => {
  next(new NotFoundError(MESSAGES.routeNotFound(req.method, req.originalUrl)));
});

app.use(errorMiddleware);

module.exports = app;
