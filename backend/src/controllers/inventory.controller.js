'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const { HTTP_STATUS } = require('../constants');
const inventoryService = require('../modules/inventory/inventory.service');

const createProduct = asyncHandler(async (req, res) => {
  const product = await inventoryService.createProduct(req.user.uid, req.body);
  sendSuccess(res, { product }, HTTP_STATUS.CREATED);
});

const getProduct = asyncHandler(async (req, res) => {
  const product = await inventoryService.getProduct(req.user.uid, req.params.productId);
  sendSuccess(res, { product });
});

const updateProduct = asyncHandler(async (req, res) => {
  const product = await inventoryService.updateProduct(req.user.uid, req.params.productId, req.body);
  sendSuccess(res, { product });
});

const deleteProduct = asyncHandler(async (req, res) => {
  const product = await inventoryService.softDeleteProduct(req.user.uid, req.params.productId);
  sendSuccess(res, { product });
});

const listProducts = asyncHandler(async (req, res) => {
  const { items, nextCursor } = await inventoryService.listProducts(req.user.uid, req.query);
  sendSuccess(res, { products: items, nextCursor });
});

const adjustStock = asyncHandler(async (req, res) => {
  const stock = await inventoryService.adjustStock(req.user.uid, req.params.productId, req.body);
  sendSuccess(res, { stock });
});

module.exports = { createProduct, getProduct, updateProduct, deleteProduct, listProducts, adjustStock };
