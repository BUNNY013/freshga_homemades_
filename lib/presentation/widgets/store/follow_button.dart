import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/following_provider.dart';
import '../../../models/store_model.dart';

class FollowButton extends StatelessWidget {
  final String storeId;
  final String storeName;
  final String storeLogo;
  final String ownerId;
  final bool isCompact;

  const FollowButton({
    super.key, 
    required this.storeId, 
    required this.storeName, 
    this.storeLogo = '',
    this.ownerId = '',
    this.isCompact = false,
  });

  factory FollowButton.fromStore(StoreModel store, {bool isCompact = false}) {
    return FollowButton(
      storeId: store.id,
      storeName: store.name,
      storeLogo: store.logoUrl,
      ownerId: store.ownerId,
      isCompact: isCompact,
    );
  }

  void _showUnfollowConfirmation(BuildContext context, FollowingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: storeLogo.isNotEmpty 
                    ? NetworkImage(storeLogo) 
                    : null,
                child: storeLogo.isEmpty ? const Icon(Icons.store, size: 40, color: Colors.grey) : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Unfollow $storeName?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        provider.toggleFollow(storeId, {
                          'storeName': storeName,
                          'storeLogo': storeLogo,
                          'ownerId': ownerId,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Unfollow',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowingProvider>(
      builder: (context, provider, child) {
        final isFollowing = provider.isFollowing(storeId);
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : AppColors.primaryGreen,
            border: Border.all(
              color: isFollowing ? Colors.grey[300]! : AppColors.primaryGreen,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(isCompact ? 12 : 20),
            boxShadow: isFollowing ? [] : [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(isCompact ? 12 : 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(isCompact ? 12 : 20),
              onTap: () {
                if (isFollowing) {
                  _showUnfollowConfirmation(context, provider);
                } else {
                  provider.toggleFollow(storeId, {
                    'storeName': storeName,
                    'storeLogo': storeLogo,
                    'ownerId': ownerId,
                  });
                }
              },
              child: Padding(
                padding: isCompact 
                    ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                    : const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFollowing && !isCompact) ...[
                      const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isFollowing ? "Following" : "Follow",
                        key: ValueKey(isFollowing),
                        style: TextStyle(
                          color: isFollowing ? AppColors.textPrimary : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 10 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
