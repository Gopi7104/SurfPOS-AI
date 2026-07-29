'use strict';

// Server liveness status — deliberately independent of Firebase/external services, since those
// aren't provisioned yet (see docs/10_TASKS.md Phase 0) and shouldn't gate whether the API process
// itself is considered up.

/**
 * @returns {{ status: 'ok', uptimeSeconds: number, timestamp: string }}
 */
function checkHealth() {
  return {
    status: 'ok',
    uptimeSeconds: Math.round(process.uptime()),
    timestamp: new Date().toISOString(),
  };
}

module.exports = { checkHealth };
