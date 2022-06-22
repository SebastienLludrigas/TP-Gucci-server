const express = require('express');
const { body } = require('express-validator');

const { signup, login, persistLogin } = require('../controllers/auth');
const isAuth = require('../middleware/is-auth')

const router = express.Router();

router.post('/signup', signup);
router.post('/login', login);
router.post('/persistLogin', persistLogin);

module.exports = router;

