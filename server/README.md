# Car Rental Application - Car Management Backend Module

This repository hosts a production-ready, scalable, and modular Node.js/Express.js backend for the **Car Management** module of a Car Rental application, integrated with **Supabase (PostgreSQL)**.

---

## Features Implemented
- **Car Draft Setup**: Save vehicle progress at any step and submit for verification later.
- **MVC Architecture**: Explicitly structured directories into Controllers, Services, Repositories, Validators, and Config.
- **Supabase Integration**: Direct database connection utilizing the `@supabase/supabase-js` client SDK.
- **Robust Storage**: Upload car images and registration documents (RC, Insurance, Fitness, PUC) to Supabase Storage, with fallback to local disk storage.
- **Input Validation**: Step-by-step validation rules built with `express-validator` to guarantee data integrity.
- **Centralized Error Handling**: Uniform API responses for successes and failures.
- **Developer Tools**: OpenAPI (Swagger) specifications and a Postman Collection.

---

## Directory Structure
```text
server/
├── migrations/
│   └── schema.sql          # DB initialization and table schema scripts
├── src/
│   ├── config/
│   │   └── supabase.js     # Supabase client setup
│   ├── middleware/
│   │   ├── errorHandler.js # Global error response formatter
│   │   └── multer.js       # File upload configurations
│   ├── modules/
│   │   └── cars/
│   │       ├── controllers/
│   │       ├── services/
│   │       ├── repositories/
│   │       ├── routes/
│   │       └── validators/
│   ├── utils/
│   │   ├── errors.js       # Common application errors (BadRequest, NotFound, etc.)
│   │   └── response.js     # Unified success/error response helpers
│   ├── app.js              # Express application configuration
│   └── server.js           # Main application entry point
├── .env.example
├── package.json
├── swagger.json            # Swagger/OpenAPI 3.0 API specifications
└── postman_collection.json # Importable Postman collection
```

---

## Installation & Setup

### Prerequisites
- Node.js (v16+)
- npm

### 1. Install Dependencies
Navigate into the server directory and run:
```bash
cd server
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and adjust the variables:
```bash
cp .env.example .env
```
Inside `.env`:
- `PORT`: Server port (default: 5000)
- `SUPABASE_URL` & `SUPABASE_KEY`: Find these in your Supabase Project Settings -> API.
- `USE_LOCAL_STORAGE`: Set to `true` to save file uploads locally (recommended for testing without Supabase Storage buckets configured) or `false` to upload to Supabase Storage buckets (`car-images` and `car-documents`).

### 3. Initialize Database in Supabase
1. Log in to your [Supabase Dashboard](https://supabase.com).
2. Go to the **SQL Editor** of your project.
3. Open the file `server/migrations/schema.sql`.
4. Copy its contents, paste them into the SQL Editor, and click **Run**.
5. *(Optional)* If using Supabase Storage (i.e. `USE_LOCAL_STORAGE=false`), navigate to the **Storage** dashboard on Supabase and create two buckets named:
   - `car-images` (make it public)
   - `car-documents`

### 4. Run the Server
- **Development mode (with auto-reload)**:
  ```bash
  npm run dev
  ```
- **Production mode**:
  ```bash
  npm start
  ```

The server will be running on [http://localhost:5000](http://localhost:5000). You can check health at [http://localhost:5000/health](http://localhost:5000/health).

---

## API Endpoints Reference

### Car Registration Flow
| Endpoint | Method | Description |
| :--- | :---: | :--- |
| `/api/v1/cars` | `POST` | Create a new car in `DRAFT` status |
| `/api/v1/cars` | `GET` | Retrieve list of all cars (optional filters like `status`, `brand`) |
| `/api/v1/cars/:id` | `GET` | Get detailed nested view of a specific car |
| `/api/v1/cars/:id` | `PUT` | Update basic car details |
| `/api/v1/cars/:id` | `DELETE` | Delete a car (only permitted in `DRAFT` state) |
| `/api/v1/cars/:id/submit` | `POST` | Transition car status to `PENDING_VERIFICATION` |

### Step-by-Step Data Uploads
| Endpoint | Method | Description |
| :--- | :---: | :--- |
| `/api/v1/cars/:id/location` | `POST` / `PUT` | Save or update car pickup location |
| `/api/v1/cars/:id/location` | `GET` | Retrieve pickup location details |
| `/api/v1/cars/:id/pricing` | `POST` / `PUT` | Save or update pricing schema |
| `/api/v1/cars/:id/pricing` | `GET` | Retrieve pricing schema |
| `/api/v1/cars/:id/availability` | `POST` / `PUT` | Save or update available/blocked dates |
| `/api/v1/cars/:id/availability` | `GET` | Retrieve availability details |
| `/api/v1/cars/:id/images` | `POST` | Upload multiple images (front, back, left, right, interior, dashboard) |
| `/api/v1/cars/:id/images` | `GET` | List all uploaded images of a car |
| `/api/v1/cars/:id/images/:imageId` | `DELETE` | Delete a specific image |
| `/api/v1/cars/:id/documents` | `POST` | Upload PDF/Image files for RC, Insurance, Fitness, and PUC |
| `/api/v1/cars/:id/documents` | `GET` | Get document URLs |

---

## Response Formats

### Success Response (HTTP 200/201)
```json
{
  "success": true,
  "message": "Car details updated successfully",
  "data": {
    "id": "e81d7a8d-...",
    "brand": "Toyota",
    "status": "DRAFT"
  }
}
```

### Validation/Client Error Response (HTTP 400/404)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "year",
      "message": "Year must not exceed the current year"
    }
  ]
}
```

---

## Git Branching Guidelines
To start working on a new feature or code change:
```bash
# Create and switch to a new branch
git checkout -b feature/car-management

# Push branch to origin
git push -u origin feature/car-management
```
