const db = require('../utils/database');

module.exports = class Couloir_plateforme_application_reservation {
  constructor(id_couloir, id_plateforme, id_application, id_reservation, leader, partageable) {
    this.id_couloir = id_couloir;
    this.id_plateforme = id_plateforme;
    this.id_application = id_application;
    this.id_reservation = id_reservation;
    this.leader = leader;
    this.partageable = partageable;
  }

  static fetchAll() {
    return db.query('SELECT * FROM couloir_plateforme_application_reservation ORDER BY id_couloir');
  }

  static findById(id) {
    return db.query(`
      SELECT * FROM couloir_plateforme_application_reservation 
      WHERE couloir_plateforme_application_reservation.id_reservation = ?`, 
      [id]
    );
  }

  static fetchAllDataForArray() {
    return db.query
    (`
      SELECT DISTINCT ap.id_application "id", ap.nom "nom_application", pl.id_plateforme,
      pl.nom "nom_plateforme", co.id_couloir, co.nom "nom_couloir"
      FROM application ap
      INNER JOIN couloir_plateforme_application_reservation coPlAppRe
      ON ap.id_application = coPlAppRe.id_application
      INNER JOIN plateforme pl 
      ON coPlAppRe.id_plateforme = pl.id_plateforme
      INNER JOIN couloir co
      ON coPlAppRe.id_couloir = co.id_couloir
      ORDER BY co.id_couloir, pl.id_plateforme, ap.id_application
    `);
  }

  saveReservation() {
    return db.query
    (`
      INSERT INTO couloir_plateforme_application_reservation
      VALUES($1, $2, $3, $4, $5, $6)`,
      [ 
        this.id_couloir,
        this.id_plateforme,
        this.id_application,
        this.id_reservation,
        this.leader,
        this.partageable
      ]
    );
  }

  updateReservation(id_couloir, id_plateforme, id_application) {
    return db.query
    (`
      UPDATE couloir_plateforme_application_reservation
      SET id_couloir     = $1, 
          id_plateforme  = $2,
          id_application = $3
      WHERE id_reservation = $4
      AND id_couloir = $5
      AND id_plateforme = $6
      AND id_application = $7
      `,
      [
        this.id_couloir,
        this.id_plateforme,
        this.id_application,
        this.id_reservation,
        id_couloir,
        id_plateforme,
        id_application
      ]
    );
  }

  static deleteOne(id_reservation, id_couloir, id_plateforme, id_application) {
    return db.query
    (`
      DELETE FROM couloir_plateforme_application_reservation 
      WHERE id_reservation = $1
      AND id_couloir = $2
      AND id_plateforme = $3
      AND id_application = $4
      `, 
      [
        id_reservation,
        id_couloir,
        id_plateforme,
        id_application
      ]
    );
  }

  static deleteAll(id_reservation) {
    return db.query(
      `DELETE FROM couloir_plateforme_application_reservation WHERE id_reservation = $1`,
      [id_reservation]
    );
  }
};