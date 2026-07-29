import { describe, it, expect } from 'vitest';
import merchantMapper from '../../../src/integrations/surfboard/mappers/merchant.mapper.js';

describe('merchantMapper.toWire', () => {
  it('maps the domain application input to Surfboard wire field names', () => {
    const wire = merchantMapper.toWire({
      businessName: 'Blue Wave Surf Shop',
      businessType: 'retail',
      contactEmail: 'owner@example.com',
      contactPhone: '+46700000000',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
    });

    expect(wire).toEqual({
      business_name: 'Blue Wave Surf Shop',
      business_type: 'retail',
      contact_email: 'owner@example.com',
      contact_phone: '+46700000000',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
    });
  });
});

describe('merchantMapper.toDomain', () => {
  it('maps a full Surfboard response to the normalized application shape', () => {
    const domain = merchantMapper.toDomain({
      application_id: 'app_1',
      merchant_id: 'sb_merchant_1',
      status: 'pending_verification',
      onboarding_url: 'https://onboard.surfboardpayments.com/app_1',
    });

    expect(domain).toEqual({
      applicationId: 'app_1',
      merchantId: 'sb_merchant_1',
      applicationStatus: 'pending_verification',
      applicationUrl: 'https://onboard.surfboardpayments.com/app_1',
    });
  });

  it('falls back to merchant_id as the applicationId when application_id is absent', () => {
    const domain = merchantMapper.toDomain({ merchant_id: 'sb_merchant_1', status: 'active' });

    expect(domain.applicationId).toBe('sb_merchant_1');
    expect(domain.merchantId).toBe('sb_merchant_1');
  });

  it('defaults missing fields to null/pending_verification rather than throwing', () => {
    const domain = merchantMapper.toDomain({});

    expect(domain).toEqual({
      applicationId: null,
      merchantId: null,
      applicationStatus: 'pending_verification',
      applicationUrl: null,
    });
  });
});

describe('merchantMapper.toMerchantProfile', () => {
  it('maps a full Surfboard merchant response to the domain Merchant shape', () => {
    const merchant = merchantMapper.toMerchantProfile({
      merchant_id: 'sb_merchant_1',
      business_name: 'Blue Wave Surf Shop',
      business_type: 'retail',
      contact_email: 'owner@example.com',
      contact_phone: '+46700000000',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
      status: 'active',
    });

    expect(merchant).toEqual({
      id: 'sb_merchant_1',
      businessName: 'Blue Wave Surf Shop',
      businessType: 'retail',
      contactEmail: 'owner@example.com',
      contactPhone: '+46700000000',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
      status: 'active',
    });
  });

  it('falls back to onboarding_status and defaults missing fields to null', () => {
    const merchant = merchantMapper.toMerchantProfile({
      id: 'sb_merchant_1',
      onboarding_status: 'pending_verification',
    });

    expect(merchant).toEqual({
      id: 'sb_merchant_1',
      businessName: null,
      businessType: null,
      contactEmail: null,
      contactPhone: null,
      address: null,
      status: 'pending_verification',
    });
  });
});

describe('merchantMapper.toMerchantUpdateWire', () => {
  it('only includes fields that were provided', () => {
    const wire = merchantMapper.toMerchantUpdateWire({ businessName: 'New Name' });

    expect(wire).toEqual({ business_name: 'New Name' });
  });

  it('maps every supported field when all are provided', () => {
    const wire = merchantMapper.toMerchantUpdateWire({
      businessName: 'New Name',
      businessType: 'retail',
      contactEmail: 'new@example.com',
      contactPhone: '+46700000001',
      address: { line1: 'New St 2', city: 'Stockholm', country: 'SE' },
    });

    expect(wire).toEqual({
      business_name: 'New Name',
      business_type: 'retail',
      contact_email: 'new@example.com',
      contact_phone: '+46700000001',
      address: { line1: 'New St 2', city: 'Stockholm', country: 'SE' },
    });
  });

  it('returns an empty object for an empty patch', () => {
    expect(merchantMapper.toMerchantUpdateWire({})).toEqual({});
  });
});
