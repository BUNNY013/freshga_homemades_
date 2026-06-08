import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';

class StoreMenuFab extends StatefulWidget {
  final Map<String, int> sectionCounts;
  final Function(String, String) onSubcategorySelected;
  
  const StoreMenuFab({super.key, required this.sectionCounts, required this.onSubcategorySelected});

  @override
  State<StoreMenuFab> createState() => _StoreMenuFabState();
}

class _StoreMenuFabState extends State<StoreMenuFab> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildMenuData(StoreProvider provider) {
    final Map<String, Map<String, dynamic>> grouped = {};
    int totalCount = 0;

    for (var product in provider.allStoreProducts) {
      final catId = product.categoryId;
      if (catId.isEmpty) continue;

      if (!grouped.containsKey(catId)) {
        grouped[catId] = {
          'categoryId': catId,
          'name': provider.availableCategories[catId] ?? "Other",
          'subcategories': <String, Map<String, dynamic>>{},
        };
      }

      final group = grouped[catId]!;
      totalCount++;

      if (product.subCategoryIds.isEmpty) {
        final subs = group['subcategories'] as Map<String, Map<String, dynamic>>;
        subs['Other'] = {
          'name': 'Other',
          'count': (subs['Other']?['count'] ?? 0) + 1,
        };
      } else {
        for (var subId in product.subCategoryIds) {
          final subs = group['subcategories'] as Map<String, Map<String, dynamic>>;
          final subName = provider.availableSubcategories[subId]?['name'] ?? "Other";
          
          if (!subs.containsKey(subId)) {
            subs[subId] = {'name': subName, 'count': 0};
          }
          subs[subId]!['count'] = (subs[subId]!['count'] as int) + 1;
        }
      }
    }

    final list = grouped.values.toList();
    list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    
    return [
      {
        'isAll': true,
        'name': 'All Items',
        'count': totalCount,
      },
      ...list
    ];
  }

  void _showMenuDialog(BuildContext context, StoreProvider provider) {
    final menuData = _buildMenuData(provider);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Menu",
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 165.0, right: 20.0),
            child: Material(
              color: Colors.white, // Clean, pristine white menu card
              borderRadius: BorderRadius.circular(28),
              elevation: 20,
              shadowColor: Colors.black26,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 320, // Wider for premium feel
                  maxHeight: MediaQuery.of(context).size.height * 0.65, // Taller
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: RawScrollbar(
                    thumbColor: Colors.grey.shade300,
                    radius: const Radius.circular(8),
                    thickness: 4,
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: menuData.length,
                      itemBuilder: (context, index) {
                        final item = menuData[index];
                        
                        if (item['isAll'] == true) {
                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSubcategorySelected("All", "All");
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Georgia',
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B2A2F),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item['count'].toString(),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Category Section
                        final String catName = item['name'];
                        final Map<String, Map<String, dynamic>> subcategories = item['subcategories'];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subtle Divider between categories
                            if (index > 1) 
                              Divider(height: 1, color: Colors.grey.shade100, indent: 28, endIndent: 28),
                            
                            // Category Title Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 24, 28, 10),
                              child: Text(
                                catName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: Color(0xFFB4A596), // Soft golden/tan for a premium touch
                                ),
                              ),
                            ),
                            
                            // Subcategories
                            ...subcategories.entries.map((entry) {
                              final subData = entry.value;
                              final subName = subData['name'];
                              final catId = item['categoryId'];

                              return InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onSubcategorySelected(catId, subName);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          subName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        subData['count'].toString(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sectionCounts.isEmpty) return const SizedBox.shrink();
    
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        return Positioned(
          bottom: 80, // Above floating cart bar
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatAnimation.value),
                child: child,
              );
            },
            child: Align(
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10), // Deep shadow for floating effect
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: const Color(0xFF1E1E1E), // Premium Matte Black
                  shape: const StadiumBorder(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => _showMenuDialog(context, provider),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "Pantry",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
