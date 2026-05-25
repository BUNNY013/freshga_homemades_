import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';

class MultiStoreBanner extends StatefulWidget {
  const MultiStoreBanner({super.key});

  @override
  State<MultiStoreBanner> createState() => _MultiStoreBannerState();
}

class _MultiStoreBannerState extends State<MultiStoreBanner> with SingleTickerProviderStateMixin {
  static const String _prefsKey = 'multi_store_cart_info_dismissed';
  bool _isDismissed = true; // Default true until checked
  bool _isVisible = false;
  bool _isInitialized = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _checkDismissedStatus();
  }

  Future<void> _checkDismissedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isDismissed = prefs.getBool(_prefsKey) ?? false;
    
    if (mounted) {
      setState(() {
        _isDismissed = isDismissed;
        _isInitialized = true;
      });
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    
    if (mounted) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isDismissed = true;
            _isVisible = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _isDismissed) return const SizedBox.shrink();

    final cartProvider = context.watch<CartProvider>();
    final hasMultipleStores = cartProvider.totalStores > 1;

    if (hasMultipleStores && !_isVisible) {
      // Trigger show
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
          _animationController.forward();
        }
      });
    } else if (!hasMultipleStores && _isVisible) {
      // Trigger hide if user removes a store
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isVisible) {
          _animationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _isVisible = false;
              });
            }
          });
        }
      });
    }

    return SizeTransition(
      sizeFactor: _fadeAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryGreen),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Items from different stores are placed as separate orders.",
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                onPressed: _dismissBanner,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
