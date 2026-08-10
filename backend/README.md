# Booking Module for Peer-to-Peer Car Rental App Backend

This backend includes the existing booking module and the new vehicle document verification module.

## Tech Stack
- **Node.js (Express)**
- **Supabase (PostgreSQL + Storage)** via the `@supabase/supabase-js` client
- **Multer** for multipart uploads
- **JWT authentication** via the existing auth middleware
- **OCR + Gemini-ready service layer** for document analysis
- **Jest & Supertest** (for unit and integration testing)

---

## Required Environment Variables

Create a `.env` file in the root directory based on the `.env.example` file:

```env
PORT=3000
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
GEMINI_API_KEY=your-gemini-api-key
JWT_SECRET=your-jwt-secret
```

---

## Starting the Application

1. Install dependencies:
   ```bash
   npm install
   ```
2. Start the Express server:
   ```bash
   npm start
   ```

---

## Vehicle Document Verification Endpoints

- POST /api/documents/upload
- POST /api/documents/analyze
- POST /api/documents/verify

## Postman example

A sample collection is available in the backend root as `postman_document_verification.json`.

## Running Automated Tests

Run the Jest test suite using:
```bash
npm test
```
