const db = require('../utils/database');

module.exports = class Platform {
  constructor(id_plateforme, nom) {
    this.id_plateforme = id_plateforme;
    this.nom = nom;
  }

  static fetchAll() {
    return db.query('SELECT * FROM plateforme');
  }

  static findById(id) {
    return db.query('SELECT * FROM plateforme WHERE plateforme.id = ?', [id]);
  }
};