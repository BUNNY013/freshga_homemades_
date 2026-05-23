import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SuggestionTile extends StatelessWidget {
  final String title;
  final bool isStore;
  final VoidCallback onTap;

  const SuggestionTile({
    super.key,
    required this.title,
    this.isStore = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              isStore ? Icons.storefront_outlined : Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.north_west_rounded,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
