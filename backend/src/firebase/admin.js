'use strict';

// Firebase Admin SDK bootstrap — the only place `admin.initializeApp` is called.
// Every module needing Auth/RTDB/Storage requires this file, never `firebase-admin` directly,
// so credential wiring stays in one place — see docs/07_CODING_RULES.md § 16.
//
// Initialization is lazy: requiring this module must not crash server boot — only actually
// calling getAuth()/getDb()/getStorageBucket() without credentials configured throws, surfaced by
// error.middleware.js as a normal 500 rather than a process crash. The three services validate
// independently: Auth only needs the service-account identity (projectId/clientEmail/privateKey),
// while RTDB/Storage each additionally need their own URL/bucket — so Auth can work before RTDB
// or Storage are fully provisioned, and a missing one gives a specific, actionable error instead
// of a generic "not configured".

const admin = require('firebase-admin');
const { getAuth: getAdminAuth } = require('firebase-admin/auth');
const { getDatabase } = require('firebase-admin/database');
const { getStorage } = require('firebase-admin/storage');
const config = require('../config');
const { logger } = require('../utils/logger');

let app = null;

function hasIdentity() {
  const { projectId, clientEmail, privateKey } = config.firebase;
  return Boolean(projectId && clientEmail && privateKey);
}

// Kept for backward compatibility / a quick "is Firebase set up at all" check — full readiness
// per service is `hasIdentity()` + that service's own URL/bucket, checked in get{Auth,Db,StorageBucket}().
function isConfigured() {
  const { databaseUrl, storageBucket } = config.firebase;
  return hasIdentity() && Boolean(databaseUrl) && Boolean(storageBucket);
}

function getApp() {
  if (app) {
    return app;
  }

  if (!hasIdentity()) {
    throw new Error(
      'Firebase Admin SDK is not configured — set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, ' +
        'and FIREBASE_PRIVATE_KEY (see backend/.env.example).',
    );
  }

  app = admin.initializeApp({
    // firebase-admin v13+ moved cert() to a top-level export — admin.credential.cert() (the
    // pre-v13 shape) no longer exists and silently threw "Cannot read properties of undefined
    // (reading 'cert')" the moment this ever ran against real credentials.
    credential: admin.cert({
      projectId: config.firebase.projectId,
      clientEmail: config.firebase.clientEmail,
      privateKey: config.firebase.privateKey,
    }),
    ...(config.firebase.databaseUrl ? { databaseURL: config.firebase.databaseUrl } : {}),
    ...(config.firebase.storageBucket ? { storageBucket: config.firebase.storageBucket } : {}),
  });

  logger.info('Firebase Admin SDK initialized');
  return app;
}

function getAuth() {
  // firebase-admin v13+ modular API: app.auth() (the pre-v13 namespaced shape) no longer exists —
  // getAuth(app) from 'firebase-admin/auth' is the replacement.
  return getAdminAuth(getApp());
}

function getDb() {
  if (!config.firebase.databaseUrl) {
    throw new Error(
      'Firebase Realtime Database is not configured — set FIREBASE_DATABASE_URL (see backend/.env.example).',
    );
  }
  return getDatabase(getApp());
}

function getStorageBucket() {
  if (!config.firebase.storageBucket) {
    throw new Error(
      'Firebase Storage is not configured — set FIREBASE_STORAGE_BUCKET (see backend/.env.example).',
    );
  }
  return getStorage(getApp()).bucket();
}

module.exports = { isConfigured, hasIdentity, getAuth, getDb, getStorageBucket };
