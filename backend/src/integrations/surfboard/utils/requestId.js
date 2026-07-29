'use strict';

// Every outgoing Surfboard call gets its own ID — carried through request/response logging and
// attached to any SurfboardApiError thrown, so a single Surfboard call is traceable end to end
// independent of the inbound Express requestId (see docs/21_BACKEND_GUIDELINES.md § 10).

const { randomUUID } = require('crypto');

function generateRequestId() {
  return `sb_req_${randomUUID()}`;
}

module.exports = { generateRequestId };
