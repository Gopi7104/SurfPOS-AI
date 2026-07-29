'use strict';

// Request-shape validation for the auth resource — see docs/07_CODING_RULES.md § 10.

const { z } = require('zod');

const signUpSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  displayName: z.string().min(1).max(120).optional(),
});

const loginSchema = z.object({
  idToken: z.string().min(1),
});

module.exports = { signUpSchema, loginSchema };
