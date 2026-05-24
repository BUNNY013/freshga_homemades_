import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';

class StoreStatsRow extends StatelessWidget {
  final StoreModel store;

  const StoreStatsRow({super.key, required this.store});

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              "${store.rating} (${store.reviewsCount})",
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const Text("•", style: TextStyle(color: AppColors.textSecondary)),
        Text(
          "${_formatNumber(store.followers)} Followers",
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const Text("•", style: TextStyle(color: AppColors.textSecondary)),
        Text(
          "${_formatNumber(store.totalOrders)}+ Orders",
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
