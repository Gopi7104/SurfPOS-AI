'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const { sendChatMessageSchema } = require('../validators/ai.validation');
const { sendChatMessage, getStatus, testConnection } = require('../controllers/ai.controller');

const router = Router();

// SurfAI is only reachable by an authenticated SurfPOS user — see docs/16_AI_MODULE.md.
router.use(authenticate);

router.post('/chat', validate(sendChatMessageSchema), sendChatMessage);
router.get('/status', getStatus);
router.post('/status/test', testConnection);

module.exports = router;
