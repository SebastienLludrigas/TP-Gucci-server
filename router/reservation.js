const express = require('express');
const { body } = require('express-validator');
const isAuth = require('../middleware/is-auth');

const { 
   postReservation, 
   updateReservation, 
   deleteOneReservedApplication,
   deleteEntireReservation,
   getInfosResas,
   getResasAfterUpdate
} = require('../controllers/reservation');

const router = express.Router();

router.post('/creation', isAuth, postReservation);
router.post('/update/:idResa', isAuth, updateReservation);
router.delete(
   '/deleteOne/:idHabilite/:idResa/:idCouloir/:idPlateforme/:idApplication', isAuth, 
   deleteOneReservedApplication
);
router.delete('/deleteAll/:idHabilite/:idResa', isAuth, deleteEntireReservation)
router.get('/infos', getInfosResas);
router.get('/updatedReservations',isAuth , getResasAfterUpdate);

module.exports = router;
