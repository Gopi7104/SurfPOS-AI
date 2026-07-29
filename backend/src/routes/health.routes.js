'use strict';

const { Router } = require('express');
const { getHealth } = require('../controllers/health.controller');

const router = Router();

// Public — no auth — see docs/04_API_DOCUMENTATION.md § Health & Infra.
router.get('/', getHealth);

module.exports = router;
