'use strict';

// Firebase Admin SDK bootstrap — the only place `admin.initializeApp` is called.
// Every module needing Auth/RTDB/Storage requires this file, never `firebase-admin` directly,
// so credential wiring stays in one place — see docs/07_CODING_RULES.md § 16.
//
// Initialization is lazy: the Firebase project isn't provisioned yet (docs/10_TASKS.md 0.3), so
// requiring this module must not crash server boot — only actually calling getAuth()/getDb()/
// getStorageBucket() without credentials configured throws, surfaced by error.middleware.js as a
// normal 500 rather than a process crash.

const admin = require('firebase-admin');
const config = require('../config');
const { logger } = require('../utils/logger');

let app = null;

function isConfigured() {
  const { projectId, clientEmail, privateKey, databaseUrl } = config.firebase;
  return Boolean(projectId && clientEmail && privateKey && databaseUrl);
}

function getApp() {
  if (app) {
    return app;
  }

  if (!isConfigured()) {
    throw new Error(
      'Firebase Admin SDK is not configured — set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, ' +
        'FIREBASE_PRIVATE_KEY, and FIREBASE_DATABASE_URL (see backend/.env.example).',
    );
  }

  app = admin.initializeApp({
    credential: admin.credential.cert({
      projectId: config.firebase.projectId,
      clientEmail: config.firebase.clientEmail,
      privateKey: config.firebase.privateKey,
    }),
    databaseURL: config.firebase.databaseUrl,
  });

  logger.info('Firebase Admin SDK initialized');
  return app;
}

function getAuth() {
  return getApp().auth();
}

function getDb() {
  return getApp().database();
}

function getStorageBucket() {
  return getApp().storage().bucket();
}

module.exports = { isConfigured, getAuth, getDb, getStorageBucket };
