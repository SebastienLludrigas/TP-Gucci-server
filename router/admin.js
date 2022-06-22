const express = require('express');
const { body } = require('express-validator');

const { getUsersWithAllInfos, createUser } = require('../controllers/admin');
const isAuth = require('../middleware/is-auth')

const router = express.Router();

router.get('/userList', getUsersWithAllInfos);
router.post('/createUser', isAuth, createUser);

module.exports = router;