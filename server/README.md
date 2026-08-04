# Rent-A-Car P2P Mobile App Backend API

This is the complete Express-based REST API for a peer-to-peer car rental mobile app, integrated with **Supabase (PostgreSQL + Auth)** using `@supabase/supabase-js`.

## Tech Stack & Architecture
- **Runtime**: Node.js (Express)
- **Database**: Supabase PostgreSQL + Auth
- **ORM & Data Client**: Supabase JS SDK (`@supabase/supabase-js`)
- **Task Scheduling**: `node-cron`
- **Testing**: Jest + `supertest`

---

## Environment Variables Setup

Create a `.env` file in the `/server` directory:

```env
PORT=3000
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key-bypasses-rls
JWT_SECRET=your-supabase-jwt-secret-from-dashboard-settings
SMS_PROVIDER_API_KEY=mock-sms-key
```

> [!IMPORTANT]
> - **SUPABASE_SERVICE_ROLE_KEY**: Make sure you use the `service_role` key and NOT the `anon` key, as the server needs administrative privileges to perform custom rate-limited OTP updates, document verification, and manage the database.
> - **JWT_SECRET**: Use the exact Supabase JWT secret found under your Supabase Project Settings -> API -> JWT Secret. This allows the backend to issue tokens that Supabase services automatically trust.

---

## Supabase Database Migrations

Copy and execute the SQL scripts located in `src/database/migrations` inside your Supabase **SQL Editor** in the following order:

1. **`001_create_profiles_table.sql`**: Sets up the public `users` table linked 1-to-1 with `auth.users`, and the custom `otp_verifications` table.
2. **`002_create_vehicles_table.sql`**: Creates the `vehicles` table incorporating the custom rental parameters matching front-end states (like variant, odometer reading, mileage, color, etc.).
3. **`003_create_bookings_table.sql`**: Enables the PostgreSQL `btree_gist` extension and establishes the `bookings` table with an `EXCLUDE` constraint preventing double-bookings.
4. **`004_create_vehicle_documents_table.sql`**: Configures the document table tracker.

---

## Installation & Running

### 1. Install Dependencies
```bash
npm install
```

### 2. Start the Server
The background cron job to expire stale unpaid pending bookings starts automatically in the background alongside the Express server.
```bash
# Run in development mode (nodemon auto-reload)
npm run dev

# Run in production mode
npm start
```

### 3. Run Automated Jest Tests
The test suite utilizes mocks for the database connection and SMS services to ensure fast, deterministic tests without making network requests.
```bash
npm run test
```

---

## API Modules

### Module 1: Authentication (Mobile OTP)
- **POST `/api/auth/send-otp`**: Generates a 6-digit verification code, bcrypt-hashes it, enforces rate limits (max 3 requests per 15 minutes per number), and logs it to SMS console.
- **POST `/api/auth/verify-otp`**: Compares bcrypt hash, checks expiry, locks after 5 attempts. Creates a new user profile or logs in existing user, returning a Supabase-compatible JWT token.
- **POST `/api/auth/complete-profile`**: Set user full name after first signup (Protected).
- **GET `/api/auth/me`**: Fetches the profile of the logged-in user (Protected).

### Module 2: Vehicles (Listing & Browsing)
- **GET `/api/vehicles`**: Browses active & available listings with filters (city, price range, fuel, transmission, seats). (Public, No Auth).
- **GET `/api/vehicles/:id`**: Gets car detail. Returns owner phone number only if current user is owner or has a confirmed/active booking for the vehicle. (Public, No Auth).
- **POST `/api/vehicles`**: Creates a new listing in `under_review` status (Protected).
- **POST `/api/vehicles/:id/documents`**: Uploads registration book document (Protected, Owner).
- **PATCH `/api/vehicles/:id/availability`**: Toggles car visibility for future searches (Protected, Owner).
- **PATCH `/api/admin/vehicles/:id/verify-document`**: Simulated admin verification. Verifying `rc_book` transitions the car status to `active`. (Admin).

### Module 3: Bookings
- **POST `/api/bookings`**: Creates a booking request. Validates car status, checks dates, checks renter ≠ owner, and handles PG exclusion 23P01 code returning a clean `409` conflict error (Protected).
- **GET `/api/bookings/my-bookings`**: Renter's reservations (Protected).
- **GET `/api/bookings/my-vehicle-bookings`**: Owner's incoming bookings (Protected).
- **PATCH `/api/bookings/:id/confirm`**: Owner confirms pending request (Protected).
- **PATCH `/api/bookings/:id/start`**: Transitions booking from confirmed to active (Protected).
- **PATCH `/api/bookings/:id/complete`**: Owner completes active trip (Protected).
- **PATCH `/api/bookings/:id/cancel`**: Cancels booking. Computes refunds and fee tiers (>48 hrs: 0% fee, 24-48 hrs: 50% fee, <24 hrs: 100% fee; deposit always fully refunded). Owner cancellation adds penalty count and refunds 100% (Protected).
