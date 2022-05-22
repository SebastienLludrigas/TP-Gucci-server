const db = require('../utils/database');

module.exports = class Couloir {
  constructor(id_couloir, nom) {
    this.id_couloir = id_couloir;
    this.nom = nom;
  }

  static fetchAll() {
    return db.query('SELECT * FROM couloir ORDER BY id_couloir');
  }

  static findById(id) {
    return db.query('SELECT * FROM couloir WHERE couloir.id = ?', [id]);
  }
};