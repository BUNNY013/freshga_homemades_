import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_colors.dart';
import '../providers/customer_provider.dart';
import 'auth_wrapper.dart';
import 'location_search_screen.dart';
import '../core/constants/lottie_constants.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  bool _isLocating = true; // Start in loading state immediately
  bool _locationSuccess = false; // To show success animation briefly
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Delay slightly to let the UI render the loading state first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _useCurrentLocation();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = '';
    });

    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      // Get location with timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Fallback to last known position if current position times out
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        throw 'Could not get current location. Please ensure location is enabled on your device or try searching manually.';
      }

      // Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (!mounted) return;

        // Show success briefly
        setState(() {
          _isLocating = false;
          _locationSuccess = true;
        });

        // Save location
        final provider = Provider.of<CustomerProvider>(context, listen: false);
        await provider.updateLocation(
          city: place.locality ?? place.subAdministrativeArea ?? '',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
          pincode: place.postalCode ?? '',
          source: 'gps',
        );

        // Wait a tiny bit for the user to see the "Success" state
        await Future.delayed(const Duration(milliseconds: 1500));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      } else {
        throw 'Could not determine location from coordinates.';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocating || _locationSuccess) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: _locationSuccess
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primaryGreen,
                        size: 64,
                      )
                    : const CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                        strokeWidth: 3,
                      ),
              ),
              const SizedBox(height: 32),
              Text(
                _locationSuccess
                    ? "Location Found!"
                    : "Finding your location...",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!_locationSuccess)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    "We need this to show available brands near you",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // MANUAL FALLBACK UI (Premium White/Green)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () async {
            // Treat as skipped
            final provider = Provider.of<CustomerProvider>(
              context,
              listen: false,
            );
            await provider.updateLocation(
              city: 'Select Location',
              state: '',
              country: '',
              pincode: '',
              source: 'skipped',
            );
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "Where are you\nlocated?",
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  height: 1.2,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "We couldn't automatically find your location. Please enter it manually to discover amazing homemade foods nearby.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Search Button (Looks like a text field)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LocationSearchScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.primaryGreen),
                      const SizedBox(width: 12),
                      Text(
                        "Search City or Pincode...",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Retry Current Location
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(
                    Icons.my_location,
                    color: AppColors.primaryGreen,
                  ),
                  label: const Text(
                    "Retry Current Location",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              Text(
                "Popular Cities",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    [
                          'Hyderabad',
                          'Bangalore',
                          'Chennai',
                          'Mumbai',
                          'Delhi',
                          'Pune',
                        ]
                        .map(
                          (city) => GestureDetector(
                            onTap: () {
                              // Navigate to search screen with prepopulated query
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LocationSearchScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                city,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
