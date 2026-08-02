'use strict';

// Real, read-only SurfAI tool functions for store/merchant info (via merchant.service.js and
// store.service.js — never their Repositories/Surfboard clients directly, per the cross-module
// rule, docs/21_BACKEND_GUIDELINES.md § 8), plus honest "not available" replies for concepts the
// backend has no record of at all: app version, theme, and printer status are Flutter/Bluetooth
// device state — nothing server-side ever tracks them (confirmed: no field for any of these
// exists in any backend module). These stubs exist so intentDetector.js can still route a
// merchant's question here instead of ever fabricating an answer.

const defaultMerchantService = require('../../merchant/merchant.service');
const defaultStoreService = require('../../store/store.service');

function createSettingsTool({
  merchantService = defaultMerchantService,
  storeService = defaultStoreService,
} = {}) {
  async function store(uid) {
    const storeId = await storeService.getPrimaryStoreId(uid);
    if (!storeId) {
      return { available: true, message: "You don't have a store set up yet." };
    }
    const details = await storeService.getStore(uid, storeId);
    const status = details.status ? ` (status: ${details.status})` : '';
    return { available: true, message: `Your store is **${details.name ?? 'Unnamed store'}**${status}.` };
  }

  async function merchantName(uid) {
    const merchant = await merchantService.getMerchantDetails(uid);
    if (!merchant?.name) {
      return { available: true, message: "I couldn't find a merchant name on file." };
    }
    return { available: true, message: `Your merchant account is registered as **${merchant.name}**.` };
  }

  async function appVersion() {
    return {
      available: false,
      message: "I don't have access to the app version from here — check Settings → About in the app.",
    };
  }

  async function theme() {
    return {
      available: false,
      message: 'Theme is a device setting, not something I can check — see Settings → Appearance in the app.',
    };
  }

  async function printerStatus() {
    return {
      available: false,
      message:
        "I can't check the printer's connection from here — see the printer status in Settings or the Receipt screen.",
    };
  }

  return { store, merchantName, appVersion, theme, printerStatus };
}

module.exports = createSettingsTool();
module.exports.createSettingsTool = createSettingsTool;
