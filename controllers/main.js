const Couloir = require('../models/couloir');
const Platform = require('../models/plateforme');
const Application = require('../models/application');
const Couloir_plateforme_application = require('../models/couloir_plateforme_application_reservation');

exports.getCouloirs = (req,res,next) => {
  Couloir.fetchAll()
    .then((couloirs) => {
      res
        .status(200)
        .json({ 
          message: 'fetched couloirs succesfully',
          totalItems: couloirs.rowCount, 
          couloirs: couloirs.rows
        });
      // console.log(couloirs);
    })
    .catch(err => {
      // Ici c'est toujours le même système de renvoi d'erreur au middleware de gestion des erreurs dans app.js qui est utilisé
      if (!err.statusCode) {
        err.statusCode = 500;
      }
      // Ici, le fait que l'on passe un paramètre à la méthode next() indique à express qu'il y a une erreur
      // et qu'il faut arréter la stack d'exécution des middlewares classiques et des routes handler
      // et qu'on va passer à la stack d'erreurs
      // SAUF ! Si le paramètre passé est === 'route' car ce paramètre indique à expres qu'il faut passer
      // au router handler suivant. Tout autre paramètre que 'route' passé à next() signalera donc
      // à express que l'on est en présence d'une erreur.
      next(err);
    });
}

exports.getPlatforms = (req,res,next) => {
  Platform.fetchAll()
    .then((platforms) => {
      res
        .status(200)
        .json({ 
          message: 'fetched platforms succesfully',
          totalItems: platforms.rowCount, 
          platforms: platforms.rows
        });
      // console.log(platforms);
    })
    .catch(err => {
      // Ici c'est toujours le même système de renvoi d'erreur au middleware de gestion des erreurs dans app.js qui est utilisé
      if (!err.statusCode) {
        err.statusCode = 500;
      }
      next(err);
    });
}

exports.getApplications = (req,res,next) => {
   Application.fetchAll()
      .then((applications) => {
         res
         .status(200)
         .json({ 
            message: 'fetched applications succesfully',
            totalItems: applications.rowCount, 
            applications: applications.rows
         });
         // console.log(applications);
      })
      .catch(err => {
        if (!err.statusCode) {
        err.statusCode = 500;
        }
        next(err);
      });
}

exports.getAppPlCo = (req, res, next) => {
   Couloir_plateforme_application.fetchAllDataForArray()
      .then(appPlCo => {
         // console.log(appPlCo);
         res
         .status(200)
         .json({ 
            message: 'fetched applications, plateformes and couloirs succesfully',
            totalItems: appPlCo.rowCount, 
            appPlCo: appPlCo.rows
         });
      })
      .catch(err => {
         // Ici c'est toujours le même système de renvoi d'erreur au middleware de gestion des erreurs dans app.js qui est utilisé
         if (!err.statusCode) {
         err.statusCode = 500;
         }
         next(err);
      });
}
