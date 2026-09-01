import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

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
        "&key=$_googlePlacesApiKey",
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
                'full_description':
                    description, // We'll use this for the final geocoding
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
      final query =
          location['full_description'] ??
          "${location['city']}, ${location['state']}";
      List<Location> locations = await locationFromAddress(
        query,
      ).timeout(const Duration(seconds: 5));

      if (locations.isNotEmpty) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations.first.latitude,
          locations.first.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _saveAndNavigate(
            city:
                place.locality ??
                place.subAdministrativeArea ??
                location['city'] ??
                '',
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
          const SnackBar(
            content: Text("Failed to get location details."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Location permissions are denied';
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

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
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
      Navigator.pop(context); // Gracefully return to the Home Screen
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "Delivery Location",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              currentCity,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search for your city...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.primaryGreen.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Auto Detect
              if (_searchController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLocating ? null : _useCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.15),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen.withOpacity(0.02),
                              AppColors.primaryGreen.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGreen.withOpacity(
                                      0.1,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isLocating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryGreen,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_rounded,
                                      color: AppColors.primaryGreen,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Auto Detect Location",
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      fontFamily: GoogleFonts.plusJakartaSans()
                                          .fontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Using GPS",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: _searchController.text.isNotEmpty
                    // SEARCH RESULTS VIEW
                    ? (_isSearching
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryGreen,
                              ),
                            )
                          : _searchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off_rounded,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No cities found",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 40,
                              ),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 64,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (context, index) {
                                final place = _searchResults[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    "${place['city']}${place['state'] != null && place['state']!.isNotEmpty ? ', ${place['state']}' : ''}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      fontFamily: GoogleFonts.plusJakartaSans()
                                          .fontFamily,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: place['full_description'] != null
                                        ? Text(
                                            place['full_description']!,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : (place['pincode'] != null &&
                                                  place['pincode']!.isNotEmpty
                                              ? Text(
                                                  place['pincode']!,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 13,
                                                  ),
                                                )
                                              : null),
                                  ),
                                  onTap: () => _selectLocation(place),
                                );
                              },
                            ))
                    // DEFAULT VIEW (Recents)
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 40),
                        children: [
                          // Recent Locations
                          if (recents.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24.0,
                                32.0,
                                24.0,
                                12.0,
                              ),
                              child: Text(
                                "RECENT LOCATIONS",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontFamily:
                                      GoogleFonts.plusJakartaSans().fontFamily,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade100,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: recents.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    indent: 56,
                                    color: Colors.grey.shade100,
                                  ),
                                  itemBuilder: (context, index) {
                                    final loc = recents[index];
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.history_rounded,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      title: Text(
                                        loc['city'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          fontFamily:
                                              GoogleFonts.plusJakartaSans()
                                                  .fontFamily,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        loc['state'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      onTap: () {
                                        _saveAndNavigate(
                                          city: loc['city']!,
                                          state: loc['state']!,
                                          country: loc['country']!,
                                          pincode: loc['pincode']!,
                                          source: 'recent',
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),

          if (_isSaving)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }
}
