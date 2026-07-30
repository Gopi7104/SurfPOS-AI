import { describe, it, expect } from 'vitest';
import merchantMapper from '../../../src/integrations/surfboard/mappers/merchant.mapper.js';

const domainInput = {
  country: 'SE',
  organisation: {
    corporateId: '5591631360',
    legalName: 'Year Zero Press AB',
    mccCode: '5192',
    address: {
      careOf: 'John Doe',
      addressLine1: 'Main Street 123',
      addressLine2: 'Building C',
      city: 'Stockholm',
      countryCode: 'SE',
      postalCode: '123 45',
    },
    phoneNumber: { code: '46', number: '701234567' },
    email: 'contact@test.com',
  },
  store: {
    name: 'Main Street Store',
    email: 'store@example.com',
    phoneNumber: { code: '46', number: '701234567' },
    address: { addressLine1: 'Main Street 123', city: 'Stockholm', countryCode: 'SE', postalCode: '123 45' },
  },
};

describe('merchantMapper.toWire', () => {
  it('maps the full domain input to the confirmed Surfboard Create Merchant body', () => {
    expect(merchantMapper.toWire(domainInput)).toEqual({
      country: 'SE',
      organisation: {
        corporateId: '5591631360',
        legalName: 'Year Zero Press AB',
        mccCode: '5192',
        address: {
          careOf: 'John Doe',
          addressLine1: 'Main Street 123',
          addressLine2: 'Building C',
          city: 'Stockholm',
          countryCode: 'SE',
          postalCode: '123 45',
        },
        phoneNumber: { code: '46', number: '701234567' },
        email: 'contact@test.com',
      },
      controlFields: {
        generateShortLink: true,
        store: {
          name: 'Main Street Store',
          email: 'store@example.com',
          phoneNumber: { code: '46', number: '701234567' },
          address: {
            addressLine1: 'Main Street 123',
            city: 'Stockholm',
            countryCode: 'SE',
            postalCode: '123 45',
          },
        },
      },
    });
  });

  it('omits optional organisation/address fields entirely when not provided', () => {
    const minimal = {
      country: 'SE',
      organisation: {
        corporateId: '1234567812',
        address: {
          addressLine1: 'Main Street 123',
          city: 'Stockholm',
          countryCode: 'SE',
          postalCode: '123 45',
        },
      },
      store: domainInput.store,
    };

    const wire = merchantMapper.toWire(minimal);

    expect(wire.organisation).toEqual({
      corporateId: '1234567812',
      address: {
        addressLine1: 'Main Street 123',
        city: 'Stockholm',
        countryCode: 'SE',
        postalCode: '123 45',
      },
    });
    expect(wire.organisation.legalName).toBeUndefined();
    expect(wire.organisation.mccCode).toBeUndefined();
    expect(wire.organisation.phoneNumber).toBeUndefined();
    expect(wire.organisation.email).toBeUndefined();
  });
});

describe('merchantMapper.toDomain', () => {
  it('maps the confirmed Create Merchant success response (envelope-wrapped)', () => {
    const domain = merchantMapper.toDomain({
      status: 'SUCCESS',
      data: {
        applicationId: '8268abfc4ae6900a10',
        webKybUrl: 'https://surfkyb.com/8268abfc4ae6900a10',
      },
      message: 'Merchant application created successfully.',
    });

    expect(domain).toEqual({
      applicationId: '8268abfc4ae6900a10',
      merchantId: null,
      storeId: null,
      applicationStatus: 'APPLICATION_INITIATED',
      applicationUrl: 'https://surfkyb.com/8268abfc4ae6900a10',
      shortLinkUrl: null,
    });
  });

  it('captures merchantId/storeId/shortLinkUrl when a PF partner gets them immediately', () => {
    const domain = merchantMapper.toDomain({
      status: 'SUCCESS',
      data: {
        applicationId: 'app_1',
        webKybUrl: 'https://surfkyb.com/app_1',
        merchantId: 'm-1',
        storeId: 's-1',
        shortLinkUrl: 'https://surfkyb.com/s/abc',
      },
      message: 'ok',
    });

    expect(domain).toMatchObject({
      merchantId: 'm-1',
      storeId: 's-1',
      shortLinkUrl: 'https://surfkyb.com/s/abc',
    });
  });

  it('defaults missing fields to null rather than throwing', () => {
    expect(merchantMapper.toDomain({})).toEqual({
      applicationId: null,
      merchantId: null,
      storeId: null,
      applicationStatus: 'APPLICATION_INITIATED',
      applicationUrl: null,
      shortLinkUrl: null,
    });
  });
});

describe('merchantMapper.toApplicationStatusDomain', () => {
  it('maps the confirmed Check Application Status success response', () => {
    const domain = merchantMapper.toApplicationStatusDomain({
      status: 'SUCCESS',
      data: {
        applicationId: '81409507c1a5f00110',
        webKybUrl: 'http://partner.surfboardpayments.com/81409507c1a5f00110',
        applicationStatus: 'MERCHANT_CREATED',
        merchantId: '81412e2e4102f80f0e',
        storeId: '81412e3c3b1090060f',
        onlineOnboardingStatus: 'PENDING_VERIFICATION',
      },
      message: 'Application status fetched successfully',
    });

    expect(domain).toEqual({
      applicationId: '81409507c1a5f00110',
      applicationStatus: 'MERCHANT_CREATED',
      merchantId: '81412e2e4102f80f0e',
      storeId: '81412e3c3b1090060f',
      applicationUrl: 'http://partner.surfboardpayments.com/81409507c1a5f00110',
      onlineOnboardingStatus: 'PENDING_VERIFICATION',
    });
  });

  it('defaults missing fields to null', () => {
    expect(merchantMapper.toApplicationStatusDomain({})).toEqual({
      applicationId: null,
      applicationStatus: null,
      merchantId: null,
      storeId: null,
      applicationUrl: null,
      onlineOnboardingStatus: null,
    });
  });
});

describe('merchantMapper.toMerchantProfile', () => {
  it('maps the confirmed flat Fetch Merchant Details response', () => {
    const merchant = merchantMapper.toMerchantProfile({
      status: 'SUCCESS',
      data: {
        merchantId: '81fa6b2d8d5dc8040e',
        merchantName: 'Conroy Hane and Parker',
        email: 'ashinisb@surfboard.se',
        companyId: '5590520507',
        countryCode: 'SE',
        mccCode: 1520,
        phoneNumber: '917676576569',
        merchantLogoUrl: 'https://example.com/logo.png',
        address: { addressLine1: 'Stockholm', city: 'Sweden', countryCode: 'SE', postalCode: '22331' },
      },
      message: 'Successfully fetched merchant details',
    });

    expect(merchant).toEqual({
      id: '81fa6b2d8d5dc8040e',
      name: 'Conroy Hane and Parker',
      companyId: '5590520507',
      email: 'ashinisb@surfboard.se',
      phoneNumber: '917676576569',
      logoUrl: 'https://example.com/logo.png',
      mccCode: '1520',
      countryCode: 'SE',
      address: { addressLine1: 'Stockholm', city: 'Sweden', countryCode: 'SE', postalCode: '22331' },
    });
  });

  it('defaults missing fields to null', () => {
    expect(merchantMapper.toMerchantProfile({})).toEqual({
      id: null,
      name: null,
      companyId: null,
      email: null,
      phoneNumber: null,
      logoUrl: null,
      mccCode: null,
      countryCode: null,
      address: null,
    });
  });
});

describe('merchantMapper.toMerchantUpdateWire', () => {
  it('only includes fields that were provided, using Surfboard field names', () => {
    expect(merchantMapper.toMerchantUpdateWire({ email: 'new@example.com' })).toEqual({
      email: 'new@example.com',
    });
  });

  it('maps every supported field when all are provided', () => {
    const wire = merchantMapper.toMerchantUpdateWire({
      email: 'new@example.com',
      logoUrl: 'https://example.com/logo.png',
      phoneNumber: { code: '46', number: '701234567' },
    });

    expect(wire).toEqual({
      email: 'new@example.com',
      merchantLogoUrl: 'https://example.com/logo.png',
      phoneNumber: { code: '46', number: '701234567' },
    });
  });

  it('returns an empty object for an empty patch', () => {
    expect(merchantMapper.toMerchantUpdateWire({})).toEqual({});
  });
});
