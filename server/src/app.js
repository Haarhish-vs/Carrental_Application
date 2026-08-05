// app.js
const express = require('express');
const cors = require('cors');
const authRoutes = require('./modules/auth/auth.routes');
const vehicleRoutes = require('./modules/vehicles/vehicle.routes');
const bookingRoutes = require('./modules/bookings/booking.routes');
const errorHandler = require('./shared/middlewares/error.middleware');

const app = express();

// Middlewares
const path = require('path');
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../public/uploads')));

// Premium Interactive Root Dashboard Page (API Docs & Status)
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Rent-A-Car P2P Backend Service Portal</title>
      <!-- Google Fonts -->
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&family=Plus+Jakarta+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
      <style>
        :root {
          --bg-dark: #0a0c10;
          --bg-card: rgba(18, 22, 32, 0.7);
          --accent-primary: #ff5e3a;
          --accent-glow: rgba(255, 94, 58, 0.15);
          --text-main: #f3f4f6;
          --text-muted: #9ca3af;
          --success: #10b981;
          --border: rgba(255, 255, 255, 0.08);
          --glass-shine: rgba(255, 255, 255, 0.03);
        }

        * {
          box-sizing: border-box;
          margin: 0;
          padding: 0;
        }

        body {
          font-family: 'Plus Jakarta Sans', sans-serif;
          background: radial-gradient(circle at 50% -20%, #1e1b29, var(--bg-dark) 70%);
          color: var(--text-main);
          min-height: 100vh;
          overflow-x: hidden;
          padding: 2rem;
          display: flex;
          flex-direction: column;
          align-items: center;
        }

        .container {
          max-width: 900px;
          width: 100%;
          z-index: 10;
        }

        header {
          text-align: center;
          margin-bottom: 3rem;
          position: relative;
        }

        h1 {
          font-family: 'Outfit', sans-serif;
          font-size: 3rem;
          font-weight: 700;
          letter-spacing: -0.02em;
          background: linear-gradient(135deg, #fff 0%, #a5b4fc 50%, var(--accent-primary) 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          margin-bottom: 0.5rem;
          display: inline-block;
          animation: float 6s ease-in-out infinite;
        }

        @keyframes float {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-5px); }
        }

        .status-badge {
          display: inline-flex;
          align-items: center;
          background: rgba(16, 185, 129, 0.1);
          border: 1px solid rgba(16, 185, 129, 0.2);
          color: var(--success);
          padding: 0.4rem 1rem;
          border-radius: 50px;
          font-size: 0.85rem;
          font-weight: 600;
          margin-top: 1rem;
          backdrop-filter: blur(10px);
          animation: pulse 2s infinite;
        }

        @keyframes pulse {
          0% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.3); }
          70% { box-shadow: 0 0 0 10px rgba(16, 185, 129, 0); }
          100% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); }
        }

        .dashboard-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 1.5rem;
        }

        .card {
          background: var(--bg-card);
          border: 1px solid var(--border);
          border-radius: 20px;
          padding: 2rem;
          backdrop-filter: blur(20px);
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
          transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
          position: relative;
          overflow: hidden;
        }

        .card::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: linear-gradient(130deg, var(--glass-shine), transparent);
          pointer-events: none;
        }

        .card:hover {
          transform: translateY(-4px);
          border-color: rgba(255, 94, 58, 0.3);
          box-shadow: 0 30px 60px rgba(0, 0, 0, 0.4), 0 0 40px var(--accent-glow);
        }

        h2 {
          font-family: 'Outfit', sans-serif;
          font-size: 1.6rem;
          margin-bottom: 1.5rem;
          color: #fff;
          border-bottom: 1px solid var(--border);
          padding-bottom: 0.5rem;
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .endpoint-list {
          list-style: none;
          display: flex;
          flex-direction: column;
          gap: 1rem;
        }

        .endpoint-row {
          display: flex;
          align-items: center;
          gap: 1rem;
          padding: 0.8rem;
          border-radius: 12px;
          background: rgba(255, 255, 255, 0.02);
          border: 1px solid var(--border);
          font-family: monospace;
          font-size: 0.95rem;
          transition: background 0.2s;
        }

        .endpoint-row:hover {
          background: rgba(255, 94, 58, 0.05);
        }

        .method {
          font-weight: 700;
          padding: 0.25rem 0.6rem;
          border-radius: 6px;
          font-size: 0.75rem;
          width: 70px;
          text-align: center;
        }

        .method.post { background: rgba(59, 130, 246, 0.15); color: #60a5fa; border: 1px solid rgba(59, 130, 246, 0.2); }
        .method.get { background: rgba(16, 185, 129, 0.15); color: #34d399; border: 1px solid rgba(16, 185, 129, 0.2); }
        .method.patch { background: rgba(245, 158, 11, 0.15); color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.2); }
        .method.delete { background: rgba(239, 68, 68, 0.15); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.2); }

        .path {
          color: #e5e7eb;
          flex-grow: 1;
        }

        .desc {
          color: var(--text-muted);
          font-size: 0.85rem;
        }

        footer {
          text-align: center;
          margin-top: 4rem;
          color: var(--text-muted);
          font-size: 0.85rem;
          border-top: 1px solid var(--border);
          padding-top: 2rem;
        }

        footer a {
          color: var(--accent-primary);
          text-decoration: none;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <header>
          <h1>RENT-A-CAR</h1>
          <div>
            <span class="status-badge">● API Online & Verified</span>
          </div>
        </header>

        <div class="dashboard-grid">
          <!-- Auth Module Card -->
          <div class="card">
            <h2>🔑 Authentication Services</h2>
            <ul class="endpoint-list">
              <li class="endpoint-row">
                <span class="method post">POST</span>
                <span class="path">/api/auth/send-otp</span>
                <span class="desc">Rate-limited SMS generator</span>
              </li>
              <li class="endpoint-row">
                <span class="method post">POST</span>
                <span class="path">/api/auth/verify-otp</span>
                <span class="desc">Verify OTP & return Session Token</span>
              </li>
              <li class="endpoint-row">
                <span class="method post">POST</span>
                <span class="path">/api/auth/complete-profile</span>
                <span class="desc">Update profile details (Auth)</span>
              </li>
              <li class="endpoint-row">
                <span class="method get">GET</span>
                <span class="path">/api/auth/me</span>
                <span class="desc">Retrieve logged-in user profile</span>
              </li>
            </ul>
          </div>

          <!-- Vehicles Module Card -->
          <div class="card">
            <h2>🚗 Vehicle Fleets & Listings</h2>
            <ul class="endpoint-list">
              <li class="endpoint-row">
                <span class="method get">GET</span>
                <span class="path">/api/vehicles</span>
                <span class="desc">Search active & available cars</span>
              </li>
              <li class="endpoint-row">
                <span class="method get">GET</span>
                <span class="path">/api/vehicles/:id</span>
                <span class="desc">Vehicle details (unexposed owner phone)</span>
              </li>
              <li class="endpoint-row">
                <span class="method post">POST</span>
                <span class="path">/api/vehicles</span>
                <span class="desc">Create car listing (Auth)</span>
              </li>
              <li class="endpoint-row">
                <span class="method post">POST</span>
                <span class="path">/api/vehicles/:id/documents</span>
                <span class="desc">Upload RC document/Book (Owner)</span>
              </li>
              <li class="endpoint-row">
                <span class="method patch">PATCH</span>
                <span class="path">/api/vehicles/:id/availability</span>
                <span class="desc">Toggle availability flag (Owner)</span>
              </li>
            </ul>
          </div>

          <!-- Bookings Card -->
          <div class="card">
            <h2>📅 Bookings & Trips</h2>
            <ul class="endpoint-list">
              <li class="endpoint-row">
                <span class="method post">POST</span>
                <span class="path">/api/bookings</span>
                <span class="desc">Create booking (Date exclude checking)</span>
              </li>
              <li class="endpoint-row">
                <span class="method get">GET</span>
                <span class="path">/api/bookings/my-bookings</span>
                <span class="desc">My rented car reservations</span>
              </li>
              <li class="endpoint-row">
                <span class="method patch">PATCH</span>
                <span class="path">/api/bookings/:id/confirm</span>
                <span class="desc">Confirm rental request (Owner only)</span>
              </li>
              <li class="endpoint-row">
                <span class="method patch">PATCH</span>
                <span class="path">/api/bookings/:id/cancel</span>
                <span class="desc">Cancel booking with fee tiers</span>
              </li>
            </ul>
          </div>
        </div>

        <footer>
          <p>Built with Node.js, Express & Supabase. Service role protected.</p>
        </footer>
      </div>
    </body>
    </html>
  `);
});

// Top-level explicit vehicle upload endpoint
const uploadMiddleware = require('./shared/middlewares/upload.middleware');
const { protect: protectAuth } = require('./shared/middlewares/auth.middleware');
const vehicleCtrl = require('./modules/vehicles/vehicle.controller');

app.post('/api/vehicles/upload', protectAuth, uploadMiddleware.array('files'), vehicleCtrl.uploadMedia);

// Endpoint Routes
app.use('/api/auth', authRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/bookings', bookingRoutes);

// Unhandled Endpoint Catcher (404)
app.use((req, res, next) => {
  const error = new Error(`Route ${req.originalUrl} not found`);
  error.statusCode = 404;
  next(error);
});

// Global Error Handler Middleware
app.use(errorHandler);

module.exports = app;
