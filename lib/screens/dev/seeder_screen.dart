import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../tools/seed/seed_database.dart';
import 'package:provider/provider.dart';
import '../../providers/following_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeederScreen extends StatefulWidget {
  const SeederScreen({super.key});

  @override
  State<SeederScreen> createState() => _SeederScreenState();
}

class _SeederScreenState extends State<SeederScreen> {
  final DatabaseSeeder _seeder = DatabaseSeeder();
  bool _isLoading = false;
  String _statusMessage = 'Ready to seed database.';

  void _setStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _handleSeedDatabase() async {
    setState(() => _isLoading = true);
    _setStatus('Seeding database... This may take a moment.');
    try {
      await _seeder.runFullSeed();
      _setStatus('✅ Successfully seeded database with realistic mock data!');
    } catch (e) {
      _setStatus('❌ Error seeding database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClearDatabase() async {
    setState(() => _isLoading = true);
    _setStatus('Clearing seeded data (createdBySeeder == true)...');
    try {
      await _seeder.clearSeededData();
      _setStatus('✅ Successfully cleared all seeded data. Production data untouched.');
    } catch (e) {
      _setStatus('❌ Error clearing database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReseedDatabase() async {
    setState(() => _isLoading = true);
    _setStatus('Clearing old seeds...');
    try {
      await _seeder.clearSeededData();
      _setStatus('Old seeds cleared. Seeding new data...');
      await _seeder.runFullSeed();
      _setStatus('✅ Successfully reseeded the database!');
    } catch (e) {
      _setStatus('❌ Error reseeding database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMockFollowStores() async {
    setState(() => _isLoading = true);
    _setStatus('Mocking follow for first 5 stores...');
    try {
      final snapshot = await FirebaseFirestore.instance.collection('stores').limit(5).get();
      final storeIds = snapshot.docs.map((d) => d.id).toList();
      if (storeIds.isNotEmpty) {
        if (mounted) {
          await context.read<FollowingProvider>().mockFollowStoresForTesting(storeIds);
        }
        _setStatus('✅ Now following ${storeIds.length} stores. Go to Following tab!');
      } else {
        _setStatus('❌ No stores found to follow.');
      }
    } catch (e) {
      _setStatus('❌ Error mocking follow: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Database Seeder'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Development Tools',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these tools to populate your Firestore with realistic marketplace data for testing UI and pagination.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusMessage.startsWith('❌') ? Colors.red : Colors.blue.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _handleSeedDatabase,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Seed Database'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _handleClearDatabase,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Seeded Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleReseedDatabase,
                icon: const Icon(Icons.refresh),
                label: const Text('Reseed Database'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleMockFollowStores,
                icon: const Icon(Icons.favorite),
                label: const Text('Test: Follow 5 Stores'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            const Spacer(),
            const Text(
              '⚠️ WARNING: Clearing data relies on the "createdBySeeder: true" flag. Ensure your production data does NOT have this flag.',
              style: TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
