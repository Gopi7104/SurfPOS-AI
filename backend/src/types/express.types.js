'use strict';

// JSDoc-only type definitions — see src/types/README.md. No runtime exports.
// Augments Express's Request with the fields our middleware attaches, so a controller can
// JSDoc-annotate its parameter as `AppRequest` instead of the bare Express type.

/**
 * @typedef {import('express').Request & {
 *   id: string,
 *   log: import('pino').Logger,
 *   user?: import('./user.types').AuthenticatedUser,
 * }} AppRequest
 */

module.exports = {};
