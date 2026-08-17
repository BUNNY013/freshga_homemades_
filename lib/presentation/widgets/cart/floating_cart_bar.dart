import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../screens/cart/cart_screen.dart';

class FloatingCartBar extends StatefulWidget {
  final double bottomOffset;
  
  const FloatingCartBar({super.key, this.bottomOffset = 0});

  @override
  State<FloatingCartBar> createState() => _FloatingCartBarState();
}

class _FloatingCartBarState extends State<FloatingCartBar> {
  bool _isMinimized = false;
  int _lastItemCount = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.isEmpty) {
          _lastItemCount = 0;
          return const SizedBox.shrink();
        }

        final itemCount = cartProvider.totalItems;
        
        // Auto-expand if new items are added to the cart
        if (itemCount > _lastItemCount) {
          _isMinimized = false;
        }
        _lastItemCount = itemCount;
        final storeCount = cartProvider.totalStores;
        final totalPrice = cartProvider.totalPrice;

        String storeText = storeCount == 1 
            ? cartProvider.items.values.first.storeName 
            : '$storeCount stores';

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          bottom: 16 + MediaQuery.of(context).padding.bottom + widget.bottomOffset,
          right: 16,
          // When minimized, width is 60. When expanded, width is screen - 32.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            width: _isMinimized ? 60 : MediaQuery.of(context).size.width - 32,
            height: _isMinimized ? 60 : 72,
            decoration: BoxDecoration(
              color: _isMinimized ? AppColors.primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(_isMinimized ? 30 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(_isMinimized ? 30 : 16),
                onTap: () {
                  if (_isMinimized) {
                    setState(() => _isMinimized = false);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  }
                },
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    // --- EXPANDED CONTENT (Fades in/out) ---
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isMinimized ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: _isMinimized,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: const NeverScrollableScrollPhysics(),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 32,
                              height: 72,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 300),
                                              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                                              child: Text(
                                                '$itemCount items • $storeText',
                                                key: ValueKey<int>(itemCount),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 300),
                                              transitionBuilder: (child, animation) => SlideTransition(
                                                position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation),
                                                child: FadeTransition(opacity: animation, child: child),
                                              ),
                                              child: Text(
                                                '₹${totalPrice.toInt()}',
                                                key: ValueKey<double>(totalPrice),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Text(
                                              'View Cart',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isMinimized = true;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                    
                    // --- MINIMIZED CONTENT (Fades in/out) ---
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isMinimized ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_isMinimized,
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                                if (itemCount > 0)
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: AppColors.terracotta,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$itemCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
