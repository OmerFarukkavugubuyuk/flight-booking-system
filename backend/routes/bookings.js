const express = require('express');
const router = express.Router();
const db = require('../db');
const { v4: uuidv4 } = require('uuid');

// GET /api/bookings - Giriş yapmış kullanıcının rezervasyonlarını getirir
router.get('/', async (req, res) => {
    const userID = req.user.customerID;
    try {
        const query = `
            SELECT b.\`pnr\`, b.\`bookingTime\`, b.\`status\`, b.\`flightID\`, b.\`date\`,
                   f.\`flightNo\`, dep.\`iataCode\` AS originCode, dep.\`city\` AS originCity,
                   arr.\`iataCode\` AS destCode, arr.\`city\` AS destCity
            FROM \`Booking\` b
            JOIN \`Flight\` f ON b.\`flightID\` = f.\`flightID\`
            JOIN \`Airport\` dep ON f.\`originAirport\` = dep.\`iataCode\`
            JOIN \`Airport\` arr ON f.\`destinationAirport\` = arr.\`iataCode\`
            WHERE b.\`userID\` = ?
            ORDER BY b.\`bookingTime\` DESC`;
            
        const [rows] = await db.execute(query, [userID]);
        
        // Frontend'in beklediği JSON formatına çevirme
        const bookings = rows.map(row => ({
            pnr: row.pnr,
            bookingTime: new Date(row.bookingTime).toISOString(),
            status: row.status,
            flightNo: row.flightNo,
            date: new Date(row.date).toISOString().split('T')[0],
            departure: { iataCode: row.originCode, city: row.originCity },
            arrival: { iataCode: row.destCode, city: row.destCity }
        }));
        
        res.json(bookings);
    } catch (err) {
        res.status(500).json({ message: "Veritabanı hatası", error: err.message });
    }
});

// GET /api/bookings/:pnr - Belirli bir rezervasyonun detaylarını ve biletlerini getirir
router.get('/:pnr', async (req, res) => {
    const userID = req.user.customerID;
    const { pnr } = req.params;
    
    try {
        const bookingQuery = `
            SELECT b.\`pnr\`, b.\`bookingTime\`, b.\`status\`, b.\`date\`, f.\`flightNo\`,
                   dep.\`iataCode\` AS originCode, dep.\`airportName\` AS originName, dep.\`city\` AS originCity,
                   arr.\`iataCode\` AS destCode, arr.\`airportName\` AS destName, arr.\`city\` AS destCity
            FROM \`Booking\` b
            JOIN \`Flight\` f ON b.\`flightID\` = f.\`flightID\`
            JOIN \`Airport\` dep ON f.\`originAirport\` = dep.\`iataCode\`
            JOIN \`Airport\` arr ON f.\`destinationAirport\` = arr.\`iataCode\`
            WHERE b.\`pnr\` = ? AND b.\`userID\` = ?`;
            
        const [bookingRows] = await db.execute(bookingQuery, [pnr, userID]);
        
        if (bookingRows.length === 0) {
            return res.status(404).json({ message: "Rezervasyon bulunamadı." });
        }
        
        const booking = bookingRows[0];
        
        const ticketsQuery = `
            SELECT t.\`ticketNumber\`, cust.\`fullName\`, t.\`passportNo\`,
                   t.\`seatNumber\`, c.\`name\` AS className, t.\`ticketStatus\`
            FROM \`Ticket\` t
            JOIN \`Customer\` cust ON t.\`customerID\` = cust.\`customerID\`
            JOIN \`Seat\` s ON t.\`airplaneID\` = s.\`airplaneID\` AND t.\`seatNumber\` = s.\`seatNumber\`
            JOIN \`Class\` c ON s.\`classID\` = c.\`classID\`
            WHERE t.\`pnr\` = ?`;
            
        const [ticketRows] = await db.execute(ticketsQuery, [pnr]);
        
        res.json({
            pnr: booking.pnr,
            bookingTime: new Date(booking.bookingTime).toISOString(),
            status: booking.status,
            flightNo: booking.flightNo,
            date: new Date(booking.date).toISOString().split('T')[0],
            departure: { iataCode: booking.originCode, airportName: booking.originName, city: booking.originCity },
            arrival: { iataCode: booking.destCode, airportName: booking.destName, city: booking.destCity },
            tickets: ticketRows.map(t => ({
                ticketNumber: t.ticketNumber,
                fullName: t.fullName,
                passportNo: t.passportNo,
                seatNumber: t.seatNumber,
                className: t.className,
                ticketStatus: t.ticketStatus
            }))
        });
    } catch (err) {
        res.status(500).json({ message: "Veritabanı hatası", error: err.message });
    }
});

// POST /api/bookings - Yeni rezervasyon ve bilet oluşturma (Transaction ve Trigger destekli)
router.post('/', async (req, res) => {
    const userID = req.user.customerID; 
    const { flightID, offerDate, tickets } = req.body;
    
    // Sunucu tarafı veri doğrulama
    if (!flightID || !offerDate || !tickets || tickets.length === 0) {
        return res.status(400).json({ message: "Eksik veri gönderildi." });
    }

    const connection = await db.getConnection();

    try {
        await connection.beginTransaction();
        const pnr = uuidv4().substring(0, 6).toUpperCase(); 

        await connection.execute(
            `INSERT INTO \`Booking\` (\`pnr\`, \`userID\`, \`flightID\`, \`date\`) VALUES (?, ?, ?, ?)`,
            [pnr, userID, flightID, offerDate]
        );

        const [[flight]] = await connection.execute(`SELECT \`airplaneID\` FROM \`Flight\` WHERE \`flightID\` = ?`, [flightID]);
        if (!flight) throw new Error("Uçuş bulunamadı.");
        const airplaneID = flight.airplaneID;

        for (let i = 0; i < tickets.length; i++) {
            const t = tickets[i];
            const ticketNumber = `TK-${uuidv4().substring(0, 8).toUpperCase()}`;

            // LAST_INSERT_ID pattern ile yolcu kaydını Müşteri tablosuna ekleme / güncelleme
            await connection.execute(`
                INSERT INTO \`Customer\` (\`fullName\`, \`email\`, \`role\`) 
                VALUES (?, ?, 'Customer') 
                ON DUPLICATE KEY UPDATE 
                    \`customerID\` = LAST_INSERT_ID(\`customerID\`), 
                    \`fullName\` = VALUES(\`fullName\`)`,
                [t.fullName, t.email]
            );
            
            const [[lastInsertResult]] = await connection.execute(`SELECT LAST_INSERT_ID() AS resolvedCustomerID`);
            const resolvedCustomerID = lastInsertResult.resolvedCustomerID;

            // Bilet ekleme. Eğer koltuk doluysa SQL trigger hata fırlatacak.
            await connection.execute(`
                INSERT INTO \`Ticket\` (\`ticketNumber\`, \`passportNo\`, \`pnr\`, \`customerID\`, \`flightID\`, \`airplaneID\`, \`seatNumber\`)
                VALUES (?, ?, ?, ?, ?, ?, ?)`,
                [ticketNumber, t.passportNo, pnr, resolvedCustomerID, flightID, airplaneID, t.seatNumber]
            );
        }

        await connection.commit();
        
        // Frontend'in beklediği cevabı dönebilmek için rezervasyon detaylarını çekiyoruz
        const [[newBooking]] = await connection.execute(`SELECT * FROM \`Booking\` WHERE \`pnr\` = ?`, [pnr]);
        
        res.status(201).json({ 
            pnr: newBooking.pnr,
            bookingTime: new Date(newBooking.bookingTime).toISOString(),
            status: newBooking.status,
            flightID: newBooking.flightID,
            date: new Date(newBooking.date).toISOString().split('T')[0]
        });

    } catch (err) {
        await connection.rollback();
        // SQL Trigger Hatası (Çifte Rezervasyon) Yakalama
        if (err.code === 'ER_SIGNAL_EXCEPTION' || err.errno === 1644) {
            return res.status(409).json({ message: "Double-booking error: Selected seat is already booked." });
        }
        res.status(500).json({ message: "Rezervasyon oluşturulamadı", error: err.message });
    } finally {
        connection.release();
    }
});

module.exports = router;