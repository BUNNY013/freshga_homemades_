import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import 'package:cached_network_image/cached_network_image.dart';

class SuggestionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool isStore;
  final VoidCallback onTap;

  const SuggestionTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.isStore = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            // Image/Avatar Column
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: isStore ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isStore ? null : BorderRadius.circular(8),
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        isStore
                            ? Icons.storefront_outlined
                            : Icons.image_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    )
                  : Icon(
                      isStore
                          ? Icons.storefront_outlined
                          : Icons.search_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 16),

            // Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isStore ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isStore
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                      fontWeight: isStore ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
