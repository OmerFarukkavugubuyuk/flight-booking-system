const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/', async (req, res) => {
    try {
        const query = 'SELECT `iataCode`, `airportName`, `city`, `country` FROM `Airport`';
        const [rows] = await db.execute(query);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ message: "Veritabanı hatası", error: err.message });
    }
});

module.exports = router;