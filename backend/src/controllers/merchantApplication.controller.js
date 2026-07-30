'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const { HTTP_STATUS } = require('../constants');
const merchantApplicationService = require('../modules/merchant/merchantApplication.service');

const submitApplication = asyncHandler(async (req, res) => {
  const application = await merchantApplicationService.submitApplication(req.user.uid, req.body);
  sendSuccess(res, { application }, HTTP_STATUS.CREATED);
});

const getApplication = asyncHandler(async (req, res) => {
  const application = await merchantApplicationService.getApplication(req.user.uid, req.params.id);
  sendSuccess(res, { application });
});

const refreshApplicationStatus = asyncHandler(async (req, res) => {
  const application = await merchantApplicationService.refreshApplicationStatus(req.user.uid, req.params.id);
  sendSuccess(res, { application });
});

const listApplications = asyncHandler(async (req, res) => {
  const applications = await merchantApplicationService.listApplications(req.user.uid);
  sendSuccess(res, { applications });
});

module.exports = { submitApplication, getApplication, refreshApplicationStatus, listApplications };
