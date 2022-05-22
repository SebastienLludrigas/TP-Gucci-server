const express = require('express');
const { body } = require('express-validator');

const { getCouloirs, getPlatforms, getApplications, getAppPlCo } = require('../controllers/main');

const router = express.Router();

router.get('/couloirs', getCouloirs);
router.get('/platforms', getPlatforms);
router.get('/applications', getApplications);
router.get('/applications_platforms_couloirs', getAppPlCo);

module.exports = router;

