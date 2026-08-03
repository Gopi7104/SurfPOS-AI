'use strict';

// Resolves the caller's merchantId (docs/21_BACKEND_GUIDELINES.md § 8) before touching
// customerData.repository.js — same cross-module Service pattern as
// modules/inventory/inventory.service.js.

const defaultCustomerDataRepository = require('./customerData.repository');
const defaultMerchantService = require('../merchant/merchant.service');

/**
 * @param {{ customerDataRepository?: object, merchantService?: object }} [deps]
 */
function createCustomerDataService({
  customerDataRepository = defaultCustomerDataRepository,
  merchantService = defaultMerchantService,
} = {}) {
  /** @param {string} uid */
  async function getCustomers(uid) {
    const merchantId = await merchantService.getMerchantId(uid);
    return customerDataRepository.getCustomers(merchantId);
  }

  /**
   * @param {string} uid
   * @param {object[]} customers
   */
  async function setCustomers(uid, customers) {
    const merchantId = await merchantService.getMerchantId(uid);
    return customerDataRepository.setCustomers(merchantId, customers);
  }

  /** @param {string} uid */
  async function getPurchases(uid) {
    const merchantId = await merchantService.getMerchantId(uid);
    return customerDataRepository.getPurchases(merchantId);
  }

  /**
   * @param {string} uid
   * @param {object[]} purchases
   */
  async function setPurchases(uid, purchases) {
    const merchantId = await merchantService.getMerchantId(uid);
    return customerDataRepository.setPurchases(merchantId, purchases);
  }

  return { getCustomers, setCustomers, getPurchases, setPurchases };
}

module.exports = createCustomerDataService();
module.exports.createCustomerDataService = createCustomerDataService;
