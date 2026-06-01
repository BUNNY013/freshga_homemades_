import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/customer_provider.dart';
import 'auth_wrapper.dart';
import 'location_search_screen.dart'; // To be created next

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  bool _isLocating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
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

      // Get location with timeout for emulator stability
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Fallback to last known position if current position times out (common on emulators)
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        throw 'Could not get current location. Please ensure location is enabled on your device/emulator or try searching manually.';
      }

      // Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (!mounted) return;
        _showConfirmationSheet(
          city: place.locality ?? place.subAdministrativeArea ?? '',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
          pincode: place.postalCode ?? '',
        );
      } else {
        throw 'Could not determine location from coordinates.';
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
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _showConfirmationSheet({
    required String city,
    required String state,
    required String country,
    required String pincode,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Confirm Location",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "$city, $state $pincode\n$country",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
                        );
                      },
                      child: const Text("Change"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final provider = Provider.of<CustomerProvider>(context, listen: false);
                        await provider.updateLocation(
                          city: city,
                          state: state,
                          country: country,
                          pincode: pincode,
                          source: 'gps',
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close sheet
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        );
                      },
                      child: const Text("Confirm"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Map Icon Container
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 64,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              Text(
                "Delivering To",
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                "Choose your delivery location to discover nearby homemade brands and personalized recommendations.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Use Current Location Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLocating ? null : _useCurrentLocation,
                  icon: _isLocating 
                      ? const SizedBox.shrink()
                      : const Icon(Icons.my_location),
                  label: _isLocating
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Use Current Location"),
                ),
              ),

              const SizedBox(height: 16),
              
              // Search City / Pincode
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text("Search City / Pincode"),
                ),
              ),

              const SizedBox(height: 16),

              // Skip for now
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () async {
                    final provider = Provider.of<CustomerProvider>(context, listen: false);
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
                  child: Text(
                    "Skip For Now",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                "Popular Cities",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Hyderabad', 'Bangalore', 'Chennai', 'Mumbai', 'Delhi', 'Pune'
                ].map((city) => ActionChip(
                  label: Text(city),
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.05),
                  side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.2)),
                  onPressed: () {
                    // Navigate to search screen with prepopulated query
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LocationSearchScreen(), // We can enhance this later to auto-search
                      ),
                    );
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
