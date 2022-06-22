const express = require('express');
const db = require('./utils/database');
const cors = require('./middleware/cors');
const error = require('./middleware/error');

const mainRoutes = require('./router/main');
const authRoutes = require('./router/auth');
const adminRoutes = require('./router/admin');
const reservationRoutes = require('./router/reservation');

const app = express();

app.use(cors);

app.use(express.json());
app.use(express.urlencoded());
app.use('/main', mainRoutes);
app.use('/auth', authRoutes);
app.use('/admin', adminRoutes);
app.use('/reservation', reservationRoutes);

app.use(error);

app.listen(3000, () => {
  console.log("server listen on 3000");
});