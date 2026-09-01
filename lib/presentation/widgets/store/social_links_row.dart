import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';

class SocialLinksRow extends StatelessWidget {
  final StoreModel store;

  const SocialLinksRow({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    bool hasAny =
        store.instagramLink.isNotEmpty ||
        store.youtubeLink.isNotEmpty ||
        store.facebookLink.isNotEmpty;

    if (!hasAny) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (store.instagramLink.isNotEmpty)
            _buildSocialIcon(Icons.camera_alt_outlined, "Instagram"),
          if (store.youtubeLink.isNotEmpty)
            _buildSocialIcon(Icons.play_circle_outline, "YouTube"),
          if (store.facebookLink.isNotEmpty)
            _buildSocialIcon(Icons.facebook, "Facebook"),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
