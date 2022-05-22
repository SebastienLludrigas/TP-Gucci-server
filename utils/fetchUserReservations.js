const Habilite = require('../models/habilite');

const fetchUserReservations = async (idHabilite, res, next) => {
   const reservations = await Habilite.allUserReservations(idHabilite)
   const userReservations = [];

   for (let i = 0; i < reservations.rows.length; i++) {
      try {
         const all = await Habilite.allUserApplicationReservedByIdReservation(reservations.rows[i].id_reservation)

         const intituleReservation = reservations.rows[i].intitule
         const idReservation = reservations.rows[i].id_reservation
         const dateDebutReservation = reservations.rows[i].date_debut
         const dateFinReservation = reservations.rows[i].date_fin
         const commentsReservation = reservations.rows[i].comments
         const allReservedApplications = all.rows
            
         userReservations.push(
            { 
              intituleReservation, 
              idReservation, 
              allReservedApplications,
              dateDebutReservation,
              dateFinReservation,
              commentsReservation
            }
         )
         if (i === reservations.rows.length - 1) {
            res.status(200).json(
               { 
                  infosReservations: userReservations
               }
            );
         }
      } catch (err) {
         if (!err.statusCode) {
            err.statusCode = 500;
         }
         next(err);
      }
   }
};

module.exports = fetchUserReservations;