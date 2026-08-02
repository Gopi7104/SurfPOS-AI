'use strict';

const { Router } = require('express');
const asyncHandler = require('../utils/asyncHandler');
const { receiveSurfboardWebhook } = require('../controllers/webhook.controller');

const router = Router();

// Public — no Firebase auth (Surfboard's own servers call this, never the Flutter app) — request
// authenticity comes entirely from the x-webhook-signature check inside the controller, not from
// this app's normal auth middleware. See docs/04_API_DOCUMENTATION.md § 10.
router.post('/surfboard', asyncHandler(receiveSurfboardWebhook));

module.exports = router;
