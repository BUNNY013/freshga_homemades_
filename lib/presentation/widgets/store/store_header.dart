import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';

class StoreHeader extends StatelessWidget {
  final StoreModel store;

  const StoreHeader({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0, // 220 banner + 30 overlap area
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 20),
              onPressed: () {},
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary, size: 20),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none, // Allows the background to scroll smoothly in sync with the list
        background: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Banner Image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 30, // Leave 30px at bottom for white overlap area
              child: CachedNetworkImage(
                imageUrl: store.bannerUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
              ),
            ),
            // Gradient Overlay for text/icon visibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            // White Area for seamless connection
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 30,
              child: Container(color: Colors.white),
            ),
            // Logo positioned to overlap perfectly
            Positioned(
              left: 16,
              bottom: 0, // Logo rests exactly at the boundary of StoreInfoSection
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: store.logoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade100),
                    errorWidget: (context, url, error) => const Icon(Icons.store, color: Colors.grey, size: 36),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
