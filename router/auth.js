const express = require('express');
const { body } = require('express-validator');

const authController = require('../controllers/auth');
const isAuth = require('../middleware/is-auth')

const router = express.Router();

router.post('/signup', authController.signup);
router.post('/login', authController.login);
router.post('/persistLogin', authController.persistLogin);

module.exports = router;

