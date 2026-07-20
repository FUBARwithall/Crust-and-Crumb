# Crust & Crumb - Artisanal Bakery & Pastry Mobile App

**Crust & Crumb** is a Flutter mobile application built with the **GetX Pattern** architecture, featuring live REST API pastry fetching, smartphone GPS location tagging, dual-identifier authentication (with guest mode), profile management, and a real-time admin order dashboard with Google Maps integration.

---

## Key Features

- **GetX Pattern Architecture**: Clean modular structure (`views`, `controllers`, `bindings`, `routes`, `data`).
- **Live Pastry REST API Integration**: Dynamic fetching from **TheMealDB** (`/filter.php?c=Dessert`) with automatic category classification (`Roti` / `Kue`), star ratings (`⭐ 4.9`), prep time badges (`⏱️ 15 mnt`), and offline mode fallback.
- **Interactive Product Detail Sheet**: Bottom sheet modal displaying HD imagery, origin tags, ingredient highlights (*100% Organik*, *Ragi Alami*, *Bebas Pengawet*), and quantity selector stepper.
- **Smartphone GPS Location Tagging**: Uses `geolocator` and `permission_handler` to capture exact delivery coordinates (Latitude & Longitude).
- **Authentication & Guest Mode**: Supports registration (Username, Email, Password, Confirmation), dual-identifier login (Username or Email), and instant Guest login.
- **Profile Management**: Profile page to configure email, username, phone number, and password.
- **Admin Dashboard & Google Maps Integration**: Admin order view tracking incoming orders and launching delivery locations directly in Google Maps via `url_launcher`.
- **60 FPS Performance Optimizations**: Bounded memory image decoding (`memCacheWidth: 300`), disk caching with `cached_network_image`, 250ms search debouncing, and isolated reactive rebuild scope.

---

## Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management & Routing**: `get: ^4.6.6`
- **Session & Storage Persistence**: `get_storage: ^2.1.1`
- **Location Services**: `geolocator: ^13.0.4` & `permission_handler: ^11.4.0`
- **HTTP Client**: `http: ^1.6.0`
- **Image Caching**: `cached_network_image: ^3.4.1`
- **External URL Launcher**: `url_launcher: ^6.3.1`

---

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/FUBARwithall/Crust-and-Crumb.git
   cd Crust-and-Crumb
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```
