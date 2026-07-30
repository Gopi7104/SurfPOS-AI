'use strict';

// Loads and validates all environment configuration once at boot — see docs/07_CODING_RULES.md § 15.
// Fails fast (process.exit) if a variable required for the running NODE_ENV is missing, rather than
// letting a request fail deep inside a controller because a secret was never set.

const path = require('path');
const dotenv = require('dotenv');
const { z } = require('zod');
const { logger } = require('../utils/logger');
const { ENV_KEYS } = require('../constants');

// Test runs must NEVER load real secrets from .env — Vitest sets NODE_ENV=test before this module
// loads, so this loads .env.test instead (absent by default; dotenv no-ops on a missing file,
// leaving every credential unset, which is exactly what tests/*.test.js's "unconfigured in this
// env" assumptions rely on — see docs/21_BACKEND_GUIDELINES.md § 11, "never production Firebase
// or the real Surfboard API").
const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';
dotenv.config({ path: path.resolve(process.cwd(), envFile) });

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  CORS_ALLOWED_ORIGINS: z.string().default('*'),

  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),
  FIREBASE_DATABASE_URL: z.string().optional(),
  FIREBASE_STORAGE_BUCKET: z.string().optional(),

  GEMINI_API_KEY: z.string().optional(),
  OCR_PROVIDER_API_KEY: z.string().optional(),

  SURFBOARD_API_KEY: z.string().optional(),
  SURFBOARD_API_SECRET: z.string().optional(),
  SURFBOARD_WEBHOOK_SECRET: z.string().optional(),
  SURFBOARD_ENV: z.enum(['sandbox', 'production']).default('sandbox'),
  SURFBOARD_AUTH_STRATEGY: z.enum(['api_key', 'bearer', 'oauth']).default('api_key'),
  SURFBOARD_BEARER_TOKEN: z.string().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  logger.fatal({ issues: parsed.error.flatten().fieldErrors }, 'Invalid environment configuration');
  process.exit(1);
}

const env = parsed.data;

// Firebase/Gemini/Surfboard projects aren't provisioned yet (see docs/10_TASKS.md Phase 0.3-0.5),
// so these are only hard-required once NODE_ENV=production — enforced here, not on first use.
const PRODUCTION_REQUIRED_KEYS = [
  ENV_KEYS.FIREBASE_PROJECT_ID,
  ENV_KEYS.FIREBASE_CLIENT_EMAIL,
  ENV_KEYS.FIREBASE_PRIVATE_KEY,
  ENV_KEYS.FIREBASE_DATABASE_URL,
  ENV_KEYS.FIREBASE_STORAGE_BUCKET,
  ENV_KEYS.GEMINI_API_KEY,
  ENV_KEYS.SURFBOARD_API_KEY,
  ENV_KEYS.SURFBOARD_API_SECRET,
  ENV_KEYS.SURFBOARD_WEBHOOK_SECRET,
];

const missingKeys = PRODUCTION_REQUIRED_KEYS.filter((key) => !env[key]);

if (missingKeys.length > 0) {
  if (env.NODE_ENV === 'production') {
    logger.fatal({ missingKeys }, 'Missing required production environment variables');
    process.exit(1);
  }
  logger.warn(
    { missingKeys },
    'Running without some external-service credentials — routes depending on them will fail at request time',
  );
}

const config = {
  env: env.NODE_ENV,
  isProduction: env.NODE_ENV === 'production',
  port: env.PORT,
  logLevel: env.LOG_LEVEL,
  corsAllowedOrigins:
    env.CORS_ALLOWED_ORIGINS === '*'
      ? '*'
      : env.CORS_ALLOWED_ORIGINS.split(',').map((origin) => origin.trim()),

  firebase: {
    projectId: env.FIREBASE_PROJECT_ID,
    clientEmail: env.FIREBASE_CLIENT_EMAIL,
    privateKey: env.FIREBASE_PRIVATE_KEY ? env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') : undefined,
    databaseUrl: env.FIREBASE_DATABASE_URL,
    storageBucket: env.FIREBASE_STORAGE_BUCKET,
  },

  gemini: {
    apiKey: env.GEMINI_API_KEY,
  },

  ocr: {
    apiKey: env.OCR_PROVIDER_API_KEY,
  },

  surfboard: {
    apiKey: env.SURFBOARD_API_KEY,
    apiSecret: env.SURFBOARD_API_SECRET,
    webhookSecret: env.SURFBOARD_WEBHOOK_SECRET,
    environment: env.SURFBOARD_ENV,
    authStrategy: env.SURFBOARD_AUTH_STRATEGY,
    bearerToken: env.SURFBOARD_BEARER_TOKEN,
  },
};

module.exports = config;
