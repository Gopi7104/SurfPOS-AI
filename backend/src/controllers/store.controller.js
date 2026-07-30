'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const { HTTP_STATUS } = require('../constants');
const storeService = require('../modules/store/store.service');

const createStore = asyncHandler(async (req, res) => {
  const store = await storeService.createStore(req.user.uid, req.body);
  sendSuccess(res, { store }, HTTP_STATUS.CREATED);
});

const getStore = asyncHandler(async (req, res) => {
  const store = await storeService.getStore(req.user.uid, req.params.storeId);
  sendSuccess(res, { store });
});

const updateStore = asyncHandler(async (req, res) => {
  const store = await storeService.updateStore(req.user.uid, req.params.storeId, req.body);
  sendSuccess(res, { store });
});

const listStores = asyncHandler(async (req, res) => {
  const stores = await storeService.listStores(req.user.uid);
  sendSuccess(res, { stores });
});

module.exports = { createStore, getStore, updateStore, listStores };
