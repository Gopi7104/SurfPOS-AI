'use strict';

// Contract every future domain mapper (mappers/merchant.mapper.js, mappers/store.mapper.js, etc.
// — added alongside their respective phase, see docs/22_DEVELOPMENT_ROADMAP.md) implements. See
// docs/21_BACKEND_GUIDELINES.md § 6. No domain mappers exist yet — Phase 2 is SDK infrastructure
// only, no Merchant/Store/Payment business logic (see docs/10_TASKS.md Phase 2 scope).

class BaseMapper {
  /**
   * Translate a raw Surfboard wire-format response into the plain domain shape from
   * docs/20_DOMAIN_MODEL.md.
   * @param {*} _raw
   */
  toDomain(_raw) {
    throw new Error(`${this.constructor.name}.toDomain() must be implemented by a subclass`);
  }

  /**
   * Translate a plain domain object into the wire format Surfboard's API expects for a write.
   * @param {*} _domain
   */
  toWire(_domain) {
    throw new Error(`${this.constructor.name}.toWire() must be implemented by a subclass`);
  }
}

module.exports = BaseMapper;
