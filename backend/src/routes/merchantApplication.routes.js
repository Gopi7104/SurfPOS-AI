'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  submitApplicationSchema,
  applicationIdParamsSchema,
} = require('../validators/merchantApplication.validation');
const {
  submitApplication,
  getApplication,
  refreshApplicationStatus,
  listApplications,
} = require('../controllers/merchantApplication.controller');

const router = Router();

// All merchant-application endpoints require an authenticated SurfPOS user — see
// docs/04_API_DOCUMENTATION.md § 2.
router.use(authenticate);

router.post('/', validate(submitApplicationSchema), submitApplication);
router.get('/:id/status', validate(applicationIdParamsSchema, 'params'), refreshApplicationStatus);
router.get('/:id', validate(applicationIdParamsSchema, 'params'), getApplication);
router.get('/', listApplications);

module.exports = router;
