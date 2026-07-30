'use strict';

// Server bootstrap — binds app.js to a port and handles graceful shutdown.
// See docs/07_CODING_RULES.md § 15.

const app = require('./app');
const config = require('./config');
const { logger } = require('./utils/logger');

const server = app.listen(config.port, config.host, () => {
  logger.info({ port: config.port, host: config.host, env: config.env }, 'SurfPOS AI backend listening');
});

function shutdown(signal) {
  logger.info({ signal }, 'Shutting down gracefully');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

module.exports = server;
