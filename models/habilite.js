const db = require('../utils/database');

module.exports = class Habilite {
  constructor(id_habilite, nom, fonction, telephone, email, login, password) {
    this.id_habilite = id_habilite;
    this.nom = nom;
    this.fonction = fonction;
    this.telephone = telephone;
    this.email = email;
    this.login = login;
    this.password = password;
  }

  static fetchAll() {
    return db.query('SELECT * FROM habilite');
  }

  static findByEmail(email) {
    return db.query('SELECT * FROM habilite WHERE habilite.email = $1', [email]);
  }

  static findById(id) {
    return db.query('SELECT * FROM habilite WHERE habilite.id_habilite = $1', [id]);
  }

  static findMaxId() {
    return db.query('SELECT MAX(id_habilite) FROM habilite');
  }

  static allUserReservations(id) {
    return db.query('SELECT * FROM reservation WHERE id_habilite = $1 ORDER BY id_reservation', [id]);
  }

  static allUserApplicationReservedByIdReservation(id) {
    return db.query(
      `
      SELECT DISTINCT cpar.id_reservation, cpar.id_couloir, co.nom "nom_couloir", cpar.id_plateforme, 
                      pl.nom "nom_plateforme", cpar.id_application, ap.nom "nom_application"
      FROM couloir_plateforme_application_reservation cpar
      INNER JOIN couloir co
      ON cpar.id_couloir = co.id_couloir
      INNER JOIN plateforme pl
      ON cpar.id_plateforme = pl.id_plateforme
      INNER JOIN application ap
      ON cpar.id_application = ap.id_application
      WHERE cpar.id_reservation = $1
      `,
      [id]
    );
  }
};