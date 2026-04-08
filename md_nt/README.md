# MediTrack

MediTrack is a mobile health management application built with a Flutter Android client and a Node.js/Express backend using PostgreSQL. The project brings together personal medical record management and reminder features in one app.

## Features

- User registration and login
- Password recovery using a security question
- Upload and store scanned medical reports
- View, edit, delete, and organize reports
- Export reports to PDF
- Medicine reminders with multiple daily timings
- Appointment reminders with calendar support

## Project Structure

```text
MAD/
|-- md_nt/      Flutter mobile application
`-- backend/    Node.js + Express backend
```

## Tech Stack

### Frontend

- Flutter
- Dart
- SharedPreferences
- Image Picker
- PDF and Share packages

### Backend

- Node.js
- Express
- Sequelize
- PostgreSQL
- Multer
- JWT
- bcryptjs

## Main Files

### Flutter

- `md_nt/lib/main.dart`
- `md_nt/lib/config.dart`
- `md_nt/lib/home/dashboard.dart`
- `md_nt/lib/home/report_gallery_page.dart`
- `md_nt/lib/home/medicine_reminder.dart`
- `md_nt/lib/home/appointment_reminder.dart`

### Backend

- `backend/server.js`
- `backend/src/config/database.js`
- `backend/src/controllers/authController.js`
- `backend/src/models/user.js`
- `backend/src/models/report.js`
- `backend/src/routes/authRoutes.js`

## Setup

### 1. Database

Make sure PostgreSQL is running and create a database named `flutter_backend`.

Database configuration is in:

- `backend/src/config/database.js`

### 2. Start the Backend

```powershell
cd backend
npm install
npm run dev
```

Backend runs on:

- `http://localhost:5000`

### 3. Configure the Flutter App

Update the backend IP in:

- `md_nt/lib/config.dart`

Example:

```dart
static const String ipAddress = 'YOUR_PC_IP';
static const String baseUrl = 'http://$ipAddress:5000/api/auth';
```

Your phone and PC should be connected to the same Wi-Fi or hotspot.

### 4. Run the Flutter App

```powershell
cd md_nt
flutter pub get
flutter run
```

If Android build cache causes problems:

```powershell
flutter clean
flutter pub get
flutter run
```

## API Endpoints

Authentication routes are available under:

- `/api/auth`

Important endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/get-security-question`
- `POST /api/auth/reset-password`
- `GET /api/auth/reports/:userId`
- `POST /api/auth/add-report`
- `PUT /api/auth/reports/:id`
- `DELETE /api/auth/reports/:id`

Uploaded report images are served from:

- `/uploads/...`

## Android Notes

For reminder features to work properly on a real Android device:

- allow notifications
- allow lock-screen notifications
- disable battery optimization for the app if needed
- allow background activity or auto-start on restrictive Android skins

## Current Limitations

- Backend secrets and database credentials are still stored in source files
- Flutter API configuration depends on a manually updated local IP address
- There is no full automated test suite yet
- Uploaded report files are stored locally on the backend filesystem

## Future Improvements

- Move secrets and database configuration into environment variables
- Add stronger route protection and validation
- Add automated tests
- Add cloud backup or sync support
- Improve configuration for easier deployment

