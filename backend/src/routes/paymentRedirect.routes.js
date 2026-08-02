'use strict';

const { Router } = require('express');
const { redirectSuccess, redirectFailed } = require('../controllers/paymentRedirect.controller');

const router = Router();

// Public — hit directly by the customer's browser (inside Android Custom Tabs) after Surfboard's
// hosted Payment Page completes, never by the Flutter app itself. No Firebase auth applies here,
// same as /health and /webhooks/surfboard — see docs/04_API_DOCUMENTATION.md § 1.
router.get('/success', redirectSuccess);
router.get('/failed', redirectFailed);

module.exports = router;
