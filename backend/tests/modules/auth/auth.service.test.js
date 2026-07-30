import { describe, it, expect, vi } from 'vitest';
import { createAuthService } from '../../../src/modules/auth/auth.service.js';

function createFakeFirebaseAuth(overrides = {}) {
  return {
    createUser: vi.fn(),
    verifyIdToken: vi.fn(),
    revokeRefreshTokens: vi.fn(),
    ...overrides,
  };
}

function createFakeUsersRepository(overrides = {}) {
  return {
    get: vi.fn(),
    getUidByEmail: vi.fn().mockResolvedValue(null),
    create: vi.fn(),
    update: vi.fn(),
    ...overrides,
  };
}

describe('auth.service', () => {
  describe('signUp', () => {
    it('creates the Firebase user, writes an owner profile, and returns it', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        createUser: vi.fn().mockResolvedValue({ uid: 'uid_1', email: 'owner@example.com' }),
      });
      const usersRepository = createFakeUsersRepository();
      const service = createAuthService({ firebaseAuth, usersRepository });

      const profile = await service.signUp({
        email: 'owner@example.com',
        password: 'supersecret',
        displayName: 'Jane Owner',
      });

      expect(firebaseAuth.createUser).toHaveBeenCalledWith({
        email: 'owner@example.com',
        password: 'supersecret',
        displayName: 'Jane Owner',
      });
      expect(profile).toMatchObject({
        uid: 'uid_1',
        email: 'owner@example.com',
        displayName: 'Jane Owner',
        role: 'owner',
        status: 'active',
      });
      expect(typeof profile.createdAt).toBe('number');
      expect(usersRepository.create).toHaveBeenCalledWith('uid_1', profile);
    });

    it('defaults displayName to null when not provided', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        createUser: vi.fn().mockResolvedValue({ uid: 'uid_2', email: 'no-name@example.com' }),
      });
      const service = createAuthService({ firebaseAuth, usersRepository: createFakeUsersRepository() });

      const profile = await service.signUp({ email: 'no-name@example.com', password: 'supersecret' });

      expect(profile.displayName).toBeNull();
    });

    it('maps auth/email-already-exists to a Conflict error', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        createUser: vi.fn().mockRejectedValue({ code: 'auth/email-already-exists', message: 'taken' }),
      });
      const service = createAuthService({ firebaseAuth, usersRepository: createFakeUsersRepository() });

      await expect(
        service.signUp({ email: 'dup@example.com', password: 'supersecret' }),
      ).rejects.toMatchObject({ name: 'ConflictError', code: 'CONFLICT' });
    });

    it('maps auth/invalid-password to a Validation error', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        createUser: vi
          .fn()
          .mockRejectedValue({ code: 'auth/invalid-password', message: 'Password too weak' }),
      });
      const service = createAuthService({ firebaseAuth, usersRepository: createFakeUsersRepository() });

      await expect(service.signUp({ email: 'weak@example.com', password: '123' })).rejects.toMatchObject({
        name: 'ValidationError',
        code: 'VALIDATION_ERROR',
        message: 'Password too weak',
      });
    });

    it('propagates an unrecognized Firebase error untouched', async () => {
      const boom = new Error('boom');
      const firebaseAuth = createFakeFirebaseAuth({ createUser: vi.fn().mockRejectedValue(boom) });
      const service = createAuthService({ firebaseAuth, usersRepository: createFakeUsersRepository() });

      await expect(service.signUp({ email: 'x@example.com', password: 'supersecret' })).rejects.toBe(boom);
    });
  });

  describe('verifyToken', () => {
    it('returns the decoded token on success', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        verifyIdToken: vi.fn().mockResolvedValue({ uid: 'uid_1' }),
      });
      const service = createAuthService({ firebaseAuth, usersRepository: createFakeUsersRepository() });

      await expect(service.verifyToken('tok')).resolves.toEqual({ uid: 'uid_1' });
    });

    it('throws an Unauthenticated error when the token is invalid', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        verifyIdToken: vi.fn().mockRejectedValue(new Error('bad token')),
      });
      const service = createAuthService({ firebaseAuth, usersRepository: createFakeUsersRepository() });

      await expect(service.verifyToken('bad')).rejects.toMatchObject({ name: 'UnauthenticatedError' });
    });
  });

  describe('login', () => {
    it('verifies the token and returns the matching profile', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        verifyIdToken: vi.fn().mockResolvedValue({ uid: 'uid_1' }),
      });
      const usersRepository = createFakeUsersRepository({
        get: vi.fn().mockResolvedValue({ uid: 'uid_1', role: 'owner' }),
      });
      const service = createAuthService({ firebaseAuth, usersRepository });

      await expect(service.login('tok')).resolves.toEqual({ uid: 'uid_1', role: 'owner' });
      expect(usersRepository.get).toHaveBeenCalledWith('uid_1');
    });

    it('throws NotFoundError for a password sign-in with no provisioned profile', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        verifyIdToken: vi
          .fn()
          .mockResolvedValue({ uid: 'uid_1', firebase: { sign_in_provider: 'password' } }),
      });
      const usersRepository = createFakeUsersRepository({ get: vi.fn().mockResolvedValue(null) });
      const service = createAuthService({ firebaseAuth, usersRepository });

      await expect(service.login('tok')).rejects.toMatchObject({ name: 'NotFoundError' });
      expect(usersRepository.create).not.toHaveBeenCalled();
    });

    it('falls back to the email index when the uid has no profile of its own', async () => {
      // Same person, second provider: Google sign-in for an email that already has a profile
      // under the Email/Password account's uid.
      const firebaseAuth = createFakeFirebaseAuth({
        verifyIdToken: vi.fn().mockResolvedValue({
          uid: 'google_uid',
          email: 'owner@example.com',
          firebase: { sign_in_provider: 'google.com' },
        }),
      });
      const usersRepository = createFakeUsersRepository({
        get: vi
          .fn()
          .mockImplementation((uid) =>
            uid === 'password_uid'
              ? Promise.resolve({ uid: 'password_uid', role: 'owner' })
              : Promise.resolve(null),
          ),
        getUidByEmail: vi.fn().mockResolvedValue('password_uid'),
      });
      const service = createAuthService({ firebaseAuth, usersRepository });

      await expect(service.login('tok')).resolves.toEqual({ uid: 'password_uid', role: 'owner' });
      expect(usersRepository.create).not.toHaveBeenCalled();
    });

    it('auto-provisions a profile for a brand-new federated sign-in', async () => {
      const firebaseAuth = createFakeFirebaseAuth({
        verifyIdToken: vi.fn().mockResolvedValue({
          uid: 'google_uid_new',
          email: 'new-google-user@example.com',
          name: 'New Google User',
          firebase: { sign_in_provider: 'google.com' },
        }),
      });
      const usersRepository = createFakeUsersRepository({ get: vi.fn().mockResolvedValue(null) });
      const service = createAuthService({ firebaseAuth, usersRepository });

      const profile = await service.login('tok');

      expect(profile).toMatchObject({
        uid: 'google_uid_new',
        email: 'new-google-user@example.com',
        displayName: 'New Google User',
        role: 'owner',
        status: 'active',
      });
      expect(usersRepository.create).toHaveBeenCalledWith('google_uid_new', profile);
    });
  });

  describe('getCurrentUser', () => {
    it('returns the profile for a known uid', async () => {
      const usersRepository = createFakeUsersRepository({
        get: vi.fn().mockResolvedValue({ uid: 'uid_1', role: 'owner' }),
      });
      const service = createAuthService({ usersRepository });

      await expect(service.getCurrentUser({ uid: 'uid_1' })).resolves.toEqual({
        uid: 'uid_1',
        role: 'owner',
      });
    });

    it('throws NotFoundError for an unknown uid with no email fallback match', async () => {
      const usersRepository = createFakeUsersRepository({ get: vi.fn().mockResolvedValue(null) });
      const service = createAuthService({ usersRepository });

      await expect(service.getCurrentUser({ uid: 'missing' })).rejects.toMatchObject({
        name: 'NotFoundError',
      });
    });

    it('falls back to the email index when the uid has no profile of its own', async () => {
      const usersRepository = createFakeUsersRepository({
        get: vi
          .fn()
          .mockImplementation((uid) =>
            uid === 'password_uid'
              ? Promise.resolve({ uid: 'password_uid', role: 'owner' })
              : Promise.resolve(null),
          ),
        getUidByEmail: vi.fn().mockResolvedValue('password_uid'),
      });
      const service = createAuthService({ usersRepository });

      await expect(
        service.getCurrentUser({ uid: 'google_uid', email: 'owner@example.com' }),
      ).resolves.toEqual({ uid: 'password_uid', role: 'owner' });
    });
  });

  describe('logout', () => {
    it('revokes refresh tokens for the uid', async () => {
      const firebaseAuth = createFakeFirebaseAuth();
      const service = createAuthService({ firebaseAuth, usersRepository: createFakeUsersRepository() });

      await expect(service.logout('uid_1')).resolves.toEqual({ uid: 'uid_1', loggedOut: true });
      expect(firebaseAuth.revokeRefreshTokens).toHaveBeenCalledWith('uid_1');
    });
  });
});
