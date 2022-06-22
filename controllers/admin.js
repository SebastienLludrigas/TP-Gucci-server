const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const Habilite = require('../models/habilite');
const Reservation = require('../models/reservation');

exports.getUsersWithAllInfos = async (req, res, next) => {
  try {
    const users = await Habilite.fetchAll();
    const allUsersInfos = [];
    // console.log(users.rowCount)

    for (let i = 0; i < users.rows.length; i++) {
      const reservations = await Habilite.allUserReservations(users.rows[i].id_habilite)
      const userInfos = users.rows[i];
      const nbRows = reservations.rowCount
      let userReservations = [];
      // console.log(reservations.rowCount)
      // console.log(reservations.rows.length)
      // let counter = 0;

      if (nbRows > 0) {
        for (let i = 0; i < nbRows; i++) {
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
            );
          } catch (err) {
            if (!err.statusCode) {
              err.statusCode = 500;
            }
            next(err);
          };
        };

        userInfos.reservations = userReservations;
        allUsersInfos.push(userInfos);
      } else {
        userInfos.reservations = null;
        allUsersInfos.push(userInfos);
      };
    };

    res.status(200).json({
      message: 'fetched allUsersInfos succesfully',
      allUsersInfos
    });      
  } catch (err) {
    console.log(err)
  }
};

exports.getReservations = async (req, res, next) => {
  try {
    const reservations = await Reservation.fetchAll();
    res.status(200).json({
      message: 'fetched reservations succesfully',
      reservations: reservations.rows
    })   
  } catch (err) {
    if (!err.statusCode) {
      err.statusCode = 500;
    }
    next(err);
  }
};

exports.createUser = async (req, res, next) => {        
  try {
    const { nom, fonction, telephone, email, role, status } = req.body;

    const admin = await Habilite.findById(req.userId)
    if (admin.rows[0].role !== 'admin') {
      const error = new Error('Unauthorized');
      error.statusCode = 401;
      throw error;
    }

    const verifUser = await Habilite.findByEmail(email);
    if (verifUser.rows[0]) {
      const error = new Error(`! L'utilisateur ${nom} existe déjà dans la base de données`);
      error.statusCode = 409;
      throw error;
    }
  
    let password = req.body.password
    password = await bcrypt.hash(password, 12);
    
    const user = new Habilite(
      null, nom, fonction, telephone, email, password, role, status 
    );

    console.log(user)
    
    const result = await user.createUser()

    console.log(result.rows)

    res.status(201).json({
      message: `User ${nom} successfully created`,
      newUser: result.rows
    });

  } catch (err) {
    if (!err.statusCode) {
      err.statusCode = 500;
    }
    next(err);
  }
};