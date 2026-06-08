import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/store_update_model.dart';
import '../../screens/product/product_details_screen.dart';
import '../../screens/store/store_screen.dart';

class FeedCard extends StatelessWidget {
  final StoreUpdateModel update;

  const FeedCard({super.key, required this.update});

  Color _getBadgeColor() {
    switch (update.type) {
      case 'new_launch':
        return AppColors.primaryGreen;
      case 'restock':
        return const Color(0xFFE67E22); // Premium Orange
      case 'offer':
        return const Color(0xFFF43F5E); // Premium Pink/Rose
      case 'community_update':
      default:
        return const Color(0xFF3498DB); // Premium Blue
    }
  }

  String _getBadgeText() {
    if (update.badgeText.isNotEmpty) return update.badgeText;
    switch (update.type) {
      case 'new_launch':
        return 'New Launch';
      case 'restock':
        return 'Restocked';
      case 'offer':
        return 'Offer';
      case 'community_update':
      default:
        return 'Update';
    }
  }

  String? _extractDiscountCode() {
    if (update.type == 'offer') {
      final match = RegExp(r'code\s+([A-Z0-9]+)', caseSensitive: false).firstMatch(update.description);
      if (match != null) {
        return match.group(1)?.toUpperCase();
      }
      return 'FRESH10'; // Fallback for UI demonstration
    }
    return null;
  }

  void _onCardTap(BuildContext context) {
    if (update.productId != null && update.productId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(productId: update.productId!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoreScreen(storeId: update.storeId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final isProductPost = update.type != 'community_update'; // new_launch, restock, offer
    final discountCode = _extractDiscountCode();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _onCardTap(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER: Avatar, Store Name, Time, Badge ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200, width: 1),
                            color: Colors.white,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: update.storeLogo.isNotEmpty 
                                ? update.storeLogo 
                                : 'https://images.unsplash.com/photo-1556910103-1c02745a872f?w=100&h=100&fit=crop',
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(Icons.storefront_rounded, color: Colors.grey, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              update.storeName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeago.format(update.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getBadgeText(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                // --- CONTENT AREA ---
                if (isProductPost)
                  // Split Layout for Product Updates (Left: Text, Right: Image)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Text, Price, Buttons
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              update.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.3,
                                fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              update.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            
                            // Discount Code Pill (If Offer)
                            if (update.type == 'offer' && discountCode != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.05),
                                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Code: $discountCode",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: badgeColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                            // Price
                            if (update.price > 0 && update.type != 'offer')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  '₹${(update.discountPrice > 0 ? update.discountPrice : update.price).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryGreen,
                                    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                                  ),
                                ),
                              ),
                            
                            // CTA Button
                            ElevatedButton(
                              onPressed: () => _onCardTap(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: update.type == 'offer' ? badgeColor : AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                update.ctaText,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: GoogleFonts.plusJakartaSans().fontFamily),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Right Column: Product Image
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: update.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 40),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // Full-Width Layout for Community Updates
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (update.title.isNotEmpty)
                        Text(
                          update.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                          ),
                        ),
                      if (update.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          update.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (update.imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: update.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(height: 200, color: Colors.grey.shade50),
                            errorWidget: (context, url, error) => Container(
                              height: 200, 
                              color: Colors.grey.shade50,
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                      if (update.ctaText.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: () => _onCardTap(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryGreen,
                              side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              update.ctaText,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: GoogleFonts.plusJakartaSans().fontFamily),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
