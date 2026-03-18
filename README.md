# BookEase — Appointment Booking App

A full-featured Flutter mobile application for booking clinic appointments, built as a portfolio project demonstrating production-level architecture, Firebase integration, and real-world booking system design.

## Screenshots

> Add 4–5 screenshots here: Home, Service Details, Booking Calendar, My Bookings, Profile

## Features

### Customer App
- 📅 **Smart Booking Flow** — Browse services, pick an available date and time slot, confirm appointment details
- 🔒 **Double-booking Prevention** — Transactional slot reservation using a `daily_slots` concurrency control document in Firestore
- 📋 **My Bookings** — View upcoming and past appointments, cancel confirmed bookings with automatic slot release
- 🔍 **Service Search** — Real-time client-side filtering of available clinic services
- 👤 **Profile Management** — Edit display name and profile photo (Firebase Storage), change password (email users only)
- 🌙 **Theme Support** — Light, dark, and system theme modes with persistent preference
- 🔐 **Authentication** — Email/password and Google Sign-In with secure session management

### Technical Highlights
- Slot generation algorithm that calculates availability in minutes-since-midnight, correctly handling back-to-back appointments and partial overlaps
- Firestore transactions for atomic booking creation and cancellation
- Role-aware UI (Google vs email/password users see different options)
- Auth-gated navigation with onboarding completion tracking via SharedPreferences

## Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter |
| State Management | flutter_bloc (Cubit) |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage) |
| UI | FlexColorScheme, ScreenUtil, GoogleNavBar |
| Utilities | intl, image_picker, image_cropper, shared_preferences, flutter_secure_storage |

## Architecture

The app follows **Clean Architecture** with a **feature-first** folder structure.
```
lib/
├── core/               # Shared infrastructure
│   ├── exceptions/     # Unified error types
│   ├── helpers/        # Utilities, validators, formatters
│   ├── models/         # Shared models (Booking, Service, Result)
│   ├── routing/        # GoRouter config and route names
│   ├── services/       # Firebase service abstractions
│   ├── theme/          # ThemeCubit and ThemeData
│   └── widgets/        # Shared UI components
│
└── features/
    ├── auth/           # Login, signup, Google Sign-In
    ├── booking/        # Booking wizard, slot generation, repository
    ├── home/           # Service catalog, search, service details
    ├── my_bookings/    # Booking history, cancellation
    ├── onboarding/     # First-launch carousel
    ├── profile/        # Account management, theme settings
    └── root/           # App shell, bottom nav, splash
```

### Key Patterns
- **Repository Pattern** — All Firestore and Auth operations are abstracted behind repository classes injected via `MultiBlocProvider`
- **Result\<T\>** — Every repository method returns a `Result<T>` (Success/Failure) ensuring no unhandled exceptions reach the UI layer
- **Cubit** — Lightweight state management with sealed state classes per feature
- **ShellRoute** — Booking flow shares a single `BookingCubit` instance across three screens via GoRouter's `ShellRoute`

## Screens

| Screen | Purpose |
|---|---|
| Splash | Boot gate, redirects based on auth and onboarding state |
| Onboarding | 3-slide first-launch walkthrough |
| Auth | Login / registration with Google Sign-In |
| Home | Service catalog with search |
| Service Details | Full service info with Book Now CTA |
| Booking Calendar | Date picker + dynamic time slot grid |
| Booking Details | Customer info form + booking summary |
| Booking Success | Confirmation receipt |
| My Bookings | Upcoming and past appointments |
| All Bookings | Full booking history list |
| Profile | Account info and settings |
| Edit Profile | Name and photo update |
| Change Password | Secure password update (email users only) |

## Firebase Setup

The app uses the following Firebase services:
- **Firebase Auth** — Email/password and Google Sign-In
- **Cloud Firestore** — Services catalog, bookings, clinic schedule, daily slot concurrency control, user profiles
- **Firebase Storage** — Profile photo uploads

### Firestore Collections
| Collection | Purpose |
|---|---|
| `users/{uid}` | User profile documents |
| `services/{id}` | Clinic service catalog |
| `clinic_schedule/{dayOfWeek}` | Working hours per day (1=Mon, 7=Sun) |
| `bookings/{id}` | Appointment records |
| `daily_slots/{date}` | Booked time intervals for concurrency control |

## Getting Started

### Prerequisites
- Flutter SDK
- Firebase project with Auth, Firestore, and Storage enabled
- `google-services.json` placed in `android/app/`

### Run the app
```bash
flutter pub get
flutter run
```

### Seed Firestore data
```bash
# Seed services and clinic schedule
dart run scripts/seed_services.dart
node scripts/seed_schedule.js
```

## Planned / Future Work
- 🖥️ **React Web Dashboard** — Staff-facing admin panel for managing appointments and marking completions (separate app, same Firebase project)
- 💳 **Payment Integration** — Stripe or PayPal checkout before booking confirmation
- 🔔 **Push Notifications** — Appointment reminders via Firebase Cloud Messaging