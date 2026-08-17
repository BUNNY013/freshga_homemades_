import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';
import '../modals/report_modal.dart';

class StoreHeader extends StatelessWidget {
  final StoreModel store;
  final String? heroTag;

  const StoreHeader({super.key, required this.store, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.0, // 170 banner + 50 overlap area
      pinned: false,
      stretch: true, // Enables the premium stretch-to-zoom effect when pulling down
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3), // Transparent premium look
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24), // Bigger icon
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 24),
              onPressed: () {},
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              position: PopupMenuPosition.under,
              elevation: 4,
              color: Colors.white,
              onSelected: (value) {
                if (value == 'report') {
                  ReportModal.show(
                    context,
                    type: 'store',
                    targetId: store.storeId,
                    targetName: store.name,
                    storeId: store.storeId,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 20, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      const Text('Report Store', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        collapseMode: CollapseMode.parallax, // Parallax scrolling effect
        background: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Banner Image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 50, // Leave 50px at bottom for white overlap area
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
              bottom: 50,
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
              height: 50,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),
            // Logo positioned to overlap perfectly
            Positioned(
              left: 0,
              right: 0,
              bottom: 0, // Logo rests exactly at the boundary of StoreInfoSection
              child: Center(
                child: Hero(
                  tag: heroTag ?? 'store_logo_${store.id}',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
