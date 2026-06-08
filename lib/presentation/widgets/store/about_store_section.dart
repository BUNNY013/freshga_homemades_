import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/store_model.dart';

class AboutStoreSection extends StatelessWidget {
  final StoreModel store;

  const AboutStoreSection({super.key, required this.store});

  // Colors based on the UI
  static const Color bgColor = Color(0xFFFFF8F4); // User requested warm cream background
  static const Color cardColor = Colors.white;
  static const Color primaryText = Color(0xFF1E2922);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color iconBgColor = Color(0xFFF0F3E8);
  static const Color iconColor = Color(0xFF4C6A4F);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color chipBgColor = Color(0xFFF5F7F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)), // Slides up by 30 pixels
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildOurStoryCard(),
            const SizedBox(height: 16),
            _buildStoreHighlights(),
            const SizedBox(height: 16),
            _buildLocationAndCategories(),
            const SizedBox(height: 16),
            _buildTrustVerification(),
            const SizedBox(height: 16),
            _buildSocialLinks(),
            const SizedBox(height: 24),
            _buildFooterBanner(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "About this Store",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: primaryText,
                fontFamily: GoogleFonts.playfairDisplay().fontFamily, // Serif-like fallback
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.eco_rounded, color: iconColor.withOpacity(0.5), size: 28),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 80,
          color: iconColor.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryText,
            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildOurStoryCard() {
    return _buildCard(
      child: Stack(
        children: [
          // Simulated Watermark
          Positioned(
            right: -20,
            top: 0,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.eco_rounded, size: 120, color: iconColor),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.eco_outlined, "Our Story"),
              const SizedBox(height: 16),
              Text(
                store.description.isNotEmpty 
                    ? store.description 
                    : "Traditional homemade treats crafted using family recipes passed down through generations. Made in small batches using premium ingredients and no artificial preservatives.",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHighlights() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Store Highlights",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryText,
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHighlightCol(Icons.shopping_bag_outlined, store.productsCount.toString(), "Products", iconColor),
              _buildDivider(),
              _buildHighlightCol(Icons.people_alt_outlined, _formatCount(store.followers), "Followers", const Color(0xFFD77D43)),
              _buildDivider(),
              _buildHighlightCol(Icons.star_border_rounded, store.rating > 0 ? "${store.rating.toStringAsFixed(1)} ★" : "New", "Rating", iconColor),
              _buildDivider(),
              store.totalOrders > 25
                  ? _buildHighlightCol(Icons.local_shipping_outlined, _formatCount(store.totalOrders), "Orders", const Color(0xFFC75D3C))
                  : _buildHighlightCol(Icons.flare_rounded, "New", "Arrival", const Color(0xFFC75D3C)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: dividerColor,
    );
  }

  Widget _buildHighlightCol(IconData icon, String value, String label, Color valueColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationAndCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCard(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, color: iconColor, size: 28),
                const SizedBox(height: 6),
                const Text(
                  "Origin",
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  store.city.isNotEmpty && store.state.isNotEmpty 
                      ? "${store.city}, ${store.state}" 
                      : (store.city.isNotEmpty ? store.city : "Location hidden"),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EBE0), // Warm beige background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CATEGORIES",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: iconColor, // Dark green
                  fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: store.categories.isNotEmpty
                    ? store.categories.map((c) => _buildMiniChip(c)).toList()
                    : [_buildMiniChip("Raw Mango"), _buildMiniChip("Mustard Oil"), _buildMiniChip("Fenugreek"), _buildMiniChip("Fennel"), _buildMiniChip("Turmeric"), _buildMiniChip("Red Chili")],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C2C2C), // Dark grey/black like the image
        ),
      ),
    );
  }

  Widget _buildTrustVerification() {
    if (!store.isVerified) return const SizedBox.shrink();
    
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.verified_user_outlined, "Trust & Verification"),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Image.asset('assets/fssai.png', width: 32, height: 32, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("FSSAI Verified", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryText)),
                        SizedBox(height: 4),
                        Text("Food safety and quality standards verified.", style: TextStyle(fontSize: 13, color: secondaryText, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    if (store.instagramLink.isEmpty && store.facebookLink.isEmpty && store.youtubeLink.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CONNECT WITH US",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: iconColor,
              fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (store.instagramLink.isNotEmpty) _buildSocialImageIcon('assets/instagram.png', "Instagram"),
              if (store.facebookLink.isNotEmpty) _buildSocialIcon(Icons.facebook_outlined, "Facebook"),
              if (store.youtubeLink.isNotEmpty) _buildSocialIcon(Icons.play_circle_outline_rounded, "YouTube"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialImageIcon(String assetPath, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Image.asset(assetPath, width: 28, height: 28, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9EFE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFF0D5BE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFFC75D3C), size: 16),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Thank you for supporting homemakers!",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Every order helps a home grow.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5C5C5C),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.eco_rounded, color: Color(0xFFB5C1A3), size: 24),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
