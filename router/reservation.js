const express = require('express');
const { body } = require('express-validator');
const isAuth = require('../middleware/is-auth');

const reservationController = require('../controllers/reservation');

const router = express.Router();

router.post('/creation', isAuth, reservationController.postReservation);
router.post('/update/:idResa', isAuth, reservationController.updateReservation);
router.delete(
   '/deleteOne/:idHabilite/:idResa/:idCouloir/:idPlateforme/:idApplication', isAuth, 
   reservationController.deleteOneReservedApplication
);
router.delete('/deleteAll/:idHabilite/:idResa', isAuth, reservationController.deleteEntireReservation)
router.get('/infos', reservationController.getInfosResas);

module.exports = router;
