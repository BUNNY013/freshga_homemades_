import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'customer_home_screen.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final List<Map<String, dynamic>> _interests = [
    {"name": "Pickles", "icon": "🍋", "selected": false},
    {"name": "Honey", "icon": "🍯", "selected": false},
    {"name": "Sweets", "icon": "🍡", "selected": false},
    {"name": "Snacks", "icon": "🥨", "selected": false},
    {"name": "Masalas", "icon": "🌶️", "selected": false},
    {"name": "Millets", "icon": "🌾", "selected": false},
    {"name": "Cookies", "icon": "🍪", "selected": false},
    {"name": "Healthy Foods", "icon": "🥗", "selected": false},
  ];

  int get _selectedCount => _interests.where((i) => i["selected"] == true).length;

  void _toggleInterest(int index) {
    setState(() {
      _interests[index]["selected"] = !(_interests[index]["selected"] as bool);
    });
  }

  void _continue() {
    if (_selectedCount >= 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Skip logic -> go to Home directly
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              );
            },
            child: Text(
              "Skip for now",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What do you love?",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      "Pick at least 3 categories so we can personalize your homemade discovery feed.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: List.generate(_interests.length, (index) {
                        final interest = _interests[index];
                        final isSelected = interest["selected"] as bool;
                        
                        return GestureDetector(
                          onTap: () => _toggleInterest(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primaryGreen 
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.primaryGreen 
                                    : AppColors.textSecondary.withOpacity(0.2),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryGreen.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  interest["icon"] as String,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  interest["name"] as String,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: isSelected 
                                        ? Colors.white 
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.textSecondary.withOpacity(0.1),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedCount >= 3 ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCount >= 3 
                          ? AppColors.primaryGreen 
                          : AppColors.textSecondary.withOpacity(0.2),
                      foregroundColor: _selectedCount >= 3 
                          ? Colors.white 
                          : AppColors.textSecondary,
                    ),
                    child: Text(
                      _selectedCount >= 3
                          ? "Continue"
                          : "Select ${_selectedCount < 3 ? (3 - _selectedCount) : 0} more",
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
