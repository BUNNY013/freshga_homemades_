import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TrustStripSection extends StatelessWidget {
  const TrustStripSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F3), // Light greenish background from UI
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const _TrustItem(
              icon: Icons.shield_outlined,
              title: "Verified Sellers",
              subtitle: "100% trusted",
            ),
            _buildDivider(),
            const _TrustItem(
              icon: Icons.eco_outlined, // Closest to leaf icon
              title: "No Preservatives",
              subtitle: "Homemade & Pure",
            ),
            _buildDivider(),
            const _TrustItem(
              icon: Icons.inventory_2_outlined,
              title: "Eco Packaging",
              subtitle: "Better for Earth",
            ),
            _buildDivider(),
            const _TrustItem(
              icon: Icons.schedule_send_outlined, // Clock/Dispatch icon
              title: "On-time Dispatch",
              subtitle: "Fresh to you",
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey.shade300,
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF1E7036), size: 24), // FreshGa Green
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E7036),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
