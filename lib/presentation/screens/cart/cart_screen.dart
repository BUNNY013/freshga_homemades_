import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';
import '../../widgets/cart/multi_store_banner.dart';
import 'empty_cart_screen.dart';
import '../store/store_screen.dart';
import '../checkout/checkout_screen.dart';
import '../../../providers/wishlist_provider.dart';
import '../wishlist/liked_products_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<String, bool> _expandedStores = {};
  final Map<String, StoreModel> _storeCache = {};
  final StoreService _storeService = StoreService();

  Future<StoreModel?> _getStore(String storeId) async {
    if (_storeCache.containsKey(storeId)) return _storeCache[storeId];
    final store = await _storeService.getStore(storeId);
    if (store != null && mounted) {
      setState(() {
        _storeCache[storeId] = store;
      });
    }
    return store;
  }

  String _getMaxDispatchTime(List<CartItemModel> items) {
    int maxDays = 0;
    for (var item in items) {
      final numMatch = RegExp(r'\d+').firstMatch(item.dispatchTime);
      if (numMatch != null) {
        final int days = int.parse(numMatch.group(0)!);
        if (days > maxDays) maxDays = days;
      }
    }
    if (maxDays == 0) return "2 Days";
    return "$maxDays Days";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.isEmpty) {
          return const EmptyCartScreen();
        }

        final groupedItems = cartProvider.getStoreGroupedItems();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "My Cart",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, _) {
                  final count = wishlistProvider.likedProducts.length;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppColors.textPrimary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LikedProductsScreen()),
                          );
                        },
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Info Banner
                const MultiStoreBanner(),

                // Store Groups
                ...groupedItems.entries.map((entry) {
                  final storeId = entry.key;
                  final items = entry.value;
                  final storeName = items.first.storeName;
                  final isExpanded = _expandedStores[storeId] ?? true;

                  return _buildStoreSection(
                    context, 
                    cartProvider, 
                    storeId, 
                    storeName, 
                    items, 
                    isExpanded,
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreSection(
    BuildContext context, 
    CartProvider cartProvider, 
    String storeId, 
    String storeName, 
    List<CartItemModel> items, 
    bool isExpanded
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Store Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedStores[storeId] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  FutureBuilder<StoreModel?>(
                    future: _storeCache.containsKey(storeId) ? Future.value(_storeCache[storeId]) : _getStore(storeId),
                    builder: (context, snapshot) {
                      final store = snapshot.data;
                      if (store != null && store.logoUrl.isNotEmpty) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: store.logoUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey.shade100, width: 40, height: 40),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade100, width: 40, height: 40,
                              child: const Icon(Icons.storefront, color: AppColors.primaryGreen, size: 20),
                            ),
                          ),
                        );
                      }
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront, color: AppColors.primaryGreen, size: 20),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${cartProvider.getStoreItemCount(storeId)} items",
                                style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Dispatch in ${_getMaxDispatchTime(items)}",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),

          // Store Items (Collapsible)
          AnimatedCrossFade(
            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
            firstChild: Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (context, index) {
                    return _buildCartItem(cartProvider, items[index]);
                  },
                ),
                
                // Add More Items
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StoreScreen(storeId: storeId)),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: AppColors.primaryGreen, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Add more items from this store",
                          style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                
                // Store Total & Checkout
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Store Total",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            "₹${cartProvider.getStoreTotal(storeId).toInt()}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            showDialog(
                               context: context,
                               barrierDismissible: false,
                               builder: (c) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                            );
                            
                            final messages = await cartProvider.validateCartForCheckout(storeId);
                            if (!context.mounted) return;
                            Navigator.pop(context); // pop loading
                            
                            if (messages.isNotEmpty) {
                               showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                     title: const Text('Cart Updated', style: TextStyle(fontWeight: FontWeight.bold)),
                                     content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: messages.map((m) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Text('• $m', style: const TextStyle(fontSize: 14)),
                                        )).toList(),
                                     ),
                                     actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c), 
                                          child: const Text('Review Cart', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold))
                                        ),
                                     ],
                                  ),
                               );
                            } else {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(builder: (context) => CheckoutScreen(storeId: storeId)),
                               );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Checkout $storeName",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartProvider cartProvider, CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey.shade200, width: 64, height: 64),
              errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, width: 64, height: 64),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => cartProvider.removeFromCart(item.cartItemId),
                      child: const Icon(CupertinoIcons.trash, color: AppColors.textSecondary, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.variantLabel,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${item.price.toInt()}",
                      style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (item.isAvailable)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => cartProvider.decrementQuantity(item.cartItemId),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Text(
                              "${item.quantity}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            InkWell(
                              onTap: () => cartProvider.incrementQuantity(item.cartItemId),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Not available",
                          style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
