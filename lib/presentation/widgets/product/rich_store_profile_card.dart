import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';
import '../../screens/store/store_screen.dart';

class RichStoreProfileCard extends StatefulWidget {
  final String storeId;
  final String storeName;

  const RichStoreProfileCard({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<RichStoreProfileCard> createState() => _RichStoreProfileCardState();
}

class _RichStoreProfileCardState extends State<RichStoreProfileCard> {
  final StoreService _storeService = StoreService();
  late Future<StoreModel?> _storeFuture;

  @override
  void initState() {
    super.initState();
    _storeFuture = _storeService.getStore(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.orange.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Store Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<StoreModel?>(
              future: _storeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return CachedNetworkImage(
                    imageUrl: snapshot.data!.logoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade50),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade50,
                      child: const Icon(Icons.store, color: Colors.grey),
                    ),
                  );
                }
                return Container(
                  color: Colors.grey.shade50,
                  child: const Icon(Icons.store, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Store Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "By ${widget.storeName}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Visit Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreScreen(storeId: widget.storeId),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primaryGreen),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Visit Store",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
