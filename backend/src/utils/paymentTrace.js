'use strict';

// TEMPORARY diagnostic instrumentation for the payment-confirmation-flow investigation — traces
// steps 3/4/9/10/11 of the redirect -> deep-link -> status -> receipt sequence. Writes to a plain
// file (not the pino logger) so it can be tailed independently of whatever terminal owns the
// server process. Remove this file and its call sites once the root cause is confirmed and fixed.

const fs = require('fs');

const TRACE_FILE =
  '/private/tmp/claude-501/-Users-sgopinath-Desktop-SurfPOS-AI/17c813e6-4a3e-48dd-a280-47c0827bc0b1/scratchpad/payment_trace.log';

function paymentTrace(step, event, data = {}) {
  const line = JSON.stringify({ ts: new Date().toISOString(), step, event, ...data });
  try {
    fs.appendFileSync(TRACE_FILE, line + '\n');
  } catch {
    // Diagnostic-only — never let a trace-write failure affect the real request.
  }
}

module.exports = { paymentTrace };
