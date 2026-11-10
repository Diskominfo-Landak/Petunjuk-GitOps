const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;
const APP_NAME = process.env.APP_NAME || 'Aplikasi Node.js Pemkab Landak';

app.use(express.json());

// Endpoint pemeriksaan kesehatan (Healthcheck) untuk GitOps & Docker
app.get('/healthz', (req, res) => {
    res.status(200).json({
        status: 'ok',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

app.get('/up', (req, res) => {
    res.status(200).send('OK');
});

// Halaman utama
app.get('/', (req, res) => {
    res.json({
        message: `Selamat datang di ${APP_NAME}`,
        environment: process.env.NODE_ENV || 'development',
        status: 'running'
    });
});

// Start server jika dijalankan langsung
if (require.main === module) {
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`[${new Date().toISOString()}] Server ${APP_NAME} berjalan di port ${PORT}`);
    });
}

module.exports = app;
