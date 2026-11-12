const express = require('express');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors({
    origin: 'http://localhost:5173',
    credentials: true
}));

app.use(express.json());

app.use((req, res, next) => {
    req.user = { customerID: 1 };
    next();
});

const bookingsRouter = require('./routes/bookings');
const offersRouter = require('./routes/offers');
const authRouter = require('./routes/auth');
const airportsRouter = require('./routes/airports');

app.use('/api/bookings', bookingsRouter);
app.use('/api/offers', offersRouter);
app.use('/api/auth', authRouter);
app.use('/api/airports', airportsRouter);

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});