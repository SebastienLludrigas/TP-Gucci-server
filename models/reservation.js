const db = require('../utils/database');

module.exports = class Reservation {
  constructor(id_reservation, intitule, comments, name, fonction, email, telephone, id_habilite, date_debut, date_fin, created_at) {
    this.id_reservation = id_reservation;
    this.intitule = intitule;
    this.comments = comments;
    this.name = name;
    this.fonction = fonction;
    this.email = email;
    this.telephone = telephone;
    this.id_habilite = id_habilite;
    this.date_debut = date_debut;
    this.date_fin = date_fin;
    this.created_at = created_at;
  }

  static fetchAll() {
    return db.query('SELECT * FROM reservation');
  }

  static findById(id) {
    return db.query('SELECT * FROM reservation WHERE id_reservation = $1', [id]);
  }

  static findMaxId() {
    return db.query('SELECT MAX(id_reservation) FROM reservation');
  }

  save() {
    return db.query
    (`
      INSERT INTO reservation(intitule, comments, name, fonction, email, telephone, id_habilite, date_debut, date_fin)
      VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [
        this.intitule,
        this.comments,
        this.name,
        this.fonction,
        this.email,
        this.telephone,
        this.id_habilite,
        this.date_debut,
        this.date_fin
      ]
    );
  }

  update() {
    return db.query
    (`
      UPDATE reservation
      SET intitule    = $1,
          comments    = $2, 
          name        = $3,
          fonction    = $4,
          email       = $5,
          telephone   = $6,
          id_habilite = $7,
          date_debut  = $8,
          date_fin    = $9
      WHERE id_reservation = $10
      `,
      [
        this.intitule,
        this.comments,
        this.name,
        this.fonction,
        this.email,
        this.telephone,
        this.id_habilite,
        this.date_debut,
        this.date_fin,
        this.id_reservation
      ]
    );
  }

  static delete(id_reservation) {
    return db.query(`DELETE FROM reservation WHERE id_reservation = $1`, [id_reservation]);
  }

  static infosResas() {
    return db.query
    (`
      SELECT coPlAppRe.id_couloir, coPlAppRe.id_plateforme, coPlAppRe.id_application, co.nom "nomCouloir", pl.nom "nomPlateforme", app.nom "nomApplication",
      re.id_reservation, re.intitule, re.id_habilite, re.comments, re.date_debut, re.date_fin, re.name, re.fonction, re.telephone, re.email,
      (re.date_fin::date - re.date_debut::date)::int + 1 "nbJoursReservation" 
      FROM reservation re
      INNER JOIN couloir_plateforme_application_reservation coPlAppRe
      ON re.id_reservation = coPlAppRe.id_reservation
      INNER JOIN couloir co
      ON coPlAppRe.id_couloir = co.id_couloir
      INNER JOIN plateforme pl
      on coPlAppRe.id_plateforme = pl.id_plateforme
      INNER JOIN application app
      ON coPlAppRe.id_application = app.id_application
      WHERE coPlAppRe.id_reservation > 0
    `);
  }
};