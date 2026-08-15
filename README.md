# 🚗 DriveX — Peer-to-Peer Car Rental Platform

A production-ready, full-stack **Peer-to-Peer (P2P) Car Rental Application** built with **Flutter (Mobile & Web)** and **Node.js / Express.js (Backend)** powered by **Supabase (PostgreSQL)**, **Cloudinary CDN**, **Razorpay**, and **Firebase (FCM & Auth)**.

---

## 🏗️ System Architecture

```
                       ┌──────────────────────────────────────┐
                       │       Flutter Mobile & Web App       │
                       │    (Dart / Material 3 / Provider)    │
                       └──────────────────┬───────────────────┘
                                          │
                                   HTTP / REST API (Dio)
                                          │
                                          ▼
                       ┌──────────────────────────────────────┐
                       │        Node.js + Express API         │
                       │       (Render.com / Express)         │
                       └──────┬───────────┬───────────┬───────┘
                              │           │           │
            ┌─────────────────┘           │           └──────────────────┐
            ▼                             ▼                              ▼
 ┌─────────────────────┐      ┌───────────────────────┐      ┌───────────────────────┐
 │ Supabase Database   │      │ Cloudinary CDN        │      │ Third-Party Services  │
 │ (PostgreSQL / RLS)  │      │ (Vehicle & Document)  │      │ - Razorpay Payment    │
 └─────────────────────┘      └───────────────────────┘      │ - Firebase FCM & Auth │
                                                             │ - Tesseract OCR       │
                                                             └───────────────────────┘
```

---

## 🔄 Step-by-Step Application Workflow

```
1. Authentication & Onboarding
   └─ Phone Number OTP Login/Registration ──► JWT Session Created & Securely Stored

2. Vehicle Exploration & Search
   └─ Search by City/Dates ──► Apply Filters (Fuel, Transmission, Seats, Price) ──► View Details & Reviews

3. Booking & Payment Execution
   └─ Select Start/End Dates ──► Overlap Validation ──► Razorpay Payment ──► Instant Reservation Created

4. Owner Car Hosting (Wizard)
   └─ Step 1: Specs ──► Step 2: Photos ──► Step 3: Pricing & Location ──► Step 4: RC Verification (OCR)

5. Trip Lifecycle & Tracking
   └─ Owner Approves Request ──► 4-Angle Car Photos Uploaded ──► Live GPS Tracking ──► Complete Trip & Review
```

---

## 🛠️ Implemented Features Breakdown

### 📱 Client Side (Flutter Application)

#### 1. Core & Network UX
- **Centralized Error Handling (`AppErrorHandler`)**: Automatically maps HTTP errors (400, 401, 403, 404, 409, 429, 500), timeout exceptions, and network failures into clean user messages while preserving detailed developer logs. Includes toast debouncing.
- **Real-Time Network Banner (`NetworkStatusService`)**: Monitored via `connectivity_plus`. Displays a subtle bottom banner when offline (*"No internet connection..."*) and a brief restored banner when online.

#### 2. Authentication Module
- Phone-based OTP Authentication (Send OTP & Verify OTP flow).
- Automatic JWT token management using `flutter_secure_storage`.
- Auto-login session restore on app restart.

#### 3. Vehicle Exploration & Search
- **Home Screen**: Featured offer carousel, category quick filters (SUV, Sedan, Luxury, Hatchback), popular cars grid, recommended cars, and "Why Choose Us" / "How It Works" sections.
- **Advanced Search Screen**: Interactive filters for city, price range slider, fuel type, transmission, seating capacity, and sorting options (Price Low-High, Rating).
- **Vehicle Detail Screen**: High-resolution image gallery, vehicle specifications, pricing breakdown, host profile card, customer reviews, and direct booking button.

#### 4. Booking & Reservation Flow
- **Reservation Screen**: Date range picker (Pickup & Return), automated total cost calculator (daily rate + service fee), and location selector.
- **Razorpay Payment Integration**: Integrated checkout screen supporting secure digital payments with instant transaction confirmation.
- **Renter Bookings (`MyBookingsScreen`)**: View active, upcoming, completed, and cancelled bookings with real-time status badges and instant trip cancellation option.

#### 5. Owner Vehicle Hosting (4-Step Wizard)
- **Step 1 — Car Specifications**: Brand, Model, Year, Fuel Type, Transmission, Seats, and Spec Features.
- **Step 2 — Vehicle Photos**: Multi-slot mandatory photo upload (Front, Back, Side, Interior) with image picker.
- **Step 3 — Pricing & Availability**: Daily rental price, security deposit, city/location, and initial availability toggle.
- **Step 4 — Document Verification**: RC book upload with automated OCR client/server document parsing.

#### 6. Host Vehicle & Request Management (`MyCarsScreen`)
- View hosted vehicles with instant availability toggle (Mark as Available / Unavailable).
- Manage incoming rental requests (Accept or Decline booking requests).
- Trip Execution Controls (Start Trip & Complete Trip buttons).

#### 7. Live GPS Tracking & Trip Verification (`BookingTrackingScreen`)
- Real-time GPS location tracking powered by `geolocator` and `flutter_map` (OpenStreetMap).
- Mandatory 4-angle vehicle condition photo upload before trip commencement.

#### 8. Wishlist & User Profile
- **Wishlist Management**: Toggle vehicle wishlist with persistent backend sync.
- **Profile Screen**: User avatar upload (Cloudinary CDN), profile detail editing (Name, Email), and settings.
- **Support & AI Assistant**: Help Center with FAQ accordions, terms/policies, customer support dialer/email launcher, and AI Assistant chat screen.

---

### ⚙️ Backend Side (Node.js & Express API)

#### 1. Authentication Service (`/api/auth`)
- `POST /api/auth/send-otp`: Sends 6-digit OTP code to specified phone number.
- `POST /api/auth/verify-otp`: Validates OTP code, registers/logs in user, and issues signed JWT token.
- `GET /api/auth/me`: Validates JWT header and returns current authenticated user details.

#### 2. Vehicles Service (`/api/vehicles`)
- `GET /api/vehicles`: Retrieves available cars with filtering (city, date range, price, fuel, transmission, seats).
- `GET /api/vehicles/:id`: Retrieves single vehicle details with populated owner profile and reviews.
- `POST /api/vehicles`: Creates a new vehicle listing (owner authorization required).
- `PATCH /api/vehicles/:id/availability`: Toggles vehicle booking availability.
- `POST /api/vehicles/upload`: Uploads vehicle images to Cloudinary CDN and returns secure URLs.

#### 3. Bookings Service (`/api/bookings`)
- `POST /api/bookings`: Creates a new booking request with double-booking overlap check (PostgreSQL EXCLUDE / date range query).
- `GET /api/bookings/my-bookings`: Fetches rental history for renter.
- `GET /api/bookings/my-cars/requests`: Fetches booking requests for car owners.
- `POST /api/bookings/:id/confirm`: Car owner accepts booking request.
- `POST /api/bookings/:id/decline`: Car owner declines booking request.
- `POST /api/bookings/:id/start`: Car owner/renter starts trip (initiates location tracking).
- `POST /api/bookings/:id/complete`: Completes trip and unlocks car review submission.
- `POST /api/bookings/:id/cancel`: Cancels reservation.
- `POST /api/bookings/:id/confirm-payment`: Confirms Razorpay transaction signature.

#### 4. Location Tracking Service (`/api/bookings/:id/location`)
- `POST /api/bookings/:id/location`: Receives periodic GPS coordinates from driver device.
- `GET /api/bookings/:id/location`: Serves latest vehicle GPS location coordinates for live map tracking.

#### 5. Documents & OCR Service (`/api/documents`)
- `POST /api/documents/verify-rc`: Parses RC document image/PDF via Multer + `pdf-parse` / `tesseract.js` OCR to extract Registration Number and Chassis Details.

#### 6. Wishlist, Reviews & Support Services
- `POST /api/wishlist/toggle`: Toggles vehicle in user's wishlist.
- `GET /api/wishlist`: Returns populated wishlist cars.
- `POST /api/reviews`: Submits vehicle rating (1-5 stars) and text review.
- `GET /api/support/details`: Returns customer support contact info and dynamic platform policies.

---

## 📂 Codebase Directory Structure

```
Carrental_Application/
├── client/
│   └── car_rental_app_client_side/
│       ├── lib/
│       │   ├── main.dart                          ← App entry & Global NetworkStatusBanner
│       │   ├── core/
│       │   │   ├── error_handling/
│       │   │   │   ├── app_error.dart             ← AppError model & AppErrorType enum
│       │   │   │   └── app_error_handler.dart     ← Centralized error & toast service
│       │   │   ├── network/
│       │   │   │   └── network_status.dart        ← Real-time internet connection listener
│       │   │   ├── theme/
│       │   │   │   └── app_colors.dart            ← Centralized color palette
│       │   │   └── notifications/
│       │   │       └── notification_service.dart  ← FCM Push notifications integration
│       │   └── features/
│       │       ├── auth/                          ← Phone OTP Authentication & Services
│       │       ├── home/                          ← Home, Details, Reserve, Payment, Bookings, Tracking
│       │       ├── owner/                         ← Rent Your Car 4-step wizard & Vehicle APIs
│       │       ├── search/                        ← Vehicle Search & Filter Bottom Sheet
│       │       ├── wishlist/                      ← Wishlist Controller & Screen
│       │       ├── profile/                       ← Profile & Settings Screens
│       │       └── support/                       ← Help Center & AI Assistant
│       └── pubspec.yaml                           ← Dependencies & Assets configuration
│
└── server/
    └── src/
        ├── server.js                              ← HTTP Server entry point
        ├── app.js                                 ← Express middleware & router setup
        ├── config/
        │   └── env.js                             ← Environment variables & Cloudinary setup
        ├── database/
        │   └── supabase.js                        ← Supabase client initialization
        └── modules/
            ├── auth/                              ← Auth controller & OTP logic
            ├── vehicles/                          ← Vehicle CRUD & Cloudinary controller
            ├── bookings/                          ← Booking engine & overlap protection
            ├── locations/                         ← GPS live tracking controller
            ├── documents/                         ← RC Document OCR verification
            ├── wishlist/                          ← Wishlist controller
            ├── reviews/                           ← Rating & Review controller
            └── support/                           ← Support & Policy controller
```

---

## 💻 Technical Stack Overview

| Layer | Technology / Package |
|-------|----------------------|
| **Mobile & Web App** | Flutter (Dart SDK `>=3.9.0 <4.0.0`) |
| **State & Interceptors**| Provider, Dio Interceptors |
| **Connectivity** | `connectivity_plus: ^6.1.3` |
| **Maps & GPS** | `flutter_map: ^7.0.2`, `latlong2: ^0.9.1`, `geolocator: ^14.0.2` |
| **Payments** | `razorpay_flutter: ^1.4.5` |
| **Secure Storage** | `flutter_secure_storage: ^9.2.2` |
| **Media Handling** | `image_picker: ^1.1.2`, `cached_network_image: ^3.4.1` |
| **Backend Framework** | Node.js (Express.js) |
| **Database** | Supabase (PostgreSQL) |
| **Media CDN** | Cloudinary API |
| **Push Notifications** | Firebase Admin SDK & Firebase Messaging |
| **OCR / PDF Parsing** | `tesseract.js`, `pdf-parse` |

---

## 🚀 How to Run the Project

### 1. Backend Setup (Node.js)

```bash
# Navigate to server directory
cd server

# Install dependencies
npm install

# Configure Environment Variables (.env)
# SUPABASE_URL=...
# SUPABASE_ANON_KEY=...
# CLOUDINARY_CLOUD_NAME=...
# CLOUDINARY_API_KEY=...
# CLOUDINARY_API_SECRET=...
# JWT_SECRET=...

# Start development server
npm run dev
```

### 2. Frontend Setup (Flutter)

```bash
# Navigate to Flutter client directory
cd client/car_rental_app_client_side

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```
