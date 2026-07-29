import { describe, it, expect, vi } from 'vitest';
import { createAuthMiddleware } from '../../src/middleware/auth.middleware.js';

function createReq({ authorization } = {}) {
  return { headers: { authorization }, log: { warn: vi.fn() } };
}

function createRes() {
  return {};
}

describe('auth.middleware', () => {
  it('calls next() and attaches req.user on a valid token', async () => {
    const authService = { verifyToken: vi.fn().mockResolvedValue({ uid: 'uid_1', email: 'a@b.com' }) };
    const { authenticate } = createAuthMiddleware({ authService });
    const req = createReq({ authorization: 'Bearer good-token' });
    const next = vi.fn();

    await authenticate(req, createRes(), next);

    expect(authService.verifyToken).toHaveBeenCalledWith('good-token');
    expect(req.user).toEqual({ uid: 'uid_1', email: 'a@b.com', phoneNumber: null });
    expect(next).toHaveBeenCalledWith();
  });

  it('maps a Firebase phone_number claim onto req.user.phoneNumber', async () => {
    const authService = {
      verifyToken: vi.fn().mockResolvedValue({ uid: 'uid_1', email: null, phone_number: '+46700000000' }),
    };
    const { authenticate } = createAuthMiddleware({ authService });
    const req = createReq({ authorization: 'Bearer good-token' });
    const next = vi.fn();

    await authenticate(req, createRes(), next);

    expect(req.user.phoneNumber).toBe('+46700000000');
  });

  it('calls next(error) with UnauthenticatedError when the Authorization header is missing', async () => {
    const authService = { verifyToken: vi.fn() };
    const { authenticate } = createAuthMiddleware({ authService });
    const req = createReq();
    const next = vi.fn();

    await authenticate(req, createRes(), next);

    expect(authService.verifyToken).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith(expect.objectContaining({ name: 'UnauthenticatedError' }));
  });

  it('calls next(error) with UnauthenticatedError when the header has no Bearer prefix', async () => {
    const authService = { verifyToken: vi.fn() };
    const { authenticate } = createAuthMiddleware({ authService });
    const req = createReq({ authorization: 'good-token' });
    const next = vi.fn();

    await authenticate(req, createRes(), next);

    expect(next).toHaveBeenCalledWith(expect.objectContaining({ name: 'UnauthenticatedError' }));
  });

  it('calls next(error) and logs a warning when token verification fails', async () => {
    const verificationError = new Error('bad token');
    const authService = { verifyToken: vi.fn().mockRejectedValue(verificationError) };
    const { authenticate } = createAuthMiddleware({ authService });
    const req = createReq({ authorization: 'Bearer bad-token' });
    const next = vi.fn();

    await authenticate(req, createRes(), next);

    expect(req.log.warn).toHaveBeenCalledWith({ err: verificationError }, expect.any(String));
    expect(next).toHaveBeenCalledWith(verificationError);
  });
});
