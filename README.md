# Stark Group Vehicle Management System (VMS) — Frontend

## Project Overview
The Stark Group Vehicle Management System (VMS) is a Flutter Web application designed to manage company vehicles. It provides an interface for viewing, registering, updating, and deleting vehicle records.

## Features
- User Login and Authentication
- View Vehicle List
- Register New Vehicles
- Edit Vehicle Information
- Delete Vehicles
- Backend API Integration
- Loading and Error Handling
- Duplicate Vehicle Number Validation

## Technology Stack
- Flutter
- Dart
- REST API

## Backend Integration
The frontend communicates with a separate Java Spring Boot backend through REST APIs. Vehicle information is retrieved from and stored in a MySQL database through the backend.

## Run Locally

### Prerequisites
- Flutter SDK
- Dart SDK
- Google Chrome

### Setup
1. Clone this repository.
2. Open the project folder in a terminal.
3. Install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run -d chrome
```

## Project Structure
The project follows a feature-based Flutter structure, separating application configuration, models, services, routing, themes, and UI
## Related Repository

Backend: https://github.com/kabir-akib/vms-backend

---

Developed as part of the Stark Group Vehicle Management System project.
