# 🚗 Rent-A-Car — P2P Car Rental Application

A full-stack, production-ready **Peer-to-Peer Car Rental Platform** built with **Flutter (mobile + web)** and **Node.js + Supabase (backend)**. Users can rent out their own cars or book available cars — all with phone-based OTP authentication, Cloudinary image storage, and real-time booking management.

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Tech Stack](#-tech-stack)
3. [Project Architecture](#-project-architecture)
4. [Features Implemented](#-features-implemented)
5. [Flutter Frontend — Screen-by-Screen Breakdown](#-flutter-frontend--screen-by-screen-breakdown)
6. [Backend API — Module Breakdown](#-backend-api--module-breakdown)
7. [Flutter Packages Used](#-flutter-packages-used)
8. [Backend Packages Used](#-backend-packages-used)
9. [Authentication Flow](#-authentication-flow)
10. [Image Upload Flow (Cloudinary)](#-image-upload-flow-cloudinary)
11. [Booking Flow](#-booking-flow)
12. [Widget Classification (Stateful vs Stateless)](#-widget-classification-stateful-vs-stateless)
13. [Database Design (Supabase/PostgreSQL)](#-database-design-supabasepostgresql)
14. [How to Run the Project](#-how-to-run-the-project)
15. [Interview Q&A Preparation](#-interview-qa-preparation)

---

## 🏆 Project Overview

**Rent-A-Car** is a mobile-first Flutter application that connects **car owners** (who want to earn by renting their vehicles) with **renters** (who need a car for a period). Think of it as an Airbnb for cars.

**Key Differentiators:**
- Phone number OTP login — no passwords
- Cloudinary CDN image storage for all vehicle photos
- 4-step guided car listing wizard for owners
- Double-booking prevention using PostgreSQL EXCLUDE constraint
- End-to-end token-based route protection

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Dart) — Android + Web |
| UI Design | Material Design 3 (MD3) |
| HTTP Client | Dio (interceptors + retry) |
| Backend | Node.js + Express.js |
| Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth + Custom JWT + OTP |
| Image Storage | Cloudinary CDN |
| File Picking | file_picker, image_picker |
| Maps | Google Maps Flutter |
| Deployment | Render.com (backend) |
| Testing | Flutter Test + Jest (Node.js) |

---

## 🏗️ Project Architecture

```
Car_Rental_Application/
├── client/
│   └── car_rental_app_client_side/
│       ├── lib/
│       │   ├── main.dart                    ← App Entry, MaterialApp, HomePage
│       │   ├── core/theme/app_colors.dart   ← Global Color Tokens
│       │   └── features/
│       │       ├── auth/
│       │       │   ├── presentation/screens/auth_screen.dart   ← OTP Login UI
│       │       │   └── services/auth_service.dart              ← Auth API + Token
│       │       ├── home/
│       │       │   └── presentation/screens/
│       │       │       ├── home_screen.dart           ← Tab Navigation
│       │       │       ├── car_detail_screen.dart     ← Vehicle Detail + Booking
│       │       │       └── my_bookings_screen.dart    ← Renter Booking History
│       │       └── owner/
│       │           ├── data/
│       │           │   ├── models/vehicle_model.dart  ← VehicleModel + fromDraft()
│       │           │   └── services/car_api_service.dart ← All API Calls via Dio
│       │           └── presentation/screens/rent_car/
│       │               ├── car_spefication.dart       ← Step 1: Car Specs
│       │               ├── car_images.dart            ← Step 2: Photo Upload
│       │               ├── car_pricingandavilablity.dart ← Step 3: Pricing
│       │               ├── car_documents.dart         ← Step 4: RC Document + Submit
│       │               └── rent_car_shared.dart       ← Shared Draft Model
│       ├── android/app/build.gradle.kts    ← compileSdk=36, minSdk=24
│       ├── pubspec.yaml
│       └── test/
│           ├── widget_test.dart             ← HomeScreen render test
│           └── rent_car_flow_test.dart      ← VehicleModel + form tests
└── server/
    └── src/
        ├── app.js                           ← Express app, routes, middleware
        ├── config/env.js                    ← Env vars + Cloudinary config
        ├── modules/
        │   ├── auth/                        ← OTP, JWT, profile
        │   ├── vehicles/                    ← CRUD + Cloudinary upload
        │   ├── bookings/                    ← Booking + overlap check
        │   └── locations/                   ← Google Maps integration
        └── shared/middlewares/
            ├── auth.middleware.js           ← JWT verify + req.user
            ├── upload.middleware.js         ← Multer memoryStorage
            └── error.middleware.js          ← Global error handler
```

---

## ✅ Features Implemented

| # | Feature | Status |
|---|---------|--------|
| 1 | Phone OTP Authentication (login + register) | ✅ Done |
| 2 | JWT token stored in-memory, synced across services | ✅ Done |
| 3 | Route Protection (Rent Out / Book require login) | ✅ Done |
| 4 | Home Screen with live Supabase vehicle listings | ✅ Done |
| 5 | 4-Step "Rent Out Your Car" wizard | ✅ Done |
| 6 | Cloudinary image upload (car photos + RC document) | ✅ Done |
| 7 | Car Detail Screen with booking form | ✅ Done |
| 8 | My Bookings screen for renters | ✅ Done |
| 9 | Double-booking prevention (PostgreSQL EXCLUDE) | ✅ Done |
| 10 | Backend deployed live on Render.com | ✅ Done |
| 11 | 25/25 Jest backend tests passing | ✅ Done |
| 12 | Flutter Web + Android build support | ✅ Done |

---

## 📱 Flutter Frontend — Screen-by-Screen Breakdown

### 1. `MyApp` — StatelessWidget (main.dart)
- Entry point via `runApp()`
- Configures `MaterialApp` with Material Design 3 theme
- Primary color `#1E5AA8`, background `#F4F7FB`
- Initial route: `HomeScreen()`

---

### 2. `HomeScreen` — StatefulWidget
- Bottom navigation with 4 tabs: Home, Explore, My Bookings, Profile
- **State managed:** selected tab index via `setState()`

**`HomePage` — StatefulWidget (inside main.dart)**
- `initState()` calls `getVehicles()` → `FutureBuilder` renders `GridView`
- Each car card: Cloudinary image, brand/model, city, price, specs
- "Rent Out" button → auth check → `CarSpecification` Step 1

---

### 3. `AuthScreen` — StatefulWidget
- 3 internal steps: Phone Entry → OTP Verification → Profile Completion
- `TextEditingController` for each input
- On success → `AuthService.currentToken` + `CarApiService.token` both set
- `Navigator.pop(context, true)` signals parent screen to continue

---

### 4. `CarDetailScreen` — StatefulWidget
- **Header:** `PageView` image carousel (Cloudinary URLs via `Image.network`)
- **Body:** Spec chips for seats, fuel, transmission + description + city
- **Footer (sticky):** `showDatePicker()` for start/end, total price, "Book Now"
- "Book Now" → auth guard → `createBooking()` → success dialog

---

### 5. `MyBookingsScreen` — StatefulWidget
- `FutureBuilder` with `getMyBookings()` → `ListView` of booking cards
- Status chips: CONFIRMED (green), PENDING (orange), CANCELLED (red)
- Shows booking period, total price, deposit amount
- Not logged in → auth prompt shown inline

---

### 6. Rent-Out Wizard — 4-Step Flow

| Step | Screen | StatefulWidget | Key Feature |
|------|--------|---------------|-------------|
| 1 | `CarSpecification` | Yes | `Form` + `GlobalKey<FormState>` validation |
| 2 | `CarImages` | Yes | `image_picker` + `LinearProgressIndicator` upload |
| 3 | `CarPricingAndAvailability` | Yes | `showDatePicker()` + price inputs |
| 4 | `CarDocuments` | Yes | `file_picker` RC upload + `createVehicle()` final submit |

**Shared state** between steps: `RentCarDraft` — a plain Dart class passed via Navigator arguments.

---

### 7. `CarApiService` — Service Class (NOT a widget)
- `Dio` instance with base URL `https://carrental-application-z49a.onrender.com`
- **Interceptor:** auto-attaches `Authorization: Bearer <token>` to every request
- **Retry:** 1× retry on timeout errors using `extra['isRetry']` flag
- Methods: `uploadFiles()`, `uploadDocument()`, `getVehicles()`, `getMyBookings()`, `createBooking()`, `createVehicle()`, `uploadVehicleDocument()`

---

### 8. `AuthService` — Service Class (NOT a widget)
- Static `currentToken` and `currentUser` — in-memory auth state
- `isAuthenticated` getter — checks token existence
- `verifyOtp()` syncs token to `CarApiService.token`
- `logout()` clears both static fields

---

## 🔧 Backend API — Module Breakdown

### Auth Module (`/api/auth`)
| Method | Endpoint | Auth Required | Description |
|--------|----------|--------------|-------------|
| POST | `/api/auth/send-otp` | No | Rate-limited OTP → SMS |
| POST | `/api/auth/verify-otp` | No | Verify OTP → JWT token |
| POST | `/api/auth/complete-profile` | Yes | Save full name |
| GET | `/api/auth/me` | Yes | Get logged-in user profile |

### Vehicles Module (`/api/vehicles`)
| Method | Endpoint | Auth Required | Description |
|--------|----------|--------------|-------------|
| GET | `/api/vehicles` | No | All active/available listings |
| GET | `/api/vehicles/:id` | No | Single vehicle detail |
| POST | `/api/vehicles` | Yes | Create listing |
| POST | `/api/vehicles/upload` | Yes | Multipart → Cloudinary |
| POST | `/api/vehicles/:id/documents` | Yes | Attach RC document URL |
| PATCH | `/api/vehicles/:id/availability` | Yes | Toggle available flag |

### Bookings Module (`/api/bookings`)
| Method | Endpoint | Auth Required | Description |
|--------|----------|--------------|-------------|
| POST | `/api/bookings` | Yes | Create booking (overlap check) |
| GET | `/api/bookings/my-bookings` | Yes | Renter's bookings |
| PATCH | `/api/bookings/:id/confirm` | Yes | Owner confirms |
| PATCH | `/api/bookings/:id/cancel` | Yes | Cancel with fee tiers |

### Locations Module (`/api/locations`)
| Method | Endpoint | Auth Required | Description |
|--------|----------|--------------|-------------|
| GET | `/api/locations/search?q=` | No | Google Maps place search |
| POST | `/api/locations/reverse-geocode` | No | lat/lng → address |
| GET | `/api/locations/popular` | No | Popular Indian cities |
| GET | `/api/locations/recent` | Yes | Recent searches |

---

## 📦 Flutter Packages Used

| Package | Version | Purpose |
|---------|---------|---------|
| `dio` | ^5.7.0 | HTTP client — interceptors, multipart, retry |
| `file_picker` | ^8.1.2 | Pick PDF/image files from device |
| `image_picker` | ^1.1.2 | Pick photos from gallery or camera |
| `google_maps_flutter` | ^2.14.2 | Google Maps embed |
| `geolocator` | ^14.0.2 | GPS device location |
| `http` | ^1.2.0 | Basic HTTP requests |
| `http_parser` | ^4.1.2 | MIME type detection for uploads |
| `cupertino_icons` | ^1.0.8 | iOS-style icon set |
| `flutter_lints` | ^6.0.0 | Dart lint rules |

---

## 📦 Backend Packages Used

| Package | Purpose |
|---------|---------|
| `express` | HTTP web framework |
| `@supabase/supabase-js` | Database client (PostgreSQL) |
| `cloudinary` | Image/file CDN storage SDK |
| `multer` | Multipart form data parser (memory storage) |
| `jsonwebtoken` | JWT signing and verification |
| `cors` | Cross-origin request headers |
| `dotenv` | .env environment variable loader |
| `jest` + `supertest` | Integration testing framework |

---

## 🔐 Authentication Flow

```
User taps "Rent Out" or "Book Now"
         │
         ▼
Is AuthService.isAuthenticated?
    ├── YES → proceed immediately
    └── NO  → AlertDialog: "Login / Register"
                    │
             AuthScreen shown
                    │
        [Step 1] Phone number entered
        POST /api/auth/send-otp
        OTP → SMS (or console in dev)
                    │
        [Step 2] 6-digit OTP entered
        Dev shortcut: 123456 bypasses API
        POST /api/auth/verify-otp
        Returns: { token, user, isNewUser }
                    │
        [Step 3 — new users only]
        Full name entered
        POST /api/auth/complete-profile
                    │
        AuthService.currentToken = token
        CarApiService.token = token  ← synced
                    │
        Navigator.pop(context, true)
        Parent screen resumes action
```

---

## ☁️ Image Upload Flow (Cloudinary)

```
User picks photos (image_picker / file_picker)
         │
XFile.readAsBytes() → Uint8List
         │
FormData with MultipartFile.fromBytes(bytes)
         │
Dio POST /api/vehicles/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data
         │
         ▼  (Backend)
Multer memoryStorage() — file in RAM buffer
         │
cloudinary.uploader.upload_stream(buffer)
  resource_type: 'auto', folder: 'vehicles'
         │
Returns: secure_url = "https://res.cloudinary.com/..."
         │
Response to Flutter: { success: true, data: [...URLs] }
         │
URLs saved in RentCarDraft.imageUrls[]
         │
createVehicle() sends URLs in JSON payload
Stored as TEXT[] in Supabase vehicles table
```

---

## 📅 Booking Flow

```
CarDetailScreen: user selects dates
         │
POST /api/bookings { vehicleId, startDate, endDate }
         │
Supabase INSERT attempted
         │
PostgreSQL EXCLUDE constraint checks:
  vehicle_id = same AND
  daterange(start_date, end_date, '[]') overlaps
         │
    ├── OVERLAP → 23P01 error → 409 Conflict returned
    └── NO OVERLAP → booking created → 201 Created
         │
Flutter shows success dialog
MyBookingsScreen lists booking (status: "pending")
Owner: PATCH /api/bookings/:id/confirm → "confirmed"
```

---

## 🔲 Widget Classification (Stateful vs Stateless)

| Widget / Class | Type | Why? |
|----------------|------|------|
| `MyApp` | StatelessWidget | Only configures MaterialApp — no internal state |
| `HomeScreen` | StatefulWidget | Tracks selected bottom nav tab index |
| `HomePage` | StatefulWidget | FutureBuilder: _vehiclesFuture changes on refresh |
| `AuthScreen` | StatefulWidget | 3-step form flow, OTP entered, loading state |
| `CarDetailScreen` | StatefulWidget | Date pickers, booking loading, success/error state |
| `MyBookingsScreen` | StatefulWidget | _bookingsFuture, refresh on pull |
| `CarSpecification` | StatefulWidget | Form key, dropdown values, text controllers |
| `CarImages` | StatefulWidget | Image list, upload progress double |
| `CarPricingAndAvailability` | StatefulWidget | Date state, price text controllers |
| `CarDocuments` | StatefulWidget | Picked file, upload state, final submit loading |
| `CarApiService` | Plain Dart class | Service — not a widget at all |
| `AuthService` | Plain Dart class | Service with static state fields |
| `VehicleModel` | Data class | PODO — maps draft to API payload |
| `AppColors` | Abstract class | Constant color tokens only |

---

## 🗄️ Database Design (Supabase/PostgreSQL)

### users table
```sql
id            UUID   PRIMARY KEY DEFAULT uuid_generate_v4()
phone_number  TEXT   UNIQUE NOT NULL
full_name     TEXT
created_at    TIMESTAMP DEFAULT NOW()
```

### vehicles table
```sql
id             UUID   PRIMARY KEY
owner_id       UUID   REFERENCES users(id)
brand          TEXT   NOT NULL
model          TEXT   NOT NULL
fuel_type      TEXT
transmission   TEXT
seats          INT
rc_number      TEXT   UNIQUE
city           TEXT
price_per_day  DECIMAL(10,2)
deposit        DECIMAL(10,2)
images         TEXT[]          -- Array of Cloudinary URLs
status         TEXT   DEFAULT 'under_review'
is_available   BOOLEAN DEFAULT true
created_at     TIMESTAMP DEFAULT NOW()
```

### vehicle_documents table
```sql
id             UUID   PRIMARY KEY
vehicle_id     UUID   REFERENCES vehicles(id)
document_type  TEXT   -- 'rc_certificate'
document_url   TEXT   -- Cloudinary secure_url
```

### bookings table
```sql
id             UUID   PRIMARY KEY
vehicle_id     UUID   REFERENCES vehicles(id)
renter_id      UUID   REFERENCES users(id)
start_date     DATE   NOT NULL
end_date       DATE   NOT NULL
total_price    DECIMAL(10,2)
deposit_amount DECIMAL(10,2)
status         TEXT   DEFAULT 'pending'
payment_status TEXT   DEFAULT 'unpaid'

-- Prevents double-booking at DB level:
EXCLUDE USING gist (
  vehicle_id WITH =,
  daterange(start_date, end_date, '[]') WITH &&
)
```

---

## 🚀 How to Run the Project

### Backend (Node.js Server)
```bash
cd server
npm install

# Create .env file:
# SUPABASE_URL=https://xxxx.supabase.co
# SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
# JWT_SECRET=your_secret_key
# CLOUDINARY_CLOUD_NAME=doymxkmea
# CLOUDINARY_API_KEY=...
# CLOUDINARY_API_SECRET=...

npm start          # starts on port 3000
npm run dev        # development with nodemon auto-reload
npm test           # run all 25 Jest tests
```

### Flutter App (Client)
```bash
cd client/car_rental_app_client_side

flutter pub get

flutter run              # prompts device selection
flutter run -d chrome    # web (Chrome)
flutter run -d edge      # web (Edge)
flutter build apk        # release APK for Android
```

---

## 💼 Interview Q&A Preparation

---

### Q: Describe this project in 2 sentences.
> **Rent-A-Car** is a full-stack Flutter + Node.js P2P car rental app where car owners list their vehicles with photos and pricing, and renters browse, view details, and book them. The backend uses Supabase (PostgreSQL) for data, Cloudinary for CDN image storage, JWT for authentication, and a PostgreSQL EXCLUDE constraint to prevent double-bookings.

---

### Q: What architecture pattern did you use in Flutter?
> **Feature-first clean architecture.** Each feature (auth, home, owner) has its own folder with:
> - `presentation/screens/` — UI widgets only
> - `data/services/` — API calls using Dio
> - `data/models/` — plain Dart data classes
>
> This keeps each layer independent and testable.

---

### Q: Why Dio instead of the http package?
> Dio supports **interceptors** — I use an `InterceptorsWrapper` to automatically attach the `Authorization: Bearer <token>` header to every request. Without interceptors, I'd have to repeat that in every single API call. Dio also natively supports multipart file uploads, configurable timeouts, and 1× retry on timeout — all essential for a production app uploading images.

---

### Q: How does OTP authentication work in this app?
> 1. User enters phone number → Flutter calls `POST /api/auth/send-otp`
> 2. Backend generates a 6-digit OTP, stores it in Supabase with a 10-minute expiry, sends via SMS
> 3. User enters OTP → Flutter calls `POST /api/auth/verify-otp`
> 4. Backend verifies, signs a JWT with `jsonwebtoken`, returns `{ token, user, isNewUser }`
> 5. Flutter stores the token in `AuthService.currentToken` (static field) and syncs it to `CarApiService.token` so the Dio interceptor can use it

---

### Q: StatefulWidget vs StatelessWidget — when do you use each?
> - **StatelessWidget** — when the widget only renders from its constructor props and never needs to update itself. `MyApp` is stateless — it just builds `MaterialApp`.
> - **StatefulWidget** — when the widget manages internal state that changes over time. `AuthScreen` is stateful because it tracks which of 3 steps the user is on, what they typed, and loading/error states. All screens with API calls (`FutureBuilder`) need `StatefulWidget` to trigger `setState()` on refresh.

---

### Q: How does Cloudinary image upload work end-to-end?
> 1. User picks image using `image_picker` → `XFile.readAsBytes()` returns `Uint8List`
> 2. Flutter wraps it in `MultipartFile.fromBytes()` inside `FormData`
> 3. Dio POSTs to `/api/vehicles/upload` with `Authorization` header
> 4. Backend's `multer.memoryStorage()` receives the file as an in-memory `Buffer` (never writes to disk)
> 5. Cloudinary's `upload_stream()` uploads the buffer directly to Cloudinary CDN
> 6. Returns `secure_url = "https://res.cloudinary.com/..."`
> 7. This URL is stored as a string in the `vehicles.images` TEXT[] column in Supabase

---

### Q: How does the 4-step Rent-Out wizard pass data between steps?
> All steps share a `RentCarDraft` — a plain Dart class that accumulates data. Each step receives the draft via `Navigator.pushNamed()` or is passed as a constructor argument. The final step (`CarDocuments`) serializes it using `VehicleModel.fromDraft(draft)` and calls `createVehicle()`.

---

### Q: How does double-booking prevention work?
> At the **PostgreSQL database level**, the `bookings` table has:
> ```sql
> EXCLUDE USING gist (vehicle_id WITH =, daterange(start, end, '[]') WITH &&)
> ```
> This means if you try to insert a booking for a car that already has a booking overlapping those dates, PostgreSQL itself rejects it with error code `23P01` (exclusion_violation). The backend catches this and returns a `409 Conflict` to Flutter, which shows "Car is not available for selected dates."

---

### Q: What was your biggest technical challenge?
> The **Android Gradle + file_picker upgrade conflict.** When I upgraded `file_picker` to v8 (needed for Flutter's V2 embedding), it required `compileSdk = 36`. But Gradle 8 (Kotlin DSL) doesn't allow calling `afterEvaluate {}` inside `subprojects {}` when the project is already evaluated — it crashes with "Cannot run Project.afterEvaluate(Action) when the project is already evaluated."
>
> I fixed it by adding a `project.state.executed` guard: if the project is already evaluated, apply the setting immediately; otherwise defer it with `afterEvaluate`. This resolved the Gradle lifecycle issue without downgrading any dependencies.

---

### Q: What testing did you write?
> **Backend (Jest + Supertest):** 25 integration tests across 3 test files covering the full OTP auth flow, vehicle CRUD with Cloudinary mocked, and booking creation with overlap conflict scenarios. All 25 pass.
>
> **Flutter (flutter_test):** 3 widget tests — HomeScreen renders without crashing (using mocked API), and `VehicleModel.fromDraft()` correctly maps all fields to the API payload format.

---

## 📁 Key Files Quick Reference

| File | Role |
|------|------|
| `client/lib/main.dart` | App entry, MaterialApp, auth guard dialog |
| `features/auth/presentation/screens/auth_screen.dart` | OTP 3-step UI |
| `features/auth/services/auth_service.dart` | JWT token storage + API |
| `features/owner/data/services/car_api_service.dart` | All REST calls via Dio |
| `features/home/presentation/screens/home_screen.dart` | Bottom nav tabs |
| `features/home/presentation/screens/car_detail_screen.dart` | Booking form |
| `features/home/presentation/screens/my_bookings_screen.dart` | Booking history |
| `features/owner/presentation/screens/rent_car/car_images.dart` | Photo upload |
| `server/src/app.js` | Express setup + routes |
| `server/src/modules/vehicles/vehicle.controller.js` | Cloudinary upload |
| `server/src/shared/middlewares/auth.middleware.js` | JWT verification |

---

## 🌐 Live Backend

**Base URL:** `https://carrental-application-z49a.onrender.com`  
**API Docs / Status:** `https://carrental-application-z49a.onrender.com/`

---

*Built with Flutter 3.x · Dart · Node.js 20 · Express.js · Supabase · Cloudinary · Deployed on Render*
