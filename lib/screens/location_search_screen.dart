import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/theme/app_colors.dart';
import '../providers/customer_provider.dart';
import 'auth_wrapper.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;
  bool _isLocating = false;

  final List<String> _popularCities = [
    'Mumbai', 'Delhi-NCR', 'Bengaluru', 'Hyderabad', 
    'Chandigarh', 'Ahmedabad', 'Pune', 'Chennai', 
    'Kolkata', 'Kochi'
  ];

  // TODO: Replace with your actual Google Maps API Key from Google Cloud Console
  final String _googlePlacesApiKey = "AIzaSyCwEnmNo5y69fpp1eCZcUIXhypSkHJQ1FA";

  void _onSearchChanged(String query) async {
    if (query.isEmpty || query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // 1. Get Live Autocomplete Suggestions from Google Places API
      // types=(cities) ensures we ONLY get cities, towns, and villages - no streets or businesses!
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=${Uri.encodeComponent(query)}"
        "&types=(cities)"
        "&key=$_googlePlacesApiKey"
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && mounted) {
          final predictions = data['predictions'] as List;
          
          setState(() {
            _searchResults = predictions.map((p) {
              final description = p['description'] as String;
              final terms = p['terms'] as List;
              
              // Extract City and State roughly from terms
              String city = terms.isNotEmpty ? terms[0]['value'] : description;
              String state = terms.length > 1 ? terms[1]['value'] : '';
              
              return {
                'city': city,
                'state': state,
                'full_description': description, // We'll use this for the final geocoding
              };
            }).toList();
            _isSearching = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Autocomplete error: $e");
    }

    if (mounted) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectLocation(Map<String, String> location) async {
    setState(() => _isSaving = true);
    
    try {
      // 2. Use Native Geocoding (Free) on the selected Google Place Description
      // This saves you from having to pay for the Google Places Details API!
      final query = location['full_description'] ?? "${location['city']}, ${location['state']}";
      List<Location> locations = await locationFromAddress(query).timeout(const Duration(seconds: 5));
      
      if (locations.isNotEmpty) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations.first.latitude,
          locations.first.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _saveAndNavigate(
            city: place.locality ?? place.subAdministrativeArea ?? location['city'] ?? '',
            state: place.administrativeArea ?? location['state'] ?? '',
            country: place.country ?? '',
            pincode: place.postalCode ?? '',
            source: 'search',
          );
          return;
        }
      }
      throw 'Could not extract location details.';
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to get location details."), backgroundColor: AppColors.error)
        );
      }
    }
  }

  void _selectPopularCity(String city) {
    _searchController.text = city;
    _onSearchChanged(city);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) throw 'Could not get current location.';

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (!mounted) return;
        _saveAndNavigate(
          city: place.locality ?? place.subAdministrativeArea ?? '',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
          pincode: place.postalCode ?? '',
          source: 'gps',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _saveAndNavigate({
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String source,
  }) async {
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      await provider.updateLocation(
        city: city,
        state: state,
        country: country,
        pincode: pincode,
        source: source,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>().currentCustomer;
    final currentCity = customer?.city ?? "Select Location";
    final recents = customer?.recentLocations ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentCity,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search for your city",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
              ),
            ),
          ),
          
          // Auto Detect
          if (_searchController.text.isEmpty)
            ListTile(
              onTap: _isLocating ? null : _useCurrentLocation,
              leading: _isLocating 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta))
                  : const Icon(Icons.my_location, color: AppColors.terracotta),
              title: const Text(
                "Auto Detect My Location",
                style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.w500),
              ),
            ),

          if (_searchController.text.isEmpty)
            Container(height: 8, color: Colors.grey.shade100),

          Expanded(
            child: _searchController.text.isNotEmpty
                // SEARCH RESULTS VIEW
                ? (_isSearching 
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : _searchResults.isEmpty
                        ? Center(child: Text("No cities found", style: TextStyle(color: Colors.grey.shade600)))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final place = _searchResults[index];
                              return ListTile(
                                leading: const Icon(Icons.location_city, color: Colors.grey),
                                title: Text("${place['city']}${place['state'] != null && place['state']!.isNotEmpty ? ', ${place['state']}' : ''}"),
                                subtitle: place['full_description'] != null 
                                    ? Text(place['full_description']!, maxLines: 1, overflow: TextOverflow.ellipsis)
                                    : (place['pincode'] != null && place['pincode']!.isNotEmpty 
                                        ? Text(place['pincode']!) 
                                        : null),
                                onTap: () => _selectLocation(place),
                              );
                            },
                          ))
                
                // DEFAULT VIEW (Popular & Recents)
                : ListView(
                    children: [
                      // Popular Cities
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 16.0),
                        child: Text(
                          "POPULAR CITIES",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _popularCities.length,
                        itemBuilder: (context, index) {
                          final city = _popularCities[index];
                          final isSelected = city.toLowerCase() == currentCity.toLowerCase();
                          return InkWell(
                            onTap: () => _selectPopularCity(city),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_city_outlined, 
                                  size: 32, 
                                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade700
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isSelected)
                                      Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                                      ),
                                    Flexible(
                                      child: Text(
                                        city,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.black : Colors.grey.shade800,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      // Recent Locations
                      if (recents.isNotEmpty) ...[
                        Container(height: 8, color: Colors.grey.shade100, margin: const EdgeInsets.only(top: 16)),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
                          child: Text(
                            "RECENT LOCATIONS",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ),
                        ...recents.map((loc) => Column(
                          children: [
                            ListTile(
                              title: Text(loc['city'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              onTap: () {
                                _saveAndNavigate(
                                  city: loc['city']!,
                                  state: loc['state']!,
                                  country: loc['country']!,
                                  pincode: loc['pincode']!,
                                  source: 'recent',
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 16),
                          ],
                        )).toList(),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
