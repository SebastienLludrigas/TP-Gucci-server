const db = require('../utils/database');

module.exports = class Habilite {
  constructor(id_habilite, nom, fonction, telephone, email, password, role, status) {
    this.id_habilite = id_habilite;
    this.nom = nom;
    this.fonction = fonction;
    this.telephone = telephone;
    this.email = email;
    this.password = password;
    this.role = role;
    this.status = status;
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

  createUser() {
    return db.query
    (`
      INSERT INTO habilite(nom, fonction, telephone, email, password, role, status)
      VALUES($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [
        this.nom,
        this.fonction,
        this.telephone,
        this.email,
        this.password,
        this.role,
        this.status
      ]
    );
  }
};