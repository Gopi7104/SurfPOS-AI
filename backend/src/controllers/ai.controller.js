'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const aiService = require('../modules/ai/ai.service');

const sendChatMessage = asyncHandler(async (req, res) => {
  const { messages, model } = req.body;
  const reply = await aiService.sendChatMessage(messages, { model, uid: req.user.uid });
  sendSuccess(res, { reply });
});

const getStatus = asyncHandler(async (req, res) => {
  const { activeModel, availableModels, configured } = aiService.getModelInfo();
  sendSuccess(res, { provider: 'OpenRouter', activeModel, availableModels, configured });
});

const testConnection = asyncHandler(async (req, res) => {
  const result = await aiService.testConnection();
  sendSuccess(res, result);
});

module.exports = { sendChatMessage, getStatus, testConnection };
