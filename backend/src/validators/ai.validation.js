'use strict';

// Request-shape validation for SurfAI chat — see docs/07_CODING_RULES.md § 10 and
// docs/16_AI_MODULE.md.

const { z } = require('zod');

const chatMessageSchema = z.object({
  role: z.enum(['user', 'assistant']),
  content: z.string().min(1).max(8000),
});

const sendChatMessageSchema = z.object({
  messages: z.array(chatMessageSchema).min(1).max(50),
  model: z.string().min(1).optional(),
  // Reserved for a future streaming (SSE) response — accepted and validated now so the request
  // shape doesn't change later, but the backend always replies with a single complete message in
  // Phase AI 1 regardless of this flag (see docs/16_AI_MODULE.md "Streaming").
  stream: z.boolean().optional().default(false),
});

module.exports = { sendChatMessageSchema };
