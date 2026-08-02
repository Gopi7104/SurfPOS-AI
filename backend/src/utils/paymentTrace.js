'use strict';

// TEMPORARY diagnostic instrumentation for the payment-confirmation-flow investigation — traces
// steps 3/4/9/10/11 of the redirect -> deep-link -> status -> receipt sequence. Writes to a plain
// file (not the pino logger) so it can be tailed independently of whatever terminal owns the
// server process. Remove this file and its call sites once the root cause is confirmed and fixed.

const fs = require('fs');

const TRACE_FILE =
  '/private/tmp/claude-501/-Users-sgopinath-Desktop-SurfPOS-AI/b1d5544d-fd6c-4056-b89e-642c1f4bf78b/scratchpad/payment_trace.log';

function paymentTrace(step, event, data = {}) {
  const line = JSON.stringify({ ts: new Date().toISOString(), step, event, ...data });
  try {
    fs.appendFileSync(TRACE_FILE, line + '\n');
  } catch {
    // Diagnostic-only — never let a trace-write failure affect the real request.
  }
}

module.exports = { paymentTrace };
