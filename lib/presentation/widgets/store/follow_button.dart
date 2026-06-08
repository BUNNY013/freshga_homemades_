import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/following_provider.dart';
import '../../../models/store_model.dart';

class FollowButton extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String storeLogo;
  final String ownerId;
  final bool isCompact;
  final bool showNotificationBell;

  const FollowButton({
    super.key, 
    required this.storeId, 
    required this.storeName, 
    this.storeLogo = '',
    this.ownerId = '',
    this.isCompact = false,
    this.showNotificationBell = true,
  });

  factory FollowButton.fromStore(StoreModel store, {bool isCompact = false, bool showNotificationBell = true}) {
    return FollowButton(
      storeId: store.id,
      storeName: store.name,
      storeLogo: store.logoUrl,
      ownerId: store.ownerId,
      isCompact: isCompact,
      showNotificationBell: showNotificationBell,
    );
  }

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _notificationsEnabled = true;

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
                backgroundImage: widget.storeLogo.isNotEmpty 
                    ? NetworkImage(widget.storeLogo) 
                    : null,
                child: widget.storeLogo.isEmpty ? const Icon(Icons.store, size: 40, color: Colors.grey) : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Unfollow ${widget.storeName}?',
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
                        provider.toggleFollow(widget.storeId, {
                          'storeName': widget.storeName,
                          'storeLogo': widget.storeLogo,
                          'ownerId': widget.ownerId,
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
        final isFollowing = provider.isFollowing(widget.storeId);
        
        final followBtn = AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : AppColors.primaryGreen,
            border: Border.all(
              color: isFollowing ? Colors.grey[300]! : AppColors.primaryGreen,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 24),
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
            borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 24),
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 24),
              onTap: () {
                if (isFollowing) {
                  _showUnfollowConfirmation(context, provider);
                } else {
                  provider.toggleFollow(widget.storeId, {
                    'storeName': widget.storeName,
                    'storeLogo': widget.storeLogo,
                    'ownerId': widget.ownerId,
                  });
                }
              },
              child: Padding(
                padding: widget.isCompact 
                    ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                    : const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFollowing && !widget.isCompact) ...[
                      const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primaryGreen),
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
                          fontSize: widget.isCompact ? 10 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (isFollowing && widget.showNotificationBell) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              followBtn,
              const SizedBox(width: 8),
              _buildNotificationBell(),
            ],
          );
        }

        return followBtn;
      },
    );
  }

  Widget _buildNotificationBell() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _notificationsEnabled ? AppColors.primaryGreen.withOpacity(0.08) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: _notificationsEnabled ? AppColors.primaryGreen.withOpacity(0.3) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _notificationsEnabled = !_notificationsEnabled;
            });
            
            // Show YouTube style quick snackbar
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _notificationsEnabled 
                    ? "You'll get all notifications from ${widget.storeName}"
                    : "You won't get notifications from ${widget.storeName}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF1E2922),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: "OK",
                  textColor: AppColors.primaryGreen,
                  onPressed: () {},
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(
              _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              color: _notificationsEnabled ? AppColors.primaryGreen : Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
