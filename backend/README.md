# Booking Module for Peer-to-Peer Car Rental App Backend

This is the Booking Module built for a peer-to-peer car rental app backend.

## Tech Stack
- **Node.js (Express)**
- **Supabase (PostgreSQL)** via the `@supabase/supabase-js` client
- **Zod** (for request and query parameter validation)
- **node-cron** (for background cleanup of stale pending bookings)
- **Jest & Supertest** (for unit and integration testing)

---

## Required Environment Variables

Create a `.env` file in the root directory based on the `.env.example` file:

```env
PORT=3000
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
```

*Note: The `SUPABASE_SERVICE_ROLE_KEY` is required because the backend needs to perform administrative actions such as updating status, cancellation tracking, and cron job modifications that bypass row-level security (RLS).*

---

## Running Database Migrations on Supabase

Follow these steps to apply the schema and index constraints to your Supabase project:

1. In the Supabase dashboard of your project, navigate to the **SQL Editor**.
2. Click **New Query**.
3. Copy the contents of the migration file located at:
   `database/migrations/001_create_bookings_table.sql`
4. Paste it into the editor and click **Run**.

### Key Features of Database Migration:
- **`btree_gist` Extension**: Enabled to support GIST indexing on basic types like UUID.
- **Generated `date_range` Column**: Automatically aggregates `start_date` and `end_date` into a `daterange` type stored in the database.
- **GIST Exclusion Constraint**: Prevents double-booking at the PostgreSQL level. This applies only to active bookings with statuses `'pending'`, `'confirmed'`, or `'active'`.

---

## Starting the Application and Cron Jobs

1. Install dependencies:
   ```bash
   npm install
   ```
2. Start the Express server and initialize the cron job:
   ```bash
   npm start
   ```

*The scheduled cron job (`expire-pending-bookings.cron.js`) automatically initializes on startup and runs every 10 minutes. It scans for `'pending'` bookings with `'unpaid'` status that were created more than 15 minutes ago, changing their status to `'cancelled'` under system authority.*

---

## Running Automated Tests

Run the Jest test suite using:
```bash
npm test
```
