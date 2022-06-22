const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Habilite = require('../models/habilite');

exports.signup = (req, res, next) => {

};

exports.login = async (req, res, next) => {
   const email = req.body.email;
   const password = req.body.password;
   let loadedUser;
   let token;

   try {
      const find = await Habilite.findByEmail(email)
      if (find.rowCount === 0) {
         const error = new Error('Email invalide');
         error.statusCode = 401;
         throw error;
      }
      loadedUser = find.rows[0];
      // console.log(result);
            
      const isEqual = await bcrypt.compare(password, find.rows[0].password);
      if (!isEqual) {
         const error = new Error('Mot de passe invalide');
         error.statusCode = 401;
         throw error;
      }
      
      const reservations = await Habilite.allUserReservations(loadedUser.id_habilite)
      const userReservations = [];
      const nbRows = reservations.rowCount
      let counter = 0;

      console.log(nbRows)
      if (nbRows > 0) {
         console.log('it goes through there')
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
                     commentsReservation,
                     show: false
                  }
               )
               counter++
               if (i === reservations.rows.length - 1) {
                  console.log(counter)
                  token = jwt.sign(
                     {
                        email: loadedUser.email,
                        userId: loadedUser.id_habilite.toString()
                     },
                     'laclésupersecrèteetdoncintrouvabledeGucci',
                     { expiresIn: '1h' }
                  );
                  res.status(200).json(
                     { 
                        token: token, 
                        loadedUser: loadedUser,
                        userId: loadedUser.id_habilite.toString(),
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
      } else {
         try {
            token = jwt.sign(
               {
                  email: loadedUser.email,
                  userId: loadedUser.id_habilite.toString()
               },
               'laclésupersecrèteetdoncintrouvabledeGucci',
               { expiresIn: '1h' }
            );
            res.status(200).json(
               { 
                  token: token, 
                  loadedUser: loadedUser,
                  infosReservations: null,
                  userId: loadedUser.id_habilite.toString()
               }
            );
         } catch(err) {
            if (!err.statusCode) {
               err.statusCode = 500;
            }
            next(err);
         }
      }


   } catch (err) {
      if (!err.statusCode) {
         err.statusCode = 500;
      }
      next(err);
   }
}

exports.persistLogin = async (req, res, next) => {
   const token = req.body.token

   let decodedToken;
   try {
     decodedToken = jwt.verify(token, 'laclésupersecrèteetdoncintrouvabledeGucci');
   } catch (err) {
      if (!err.statusCode) {
         err.statusCode = 500;
      }
      next(err);
   }

   const id = decodedToken.userId

   console.log(id, decodedToken)

   try {
      const find = await Habilite.findById(id)
      if (find.rowCount === 0) {
         const error = new Error('Email invalide');
         error.statusCode = 401;
         next(error);
         // throw error;
      }
      loadedUser = find.rows[0];

      const reservations = await Habilite.allUserReservations(id)
      const userReservations = [];
      const nbRows = reservations.rowCount
      // let counter = 0;

      if (nbRows > 0) {
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
                     commentsReservation,
                     show: false 
                  }
               )
               if (i === reservations.rows.length - 1) {
                  res.status(200).json(
                     {  
                        loadedUser,
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
      } else {
         try {
            res.status(200).json(
               { 
                  loadedUser: loadedUser,
                  infosReservations: null
               }
            );
         } catch(err) {
            if (!err.statusCode) {
               err.statusCode = 500;
            }
            next(err);
         }
      }

   } catch (err) {
      if (!err.statusCode) {
         err.statusCode = 500;
      }
      next(err);
   }   
}