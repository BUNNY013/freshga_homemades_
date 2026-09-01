import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order_model.dart';

class RateProductScreen extends StatefulWidget {
  final OrderModel order;

  const RateProductScreen({super.key, required this.order});

  @override
  State<RateProductScreen> createState() => _RateProductScreenState();
}

class _RateProductScreenState extends State<RateProductScreen> {
  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _feedbackControllers = {};
  bool _isLoading = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.order.items) {
      _ratings[item.productId] = 0;
      _feedbackControllers[item.productId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitRatings() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final uniqueItemsMap = <String, dynamic>{};
        for (var item in widget.order.items) {
          if (!uniqueItemsMap.containsKey(item.productId)) {
            uniqueItemsMap[item.productId] = item;
          }
        }
        final uniqueProducts = uniqueItemsMap.values.toList();

        // Read all products first
        Map<String, DocumentSnapshot> productDocs = {};
        for (var item in uniqueProducts) {
          final rating = _ratings[item.productId] ?? 0;
          if (rating > 0) {
            final docRef = FirebaseFirestore.instance
                .collection('products')
                .doc(item.productId);
            productDocs[item.productId] = await transaction.get(docRef);
          }
        }

        // Read store doc
        final storeRef = FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.order.storeId);
        final storeDoc = await transaction.get(storeRef);

        // Perform writes
        final reviewsRef = FirebaseFirestore.instance.collection('reviews');

        for (var item in uniqueProducts) {
          final rating = _ratings[item.productId] ?? 0;
          final feedback =
              _feedbackControllers[item.productId]?.text.trim() ?? '';

          if (rating > 0) {
            // Write Review
            final docRef = reviewsRef.doc();
            transaction.set(docRef, {
              'orderId': widget.order.orderId,
              'storeId': widget.order.storeId,
              'customerId': widget.order.customerId,
              'productId': item.productId,
              'productName': item.productName,
              'rating': rating,
              'feedback': feedback,
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Update Product aggregate
            final pDoc = productDocs[item.productId];
            if (pDoc != null && pDoc.exists) {
              final data = pDoc.data() as Map<String, dynamic>;
              final currentRating = (data['rating'] ?? 0.0).toDouble();
              final currentCount =
                  (data['totalReviews'] ?? data['reviewsCount'] ?? 0).toInt();
              final currentRatingCounts = Map<String, dynamic>.from(
                data['ratingCounts'] ?? {},
              );

              final newCount = currentCount + 1;
              final newRating =
                  ((currentRating * currentCount) + rating) / newCount;
              currentRatingCounts[rating.toString()] =
                  (currentRatingCounts[rating.toString()] ?? 0) + 1;

              transaction.update(pDoc.reference, {
                'rating': double.parse(newRating.toStringAsFixed(1)),
                'totalReviews': newCount,
                'reviewsCount': newCount, // Keep for backward compatibility
                'ratingCounts': currentRatingCounts,
              });
            }
          }
        }

        // Update Store aggregate
        if (storeDoc.exists) {
          final storeData = storeDoc.data() as Map<String, dynamic>;
          final currentStoreRating = (storeData['rating'] ?? 0.0).toDouble();
          final currentStoreCount =
              (storeData['totalReviews'] ?? storeData['reviewsCount'] ?? 0)
                  .toInt();

          int addedReviews = 0;
          double addedRatingSum = 0;
          for (var item in uniqueProducts) {
            final rating = _ratings[item.productId] ?? 0;
            if (rating > 0) {
              addedReviews++;
              addedRatingSum += rating;
            }
          }

          if (addedReviews > 0) {
            final newStoreCount = currentStoreCount + addedReviews;
            final newStoreRating =
                ((currentStoreRating * currentStoreCount) + addedRatingSum) /
                newStoreCount;

            transaction.update(storeRef, {
              'rating': double.parse(newStoreRating.toStringAsFixed(1)),
              'totalReviews': newStoreCount,
              'reviewsCount': newStoreCount,
            });
          }
        }

        // Mark order as rated
        transaction.update(
          FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.order.orderId),
          {'isRated': true},
        );
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit ratings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                "Thank you!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                "Your ratings have been submitted.\nWe appreciate your feedback.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // Dummy items illustration (Optional)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.order.items
                    .take(2)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey.shade200),
                            errorWidget: (context, url, error) =>
                                Container(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(
                    context,
                    (route) =>
                        route.isFirst || route.settings.name == '/orders',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildSuccessView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Rate Your Products",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How was your experience with the products?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "Your feedback helps the seller and other customers.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),

            ...(() {
              final uniqueItemsMap = <String, dynamic>{};
              for (var item in widget.order.items) {
                if (!uniqueItemsMap.containsKey(item.productId)) {
                  uniqueItemsMap[item.productId] = item;
                }
              }
              return uniqueItemsMap.values.toList();
            })().map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade100,
                              width: 72,
                              height: 72,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade100,
                              width: 72,
                              height: 72,
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.variantLabel,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Rate this product",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final isSelected =
                            index < (_ratings[item.productId] ?? 0);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _ratings[item.productId] = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              isSelected ? Icons.star : Icons.star_border,
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Write a short feedback (optional)",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackControllers[item.productId],
                      maxLength: 120,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            "Tell us what you liked about this product...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bottom Action Button
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom
                    : 16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRatings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit Ratings",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
