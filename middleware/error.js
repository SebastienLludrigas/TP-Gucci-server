// Middleware exécuté à chaque fois qu'un throw error sera rencontré ou qu'une erreur sera transmise avec next(err), il permettra d'envoyer au client le message d'erreur et le statusCode passé à l'objet error. 
// Le fait de passer 4 paramètres à ce middleware indique à express qu'il s'agit d'un middleware d'erreur.
module.exports = (error, req, res, next) => {
  console.log(error);
  const status = error.statusCode || 500;
  const message = error.message;
  const data = error.data;
  res.status(status).json({ message, data });
}