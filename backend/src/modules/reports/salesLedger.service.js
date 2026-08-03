'use strict';

// Resolves the caller's merchantId before touching salesLedger.repository.js — same cross-module
// Service pattern as modules/customers/customerData.service.js.

const defaultSalesLedgerRepository = require('./salesLedger.repository');
const defaultMerchantService = require('../merchant/merchant.service');

/**
 * @param {{ salesLedgerRepository?: object, merchantService?: object }} [deps]
 */
function createSalesLedgerService({
  salesLedgerRepository = defaultSalesLedgerRepository,
  merchantService = defaultMerchantService,
} = {}) {
  /** @param {string} uid */
  async function getSales(uid) {
    const merchantId = await merchantService.getMerchantId(uid);
    return salesLedgerRepository.getSales(merchantId);
  }

  /**
   * @param {string} uid
   * @param {object[]} records
   */
  async function setSales(uid, records) {
    const merchantId = await merchantService.getMerchantId(uid);
    return salesLedgerRepository.setSales(merchantId, records);
  }

  return { getSales, setSales };
}

module.exports = createSalesLedgerService();
module.exports.createSalesLedgerService = createSalesLedgerService;
