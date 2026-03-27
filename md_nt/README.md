# MediTrack

MediTrack is a mobile health management project built with a Flutter Android client and a Node.js/Express backend backed by PostgreSQL. The app focuses on three practical workflows:

- user authentication
- medical report storage and export
- medicine reminder alarms

## Repository Layout

```text
MAD/
├─ md_nt/      # Flutter mobile app
└─ backend/    # Node.js + Express + Sequelize API
```

## What The Project Does

### Flutter app

The mobile app lets a user:

- register, log in, and reset a password with a security question
- upload scanned medical reports with doctor, hospital, date, and disease details
- browse, edit, delete, and export saved reports
- create medicine reminders with Android-native alarm behavior

Main Flutter entry points:

- `md_nt/lib/main.dart`
- `md_nt/lib/home/dashboard.dart`
- `md_nt/lib/home/report_gallery_page.dart`
- `md_nt/lib/home/medicine_reminder.dart`

### Backend

The backend provides:

- authentication APIs
- report upload and retrieval APIs
- PostgreSQL persistence through Sequelize
- static file serving for uploaded report images

Main backend entry points:

- `backend/server.js`
- `backend/src/controllers/authController.js`
- `backend/src/models/user.js`
- `backend/src/models/report.js`
- `backend/src/routes/authRoutes.js`

## Current Feature Summary

### Authentication

- Register a user
- Log in and persist token locally
- Forgot-password flow using a security question and answer

### Medical reports

- Upload reports with image, doctor, hospital, report date, and disease
- View reports by user
- Edit report metadata
- Delete reports
- Export grouped reports to PDF

### Medicine reminders

- Add multiple daily reminder times for a medicine
- Edit and delete reminders
- Snooze reminders
- Trigger Android alarm-style reminders with ringtone and lock-screen support
- Restore alarms after reboot

### Appointment reminders

- `md_nt/lib/home/appointment_reminder.dart` exists in the codebase
- it is currently not wired into the main dashboard flow

## Tech Stack

### Mobile

- Flutter
- Dart
- SharedPreferences
- Image Picker
- PDF export and sharing packages

### Backend

- Node.js
- Express
- Sequelize
- PostgreSQL
- Multer
- JWT
- bcryptjs

## How To Run

### 1. Start PostgreSQL

Make sure PostgreSQL is running and a database named `flutter_backend` exists.

Current backend DB config is in:

- `backend/src/config/database.js`

### 2. Start the backend

```powershell
cd backend
npm install
npm.cmd run dev
```

The backend runs on:

- `http://localhost:5000`

### 3. Point the Flutter app to your PC IP

Update the IP in:

- `md_nt/lib/config.dart`

Current format:

```dart
static const String ipAddress = 'YOUR_PC_IP';
static const String baseUrl = 'http://$ipAddress:5000/api/auth';
```

Your phone and PC must be on the same Wi-Fi or hotspot.

### 4. Run the Flutter app

```powershell
cd md_nt
flutter pub get
flutter run
```

For native Android alarm changes, prefer a full rebuild:

```powershell
flutter clean
flutter run
```

## Important Android Notes

For medicine alarms to work reliably on a real device:

- allow notifications for the app
- allow lock-screen notifications
- disable battery optimization for the app
- enable auto-start or background activity if your phone brand requires it

This matters especially on Vivo, Oppo, Xiaomi, and similar Android skins.

## API Overview

Authentication routes are mounted under:

- `/api/auth`

Important endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/forgot-password/question`
- `POST /api/auth/forgot-password/reset`
- `GET /api/auth/reports/:userId`
- `POST /api/auth/add-report`
- `PUT /api/auth/reports/:id`
- `DELETE /api/auth/reports/:id`

Uploaded report files are served from:

- `/uploads/...`

## Project Structure Details

### Flutter

```text
md_nt/lib/
├─ authentication/
│  ├─ login_page.dart
│  └─ register_page.dart
├─ home/
│  ├─ dashboard.dart
│  ├─ add_report_page.dart
│  ├─ report_gallery_page.dart
│  ├─ medicine_reminder.dart
│  └─ appointment_reminder.dart
├─ services/
│  └─ notification_service.dart
├─ config.dart
├─ forgot_password_page.dart
└─ main.dart
```

### Backend

```text
backend/
├─ server.js
├─ src/
│  ├─ config/database.js
│  ├─ controllers/
│  ├─ middleware/
│  ├─ models/
│  └─ routes/
└─ uploads/
```

## Current Limitations

- backend secrets and DB credentials are still hardcoded in source
- Flutter API base URL depends on a manually updated local IP address
- there is no proper automated test suite yet
- `sequelize.sync({ alter: true })` is convenient for development but risky for production
- backend contains some duplicate/legacy structure such as `backend/src/app.js`

## Recommended Next Improvements

- move backend secrets and DB credentials into environment variables
- replace hardcoded Flutter IP configuration with a safer runtime configuration
- add backend validation and auth middleware to report routes
- add tests for authentication, report APIs, and reminder flows
- integrate appointment reminders into the dashboard if that feature should ship

## Development Notes

- the project is currently Android-first for the alarm experience
- report export is implemented in the Flutter client
- uploaded images are stored on the backend filesystem, not cloud storage

## License

No license has been defined yet in this repository.
