'use strict';

// Route path constants — every router mount point in src/app.js should reference one of these
// instead of a literal string, so a path never has to be updated in more than one place.

module.exports = Object.freeze({
  HEALTH: '/health',
  AUTH: '/auth',
  MERCHANT_APPLICATIONS: '/merchant/applications',
  MERCHANT: '/merchant',
  STORES: '/stores',
  INVENTORY: '/inventory',
  PAYMENTS: '/payments',
  PAYMENT_REDIRECT: '/payments/redirect',
  WEBHOOKS: '/webhooks',
});
