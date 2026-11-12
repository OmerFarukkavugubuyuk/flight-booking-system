// routes/offers.js
const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/', async (req, res) => {
    const { dep, arr, date } = req.query;
    if (dep === arr) return res.json([]); 
    
    try {
        const query = `
            SELECT o.\`flightID\`, o.\`date\`, f.\`flightNo\`, f.\`basePrice\`,
                   ap.\`airplaneID\`, ap.\`model\`, ap.\`capacity\`,
                   dep.\`iataCode\` AS dep_iataCode, dep.\`airportName\` AS dep_airportName, dep.\`city\` AS dep_city, dep.\`country\` AS dep_country,
                   arr.\`iataCode\` AS arr_iataCode, arr.\`airportName\` AS arr_airportName, arr.\`city\` AS arr_city, arr.\`country\` AS arr_country
            FROM \`Offer\` o
            JOIN \`Flight\` f ON o.\`flightID\` = f.\`flightID\`
            JOIN \`Airplane\` ap ON f.\`airplaneID\` = ap.\`airplaneID\`
            JOIN \`Airport\` dep ON f.\`originAirport\` = dep.\`iataCode\`
            JOIN \`Airport\` arr ON f.\`destinationAirport\` = arr.\`iataCode\`
            WHERE f.\`originAirport\` = ? AND f.\`destinationAirport\` = ? AND o.\`date\` = ?`;
            
        const [rows] = await db.execute(query, [dep, arr, date]);
        
        // Formatting to match frontend expectations
        const offers = rows.map(row => ({
            flightID: row.flightID,
            date: row.date.toISOString().split('T')[0],
            flightNo: row.flightNo,
            basePrice: Number(row.basePrice),
            airplane: { airplaneID: row.airplaneID, model: row.model, capacity: row.capacity },
            departure: { iataCode: row.dep_iataCode, airportName: row.dep_airportName, city: row.dep_city, country: row.dep_country },
            arrival: { iataCode: row.arr_iataCode, airportName: row.arr_airportName, city: row.arr_city, country: row.arr_country }
        }));
        res.json(offers);
    } catch (err) {
        res.status(500).json({ message: "Database error", error: err.message });
    }
});
module.exports = router;