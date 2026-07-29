'use strict';

// Fine-grained permission keys, one per feature area in docs/05_FEATURES.md — not yet enforced by
// any middleware (no authorization module exists yet). Defined now so future role→permission
// mapping and `requirePermission()` checks have a single source of truth instead of ad hoc strings.

module.exports = Object.freeze({
  MANAGE_MERCHANT: 'manage_merchant',
  MANAGE_STAFF: 'manage_staff',
  MANAGE_CATALOG: 'manage_catalog',
  MANAGE_INVENTORY: 'manage_inventory',
  PROCESS_SALES: 'process_sales',
  MANAGE_SETTINGS: 'manage_settings',
  VIEW_ANALYTICS: 'view_analytics',
  CONFIRM_INVOICE_SCANS: 'confirm_invoice_scans',
});
