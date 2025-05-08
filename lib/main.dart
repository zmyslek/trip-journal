import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late MaplibreMapController mapController;
  final SearchController searchController = SearchController();
  final Dio _dio = Dio();
  final String mapTilerKey = 'FelxstvCdS6k0g9YnLdK';
  final List<Map<String, dynamic>> selectedCountries = [];
  bool highlightEnabled = false;
  bool isMapReady = false;
  Map<String, dynamic>? countriesGeoJson;

  @override
  void initState() {
    super.initState();
    _loadCountriesGeoJson();
  }

  Future<void> _loadCountriesGeoJson() async {
    try {
      final data = await rootBundle.loadString('assets/countries.geojson');
      countriesGeoJson = json.decode(data);
    } catch (e) {
      debugPrint('Error loading GeoJSON: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    if (query.isEmpty) return [];

    try {
      // First try searching in local GeoJSON
      final localResults = _searchInLocalGeoJson(query);
      if (localResults.isNotEmpty) return localResults;

      // Fall back to API search if no local results
      return await _searchViaApi(query);
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchViaApi(String query) async {
    final response = await _dio.get(
      'https://api.maptiler.com/geocoding/$query.json',
      queryParameters: {
        'key': mapTilerKey,
        'types': 'country',
        'limit': 5,
      },
    );

    return List<Map<String, dynamic>>.from(response.data['features'].map((feature) {
      feature['id'] = feature['properties']?['country_code'] ??
          feature['properties']?['iso_3166_1_alpha2'];
      return feature;
    }).toList());
  }

  List<Map<String, dynamic>> _searchInLocalGeoJson(String query) {
    if (countriesGeoJson == null) return [];

    final lowerQuery = query.toLowerCase();
    return (countriesGeoJson!['features'] as List).where((feature) {
      final name = feature['properties']['name']?.toString().toLowerCase() ?? '';
      final code = feature['properties']['ISO3166-1-Alpha-2']?.toString().toLowerCase() ?? '';
      return name.contains(lowerQuery) || code.contains(lowerQuery);
    }).map((feature) {
      return {
        'id': feature['properties']['ISO3166-1-Alpha-2'],
        'place_name': feature['properties']['name'],
        'geometry': feature['geometry'],
        'properties': feature['properties'],
      };
    }).toList();
  }

  void moveCameraToLocation(Map<String, dynamic> feature) {
    if (!isMapReady) return;
    final geometry = feature['geometry'];
    if (geometry == null) return;

    // Handle both Point and Polygon geometries
    List coordinates;
    if (geometry['type'] == 'Point') {
      coordinates = geometry['coordinates'];
    } else {
      // For polygons, use the first coordinate of the first polygon
      coordinates = geometry['coordinates'][0][0];
    }

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(coordinates[1], coordinates[0]),
        4.0,
      ),
    );
  }

  Future<void> toggleCountryHighlight(Map<String, dynamic> country) async {
    if (!isMapReady) return;

    setState(() {
      if (selectedCountries.any((c) => c['id'] == country['id'])) {
        selectedCountries.removeWhere((c) => c['id'] == country['id']);
      } else {
        selectedCountries.add(country);
      }
    });

    if (highlightEnabled) {
      await _updateHighlightedCountries();
    }
  }

  Future<void> _updateHighlightedCountries() async {
    if (!isMapReady || !highlightEnabled || countriesGeoJson == null) return;

    try {
      try {
        await mapController.removeLayer('countries-highlight-layer');
        await mapController.removeSource('countries-highlight-source');
      } catch (e) {
        debugPrint('Error removing existing layers: $e');
      }

      if (selectedCountries.isEmpty) return;

      final selectedFeatures = (countriesGeoJson!['features'] as List).where((feature) {
        final countryCode = feature['properties']['ISO3166-1-Alpha-2'];
        return selectedCountries.any((c) => c['id']?.toLowerCase() == countryCode?.toLowerCase());
      }).toList();

      if (selectedFeatures.isEmpty) return;

      final featureCollection = {
        'type': 'FeatureCollection',
        'features': selectedFeatures,
      };

      await mapController.addSource(
        'countries-highlight-source',
        GeojsonSourceProperties(data: featureCollection),
      );

      await mapController.addFillLayer(
        'countries-highlight-source',
        'countries-highlight-layer',
        FillLayerProperties(
          fillColor: '#ff69b4',
          fillOpacity: 1,
          fillOutlineColor: '#ff1493',
        ),
      );
    } catch (e) {
      debugPrint('Error highlighting countries: $e');
    }
  }

  Future<void> toggleHighlightEnabled() async {
    setState(() {
      highlightEnabled = !highlightEnabled;
    });
    await _updateHighlightedCountries();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Trip journal')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: SearchAnchor(
                      searchController: searchController,
                      builder: (BuildContext context, SearchController controller) {
                        return SearchBar(
                          controller: controller,
                          padding: const MaterialStatePropertyAll<EdgeInsets>(
                            EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          onTap: () => controller.openView(),
                          onChanged: (_) => controller.openView(),
                          leading: const Icon(Icons.search),
                        );
                      },
                      suggestionsBuilder: (BuildContext context, SearchController controller) async {
                        final query = controller.value.text;
                        if (query.isEmpty) {
                          return [const Center(child: Text('Start typing to search for countries'))];
                        }

                        // Show loading indicator by returning a temporary widget
                        final loadingWidget = const Center(child: CircularProgressIndicator());

                        // Get the actual results
                        final results = await searchLocations(query);

                        if (results.isEmpty) {
                          return [const ListTile(title: Text('No countries found'))];
                        }

                        return results.map((country) {
                          final isSelected = selectedCountries.any((c) => c['id'] == country['id']);
                          return ListTile(
                            title: Text(country['place_name'] ?? 'Unknown Country'),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) async {
                                await toggleCountryHighlight(country);
                                controller.closeView(country['place_name'] ?? 'Country');
                              },
                            ),
                            onTap: () async {
                              moveCameraToLocation(country);
                              if (highlightEnabled) {
                                await toggleCountryHighlight(country);
                              }
                              controller.closeView(country['place_name'] ?? 'Country');
                            },
                          );
                        }).toList();
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      highlightEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                      color: highlightEnabled ? Colors.pink : null,
                    ),
                    onPressed: toggleHighlightEnabled,
                    tooltip: 'Toggle highlighting',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: MaplibreMap(
                styleString: 'https://api.maptiler.com/maps/0196a72c-f543-7d0f-a1dd-d13762e765b7/style.json?key=$mapTilerKey',
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 1,
                ),
                onMapCreated: (controller) async {
                  mapController = controller;
                  isMapReady = true;
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (highlightEnabled && selectedCountries.isNotEmpty) {
                    await _updateHighlightedCountries();
                  }
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: selectedCountries.length,
                itemBuilder: (context, index) {
                  final country = selectedCountries[index];
                  return ListTile(
                    title: Text(country['place_name'] ?? 'Unknown Country'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => toggleCountryHighlight(country),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}