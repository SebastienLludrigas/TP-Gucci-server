const Reservation = require('../models/reservation');
const Couloir_plateforme_application_reservation = require('../models/couloir_plateforme_application_reservation');
const Habilite = require('../models/habilite');
const fetchUserReservations = require('../utils/fetchUserReservations');

exports.postReservation = (req, res, next) => {
  // Déclaration dans le scope global de la fonction afin
  // qu'elles soient disponible dans toutes les réponses des promesses
  const id_habilite = req.body.id_habilite;
  const intitule = req.body.intitule;
    
  Habilite.findById(id_habilite)
  .then((habilite) => {
    const name = habilite.rows[0].nom;
    const fonction = habilite.rows[0].fonction;
    const email = habilite.rows[0].email;
    const telephone = habilite.rows[0].telephone;
    const comments = req.body.comments
    const date_debut = req.body.date_debut;
    const date_fin = req.body.date_fin;
    const reservation = new Reservation(
      null, intitule, comments, name, fonction, email, telephone, id_habilite, date_debut, date_fin
    )
    // Insertion dans la table réservation
    return reservation.save()
  })
  .then((result) => {
    // On boucle sur la propiété selection qui contient toutes les informations de chaque
    // association couloir_plateforme_application réservée
    // console.log(req.body.selection)

    const id_reservation = result.rows[0].id_reservation

    req.body.selection.forEach((item, index) => {
      const id_couloir = item.id_couloir;
      const id_plateforme = item.id_plateforme;
      const id_application = item.id;
      
      const cpar = new Couloir_plateforme_application_reservation(
        id_couloir, id_plateforme, id_application, id_reservation, true, true
      );

      // Insertion dans la table couloir_plateforme_application_reservation
      cpar
        .saveReservation()
        .then(() => {
          // Si c'est le dernier tour de boucle on envoi le message de succés 
          // au client (condition nécessaire afin de ne pas envoyer plusieurs fois
          // un message au client ce qui créerait une erreur du type : 
          // Error [ERR_HTTP_HEADERS_SENT]: Cannot set headers after they are sent to the client)
          if (index === req.body.selection.length - 1) {
            res.status(201).json({
              message: 'Reservation created successfully with id_reservation : ' + id_reservation + ' and intitule : ' + intitule
            });
          }
        })
        .catch(err => {
          if (!err.statusCode) {
            err.statusCode = 500;
          }
          next(err);
        });
    })
  })
  .catch(err => {
    if (!err.statusCode) {
      err.statusCode = 500;
    }
    next(err);
  });
}

exports.getInfosResas = (req, res, next) => {
  Reservation.infosResas()
    .then((result) => {
      res
        .status(200)
        .json({ 
          message: 'fetched reservation infos succesfully',
          totalItems: result.rowCount, 
          infosResas: result.rows
        });
      // console.log(result.rows);
    })
    .catch(err => {
      // Ici c'est toujours le même message d'erreur au middleware de gestion des erreurs dans app.js 
      if (!err.statusCode) {
        err.statusCode = 500;
      }
      next(err);
    });
}

exports.updateReservation = async (req, res, next) => {
  const id_reservation = req.params.idResa

  try {
    const reservationFound = await Reservation.findById(id_reservation)
    
    if (reservationFound.rowCount === 0) {
      const error = new Error('Could not find reservation...');
      error.statusCode = 404;
      throw error;
    }

    // Récupération des informations générales de la réservation.
    // En fonction des informations qui ont été modifiés on récupèrera soit
    // les informations de l'ancienne réservation soit celle de la nouvelle 
    const intitule = req.body.intitule ? req.body.intitule : reservationFound.rows[0].intitule;
    const comments = req.body.comments ? req.body.comments : reservationFound.rows[0].comments;
    const name = reservationFound.rows[0].name;
    const fonction = reservationFound.rows[0].fonction;
    const email = reservationFound.rows[0].email;
    const telephone = reservationFound.rows[0].telephone;
    const id_habilite = reservationFound.rows[0].id_habilite;
    const date_debut = req.body.dateDebut ? req.body.dateDebut : reservationFound.rows[0].date_debut;
    const date_fin = req.body.dateFin ? req.body.dateFin : reservationFound.rows[0].date_fin;

    console.log(`date debut : ${date_debut}`)

    // Instanciation de la classe Reservation
    const reservation = new Reservation(
      id_reservation, intitule, comments, name, fonction, email, telephone,
      id_habilite, date_debut, date_fin
    );

    // Update de la réservation avec les nouvelles données
    await reservation.update();
    const userReservations = await fetchUserReservations(id_habilite, res, next);

    // res.json(`Reservation with the id : ${req.params.idResa} has been updated successfully`);
    res.json(userReservations);
  } catch(err) {
    if (!err.statusCode) {
        err.statusCode = 500;
    }
    next(err);
  }
}

exports.deleteOneReservedApplication = async (req, res, next) => {
  const id_habilite = req.params.idHabilite
  const id_reservation = req.params.idResa;
  const id_couloir = req.params.idCouloir;
  const id_plateforme = req.params.idPlateforme;
  const id_application = req.params.idApplication;
  
  console.log(id_couloir)
  
    try {
      const reservationFound = await Reservation.findById(id_reservation)
    
      if (reservationFound.rowCount === 0) {
        const error = new Error('Could not find reservation...');
        error.statusCode = 404;
        throw error;
      }
  
      const oneReservation = await Couloir_plateforme_application_reservation
        .deleteOne(id_reservation, id_couloir, id_plateforme, id_application);
    
      console.log(oneReservation)

      if (oneReservation.rowCount === 0) {
        const error = new Error('Could not find the application to delete...');
        error.statusCode = 404;
        throw error;
      }

      const userReservations = await fetchUserReservations(id_habilite, res, next);
  
      res.json(userReservations);
    } catch(err) {
      if (!err.statusCode) {
        err.statusCode = 500;
      }
      next(err);
    }
}

exports.deleteEntireReservation = async (req, res, next) => {
  const id_habilite = req.params.idHabilite
  const id_reservation = req.params.idResa;

  try {
    const reservationFound = await Reservation.findById(id_reservation)
 
    if (reservationFound.rowCount === 0) {
      const error = new Error('Could not find reservation...');
      error.statusCode = 404;
      throw error;
    }

    await Reservation.delete(id_reservation);
    await Couloir_plateforme_application_reservation.deleteAll(id_reservation)

    const userReservations = await fetchUserReservations(id_habilite, res, next);
  
    res.json(userReservations);
  } catch(err) {
    if (!err.statusCode) {
      err.statusCode = 500;
    }
    next(err);
  }
}
