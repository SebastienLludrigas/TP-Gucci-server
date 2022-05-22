const db = require('../utils/database');

module.exports = class Application {
  constructor(id_application, nom, version, id_plateforme) {
    this.id_application = id_application;
    this.nom = nom;
    this.version = version;
    this.id_plateforme = id_plateforme;
  }

  static fetchAll() {
    return db.query('SELECT * FROM application ORDER BY nom');
  }

  static findById(id) {
    return db.query(`SELECT * FROM application WHERE application.id = ${id}`);
  }
};