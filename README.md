# Crust & Crumb - Artisanal Bakery & Pastry Mobile App

**Crust & Crumb** is a Flutter mobile application built with the **GetX Pattern** architecture, powered by a **Laravel REST API** backend connected to a **Supabase PostgreSQL** database. Features include live product catalog fetching, OpenStreetMap location picker with autocomplete search, GPS delivery tagging, dual-identifier authentication, Shopee-style profile management, digital receipt generation with BMP export, and SQLite offline storage.

---

## Key Features

- **GetX Pattern Architecture**: Clean modular structure (`views`, `controllers`, `bindings`, `routes`, `data/models`, `data/services`, `data/helpers`, `data/utils`).
- **Laravel REST API Backend**: All product catalogs, user authentication, and order transactions are managed through a Laravel server API (`/api/products`, `/api/orders`, `/api/login`, `/api/register`).
- **SQLite Offline Database Storage**: Product catalogs and order history are cached locally in a SQLite database (`bakery_app.db`) via `sqflite`. When the network is unavailable, the app seamlessly falls back to loading data from SQLite.
- **GetStorage Key-Value Persistence**: Lightweight session storage for active user data and shopping cart state.
- **OpenStreetMap Location Picker**: Interactive map canvas (`flutter_map`) with Google-style live autocomplete search using Nominatim API (350ms debounced, 3-character minimum threshold).
- **Smartphone GPS Location Tagging**: Uses `geolocator` to capture exact delivery coordinates (Latitude & Longitude) with GPS status badge overlay.
- **Authentication & Guest Mode**: Supports registration (Username, Email, Password, Confirmation), dual-identifier login (Username or Email), and instant Guest login — all validated against the Laravel backend with bcrypt hashed passwords.
- **Shopee-Style Profile & Settings**: Grouped account settings layout (*My Account*, *Settings*, *Support*) with modal bottom sheets for editing profile, changing password, and selecting language.
- **Digital Receipt & BMP Export**: Thermal-style receipt cards with barcode simulation, LUNAS/PAID stamp, and downloadable BMP image export via cross-platform conditional imports.
- **60 FPS Performance Optimizations**: Bounded memory image decoding (`memCacheWidth: 300`), disk caching with `cached_network_image`, 250ms search debouncing, and isolated reactive rebuild scope.

---

## Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management & Routing**: `get: ^4.7.3`
- **Local Database (Offline)**: `sqflite: ^2.4.1` & `path: ^1.9.1`
- **Key-Value Storage**: `get_storage: ^2.1.1`
- **HTTP Client**: `http: ^1.6.0`
- **Location Services**: `geolocator: ^14.0.3`
- **Map Display**: `flutter_map: ^7.0.2` & `latlong2: ^0.9.1`
- **Image Caching**: `cached_network_image: ^3.4.1`

---

## Project Structure

```
lib/
├── main.dart                          # App entry point & service initialization
├── app/
│   ├── data/
│   │   ├── helpers/
│   │   │   └── database_helper.dart   # SQLite database singleton (products & orders tables)
│   │   ├── models/
│   │   │   ├── bakery_item.dart       # BakeryItem model with category enum
│   │   │   ├── order_model.dart       # OrderModel + OrderCartItem with JSON serialization
│   │   │   └── user_model.dart        # UserModel (no plaintext password storage)
│   │   ├── services/
│   │   │   ├── auth_service.dart      # Authentication (login, register, profile update)
│   │   │   └── order_service.dart     # Product fetching, order management, SQLite caching
│   │   └── utils/
│   │       ├── app_config.dart        # Centralized API base URL constant
│   │       ├── app_snackbar.dart      # Themed snackbar utility (success/error/warning/info)
│   │       ├── download_helper.dart   # Conditional import bridge (web vs mobile)
│   │       ├── download_helper_stub.dart  # Non-web stub (no-op)
│   │       └── download_helper_web.dart   # Web implementation (dart:html Blob download)
│   ├── modules/
│   │   ├── auth/                      # Login & Register views + controllers
│   │   ├── catalog/                   # Product catalog with search & cart
│   │   ├── checkout/                  # Checkout with OpenStreetMap & GPS
│   │   ├── dashboard/                 # Bottom navigation tab controller
│   │   └── profile/                   # Profile settings, receipts, receipt card widget
│   └── routes/
│       ├── app_pages.dart             # GetX route definitions
│       └── app_routes.dart            # Route path constants
```

---

## Local Storage Architecture

| Data | Storage Engine | Rationale |
| :--- | :--- | :--- |
| **Product Catalog** | SQLite (`products` table) | Structured relational data, offline cache |
| **Order History** | SQLite (`orders` table) | Structured relational data, offline receipts |
| **User Session** | GetStorage (`current_user` key) | Lightweight key-value, fast app launch |
| **Shopping Cart** | GetStorage (`cart` key) | Ephemeral state, small payload |

---

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/FUBARwithall/Crust-and-Crumb.git
   cd Crust-and-Crumb
   ```

2. **Start the Laravel backend server**:
   ```bash
   cd server
   php artisan serve
   ```

3. **Install Flutter dependencies**:
   ```bash
   cd junior_mobile_programmer
   flutter pub get
   ```

4. **Run the application**:
   ```bash
   flutter run -d chrome
   ```

> **Note**: For Android Emulator, change `AppConfig.baseUrl` in `lib/app/data/utils/app_config.dart` from `http://127.0.0.1:8000/api` to `http://10.0.2.2:8000/api`.
