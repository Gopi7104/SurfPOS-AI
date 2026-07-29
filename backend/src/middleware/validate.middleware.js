'use strict';

// Request validation middleware factory — every endpoint validates against an explicit zod
// schema before any service/database call, per docs/07_CODING_RULES.md § 10.

const { ValidationError } = require('../utils/errors');

/**
 * @param {import('zod').ZodTypeAny} schema
 * @param {'body' | 'query' | 'params'} [source]
 */
function validate(schema, source = 'body') {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);

    if (!result.success) {
      const details = result.error.issues.map((issue) => ({
        path: issue.path.join('.'),
        message: issue.message,
      }));
      next(new ValidationError('Request validation failed', details));
      return;
    }

    req[source] = result.data;
    next();
  };
}

module.exports = validate;
