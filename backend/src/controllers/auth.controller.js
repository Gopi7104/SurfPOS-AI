'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const { HTTP_STATUS } = require('../constants');
const authService = require('../modules/auth/auth.service');

const signUp = asyncHandler(async (req, res) => {
  const profile = await authService.signUp(req.body);
  sendSuccess(res, { user: profile }, HTTP_STATUS.CREATED);
});

const login = asyncHandler(async (req, res) => {
  const profile = await authService.login(req.body.idToken);
  sendSuccess(res, { user: profile });
});

const getMe = asyncHandler(async (req, res) => {
  const profile = await authService.getCurrentUser(req.user.uid);
  sendSuccess(res, { user: profile, role: profile.role });
});

const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.user.uid);
  sendSuccess(res, { loggedOut: true });
});

module.exports = { signUp, login, getMe, logout };
