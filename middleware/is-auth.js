const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  const authHeader = req.get('Authorization');
  if (!authHeader) {
    const error = new Error('Not authenticated.');
    error.statusCode = 500;
    throw error;
  }
  const token = authHeader.split(' ')[1];
  let decodedToken;
  try {
    decodedToken = jwt.verify(token, 'laclésupersecrèteetdoncintrouvabledeGucci');
  } catch (err) {
    if (!err.statusCode) {
      err.statusCode = 401;
      err.message = 'Votre token a expiré, veuillez vous reconnecter'
    }
    next(err);
  }
  if (!decodedToken) {
    const error = new Error();
    error.statusCode = 500;
    throw error;
  }
  req.userId = decodedToken.userId;
  console.log(req.userId)
  next();
};
