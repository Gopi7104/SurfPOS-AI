'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const { signUpSchema, loginSchema } = require('../validators/auth.validation');
const { signUp, login, getMe, logout } = require('../controllers/auth.controller');

const router = Router();

// Public — see docs/04_API_DOCUMENTATION.md § 2.
router.post('/signup', validate(signUpSchema), signUp);
router.post('/login', validate(loginSchema), login);

// Protected
router.get('/me', authenticate, getMe);
router.post('/logout', authenticate, logout);

module.exports = router;
