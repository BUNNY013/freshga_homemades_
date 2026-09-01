import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TrustStripSection extends StatelessWidget {
  const TrustStripSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              icon: Icons.favorite_border_rounded,
              title: "Support Homemades",
              subtitle: "Empower creators",
            ),
            _buildDivider(),
            const _TrustItem(
              icon: Icons.volunteer_activism_outlined,
              title: "Made with Love",
              subtitle: "Authentic recipes",
            ),
            _buildDivider(),
            const _TrustItem(
              icon: Icons.groups_outlined,
              title: "Grow Together",
              subtitle: "Community first",
            ),
            _buildDivider(),
            const _TrustItem(
              icon: Icons.soup_kitchen_outlined,
              title: "Handcrafted Joy",
              subtitle: "Fresh flavors",
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
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
        Icon(icon, color: const Color(0xFF1E7036), size: 18), // FreshGa Green
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E7036),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
