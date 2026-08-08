# Booking API Contracts

This document outlines the API request and response JSON payloads for the Booking module.

## 1. Drivers List
* **Endpoint**: `GET /drivers`
* **Response Payload**:
```json
[
  {
    "id": "string",
    "name": "string",
    "rating": 4.9,
    "experienceYears": 8,
    "languages": ["string"],
    "isVerified": true,
    "pricePerDay": 25.0,
    "imageUrl": "string"
  }
]
```

## 2. Additional Services List
* **Endpoint**: `GET /services`
* **Response Payload**:
```json
[
  {
    "id": "string",
    "name": "string",
    "description": "string",
    "price": 15.0,
    "isReoccurring": true
  }
]
```

## 3. Apply Coupon
* **Endpoint**: `POST /coupons/validate`
* **Request Payload**:
```json
{
  "code": "DRIVE20",
  "bookingValue": 150.0
}
```
* **Response Payload**:
```json
{
  "valid": true,
  "coupon": {
    "code": "DRIVE20",
    "discountAmount": 0.0,
    "percentage": 20.0,
    "minBookingValue": 100.0,
    "description": "Save 20% on bookings above $100"
  }
}
```

## 4. Submit Booking
* **Endpoint**: `POST /bookings`
* **Request Payload**:
```json
{
  "vehicleId": "string",
  "pickupLocation": "string",
  "returnLocation": "string",
  "pickupDateTime": "ISO8601String",
  "returnDateTime": "ISO8601String",
  "rentalType": "selfDrive | withDriver",
  "driverId": "string | null",
  "serviceIds": ["string"],
  "couponCode": "string | null",
  "paymentMethod": "upi | creditCard | debitCard | wallet | netBanking",
  "totalPrice": 320.0
}
```
* **Response Payload**:
```json
{
  "id": "bk_87654321",
  "status": "confirmed",
  "invoiceUrl": "https://api.carrental.local/invoice/bk_87654321.pdf",
  "createdAt": "2026-08-04T12:00:00Z"
}
```

## 5. Cancel Booking
* **Endpoint**: `PATCH /bookings/:id/cancel`
* **Response Payload**:
```json
{
  "id": "bk_87654321",
  "status": "cancelled",
  "cancelledAt": "2026-08-08T11:09:00Z"
}
```

