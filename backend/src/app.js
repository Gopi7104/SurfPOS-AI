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
const authRoutes = require('./routes/auth.routes');
const merchantApplicationRoutes = require('./routes/merchantApplication.routes');
const merchantRoutes = require('./routes/merchant.routes');
const storeRoutes = require('./routes/store.routes');
const inventoryRoutes = require('./routes/inventory.routes');
const paymentRoutes = require('./routes/payment.routes');
const paymentRedirectRoutes = require('./routes/paymentRedirect.routes');
const webhookRoutes = require('./routes/webhook.routes');
const aiRoutes = require('./routes/ai.routes');
const customerDataRoutes = require('./routes/customerData.routes');
const salesLedgerRoutes = require('./routes/salesLedger.routes');

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: config.corsAllowedOrigins === '*' ? true : config.corsAllowedOrigins }));
app.use(compression());
// `verify` stashes the exact raw bytes Express received on `req.rawBody` — needed only by
// webhook.controller.js, which must HMAC the *original* bytes (see
// docs/15_SURFBOARD_INTEGRATION.md § 7): re-serializing the already-parsed `req.body` could
// reorder keys/whitespace and silently break Surfboard's signature. Every other route ignores
// `req.rawBody` and keeps using `req.body` exactly as before.
app.use(
  express.json({
    verify: (req, res, buf) => {
      req.rawBody = buf;
    },
  }),
);

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

// Both public (no Firebase auth — see docs/04_API_DOCUMENTATION.md § 1/§ 10), hit directly by
// Surfboard's own servers/hosted page rather than the Flutter app, so they stay outside the
// per-user rate limiter too, same as health.
app.use(API_ROUTES.PAYMENT_REDIRECT, paymentRedirectRoutes);
app.use(API_ROUTES.WEBHOOKS, webhookRoutes);

app.use(createRateLimiter());

app.use(API_ROUTES.AUTH, authRoutes);
// Registered before API_ROUTES.MERCHANT ('/merchant') since it's the more specific prefix —
// Express matches app.use() mounts in registration order, not by specificity.
app.use(API_ROUTES.MERCHANT_APPLICATIONS, merchantApplicationRoutes);
app.use(API_ROUTES.MERCHANT, merchantRoutes);
app.use(API_ROUTES.STORES, storeRoutes);
app.use(API_ROUTES.INVENTORY, inventoryRoutes);
app.use(API_ROUTES.PAYMENTS, paymentRoutes);
app.use(API_ROUTES.AI, aiRoutes);
app.use(API_ROUTES.CUSTOMERS, customerDataRoutes);
app.use(API_ROUTES.REPORTS_SALES, salesLedgerRoutes);

app.use((req, res, next) => {
  next(new NotFoundError(MESSAGES.routeNotFound(req.method, req.originalUrl)));
});

app.use(errorMiddleware);

module.exports = app;
