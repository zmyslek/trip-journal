# Travel Journal ✈️🌍  
A simple yet powerful Flutter app that lets users mark countries they've visited, highlight them on a map, and store personalized notes and photos.  

> Developed by [@zmyslek](https://github.com/zmyslek)

---

## 🗺️ Overview

Travel Journal is a visual and interactive travel log built with Flutter and Maplibre. It allows users to:

- Search for countries using MapTiler geocoding.
- Highlight countries they've visited.
- Add custom notes and attach photos to each visited country.
- View their travel history on a styled world map.

---

## 📸 Features

- 🌍 Interactive world map (powered by MapTiler + Maplibre)
- 🔍 Country search via geocoding API
- ✅ Mark countries as visited
- 🖼️ Add travel photos
- 📝 Write custom travel notes
- 💾 Local GeoJSON parsing for map overlay
- ✅ Toggle highlighting of visited countries

---

## 🚀 Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (3.x or newer)
- Android Studio or VS Code with Flutter plugin
- A [MapTiler](https://www.maptiler.com/cloud/) account (free tier is fine)

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/zmyslek/travel-journal.git
   cd travel-journal


2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Add your MapTiler API key:**

   Replace the value in `main.dart`:

   ```dart
   final String mapTilerKey = 'YOUR_MAPTILER_API_KEY';
   ```

4. **Add the countries GeoJSON file:**

   Ensure this file exists at:

   ```
   assets/countries.geojson
   ```

   Update `pubspec.yaml` accordingly:

   ```yaml
   flutter:
     assets:
       - assets/countries.geojson
   ```

5. **Run the app:**

   ```bash
   flutter run
   ```


## 📁 Project Structure

* `main.dart` – core UI and logic
* `assets/countries.geojson` – country polygon data
* Uses `maplibre_gl`, `dio`, `flutter/material.dart`


## 🌐 Map & API Attribution

This app uses:

* [Maplibre GL](https://maplibre.org/)
* [MapTiler](https://www.maptiler.com/) (Geocoding and map tiles)


## 🛠️ Planned Features

* Cloud sync with Firebase
* User authentication
* Custom travel tags (e.g., food, adventure)
* Timeline view of visits
* Export to PDF or image


## 📃 License

MIT License — feel free to fork and build on top of it!
Attribution to MapTiler and OpenStreetMap is required if using in production.


## 🙋‍♂️ Contact

Have feedback or want to collaborate?
Open an issue or reach out via [GitHub @zmyslek](https://github.com/zmyslek)
