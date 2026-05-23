import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';

class FollowButton extends StatelessWidget {
  const FollowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        final isFollowing = provider.isFollowing;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : AppColors.primaryGreen,
            border: Border.all(color: AppColors.primaryGreen),
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              // Assuming "user_1" for demo purposes
              provider.toggleFollow('user_1');
            },
            child: Text(
              isFollowing ? "Following" : "Follow",
              style: TextStyle(
                color: isFollowing ? AppColors.primaryGreen : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }
}
