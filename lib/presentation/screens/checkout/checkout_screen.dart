import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../models/address_model.dart';
import '../../../models/store_model.dart';
import '../../../models/delivery_area_model.dart';
import '../../../services/store_service.dart';
import '../../widgets/checkout/address_bottom_sheet.dart';
import '../store/store_screen.dart';
import '../product/product_details_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'order_success_screen.dart';
import '../../../models/order_model.dart';
import '../../../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String storeId;

  const CheckoutScreen({super.key, required this.storeId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressModel? _selectedAddress;
  StoreModel? _store;
  bool _isLoading = false;
  String _deliveryInstructions = '';
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStoreDetails();
      _autoSelectDefaultAddress();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _autoSelectDefaultAddress() {
    final customerProvider = context.read<CustomerProvider>();
    final customer = customerProvider.currentCustomer;
    if (customer != null &&
        customer.savedAddresses != null &&
        customer.savedAddresses!.isNotEmpty) {
      try {
        final defaultAddress = customer.savedAddresses!.firstWhere(
          (addr) => addr.isDefault,
        );
        setState(() => _selectedAddress = defaultAddress);
      } catch (e) {
        setState(() => _selectedAddress = customer.savedAddresses!.first);
      }
    }
  }

  Future<void> _fetchStoreDetails() async {
    final store = await StoreService().getStore(widget.storeId);
    if (mounted && store != null) {
      setState(() => _store = store);
    }
  }

  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressBottomSheet(
        selectedAddress: _selectedAddress,
        onAddressSelected: (address) {
          setState(() {
            _selectedAddress = address;
          });
        },
      ),
    );
  }

  void _showInstructionsBottomSheet() {
    final TextEditingController instrCtrl = TextEditingController(
      text: _deliveryInstructions,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // For keyboard
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Delivery Instructions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: instrCtrl,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: InputDecoration(
                    hintText: "e.g. Please pack safely, leave with security...",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _deliveryInstructions = instrCtrl.text.trim();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Save Instructions",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _proceedToPayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cartProvider = context.read<CartProvider>();
    final validationError = await cartProvider.validateCheckoutAddress(
      widget.storeId,
      _selectedAddress!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (validationError != null) {
      // Compliance check failed!
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'Delivery Restricted',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            validationError,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                _showAddressBottomSheet();
              },
              child: const Text(
                'Change Address',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }

    // Pass compliance! Navigate to payment screen
    final groupedItems = cartProvider.getStoreGroupedItems();
    final items = groupedItems[widget.storeId] ?? [];
    if (items.isEmpty) return;

    final storeName = items.first.storeName;
    final itemTotal = cartProvider.getStoreTotal(widget.storeId);
    final deliveryFee = _calculateDeliveryFee(itemTotal);
    final platformFee = 9.0;
    final toPay = itemTotal + deliveryFee + platformFee;

    var options = {
      'key': 'rzp_test_TOo0mUDrME9tJp', // TODO: Replace with real key
      'amount': (toPay * 100).toInt(), // Amount in paise
      'name': 'FreshGa Homemades',
      'description': 'Payment for Order from $storeName',
      'timeout': 120,
      'retry': {'enabled': true, 'max_count': 3},
      'prefill': {
        'contact': _selectedAddress!.phoneNumber,
        'email':
            context.read<CustomerProvider>().currentCustomer?.email ??
            'test@example.com',
      },
      'theme': {'color': '#4CAF50'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open Razorpay: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() => _isLoading = false);

    String errorMessage =
        "Payment Failed: ${response.message ?? 'Unknown error'}";
    if (response.code == Razorpay.NETWORK_ERROR) {
      errorMessage =
          "Network issue detected. Please check your internet connection.";
    } else if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = "Payment was cancelled. You can try again.";
    } else if (response.code == Razorpay.INVALID_OPTIONS) {
      errorMessage = "Configuration error. Please contact support.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet Selected: ${response.walletName}"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment succeeded! Save the order to Firestore.
    try {
      final cartProvider = context.read<CartProvider>();
      final groupedItems = cartProvider.getStoreGroupedItems();
      final items = groupedItems[widget.storeId] ?? [];
      if (items.isEmpty) return;

      final storeName = items.first.storeName;
      final itemTotal = cartProvider.getStoreTotal(widget.storeId);
      final deliveryFee = _calculateDeliveryFee(itemTotal);
      final platformFee = 9.0;
      final toPay = itemTotal + deliveryFee + platformFee;

      final orderItems = items
          .map(
            (cartItem) => OrderItem(
              productId: cartItem.productId,
              productName: cartItem.productName,
              imageUrl: cartItem.imageUrl,
              variantLabel: cartItem.variantLabel,
              quantity: cartItem.quantity,
              price: cartItem.price,
            ),
          )
          .toList();

      final orderService = OrderService();
      int maxDispatchDays = 1;
      final maxDispatchDate = DateTime.now().add(const Duration(days: 2));
      final expiresAt = DateTime.now().add(const Duration(hours: 24));

      final customerProvider = context.read<CustomerProvider>();
      final customerId =
          customerProvider.currentCustomer?.uid ?? 'unknown_customer';

      final order = OrderModel(
        orderId: '',
        storeId: widget.storeId,
        storeName: storeName,
        customerId: customerId,
        customerName: _selectedAddress!.name,
        items: orderItems,
        totalAmount: toPay,
        subTotal: itemTotal,
        deliveryFee: deliveryFee,
        taxes: 0.0,
        platformFee: platformFee,
        paymentMethod: 'Online',
        paymentStatus: 'Completed',
        payoutStatus: 'pending',
        deliveryAddress: _selectedAddress!.formattedAddress,
        deliveryLatitude: _selectedAddress!.latitude,
        deliveryLongitude: _selectedAddress!.longitude,
        customerPhone: _selectedAddress!.phoneNumber,
        orderStatus: 'New',
        expiresAt: expiresAt,
        maxDispatchDate: maxDispatchDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final generatedOrderId = await orderService.createOrder(order);

      if (mounted) {
        cartProvider.clearStoreCart(widget.storeId);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              orderId: generatedOrderId,
              amountPaid: toPay,
              paymentMethod: 'Online',
              date: DateTime.now(),
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save order: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _calculateDeliveryDate(List<dynamic> items) {
    if (_store == null || _selectedAddress == null) return "-";

    // 1. Find max dispatch time
    int maxDispatchDays = 1;
    for (var item in items) {
      final dispatchStr = item.dispatchTime.toString();
      final parts = dispatchStr.split(' ');
      if (parts.isNotEmpty) {
        final days = int.tryParse(parts[0]);
        if (days != null && days > maxDispatchDays) {
          maxDispatchDays = days;
        }
      }
    }

    // 2. Determine transit time
    int transitDays = 7; // Default National (Buffer for India Post / Surface)
    if (_store!.state.toLowerCase().trim() ==
        _selectedAddress!.state.toLowerCase().trim()) {
      transitDays = 3; // Local State (Buffer for standard couriers)
    }

    final totalDays = maxDispatchDays + transitDays;

    final deliveryDate = DateTime.now().add(Duration(days: totalDays));
    final monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${deliveryDate.day} ${monthNames[deliveryDate.month - 1]}";
  }

  DeliveryAreaModel? _getApplicableDeliveryArea() {
    if (_store == null || _selectedAddress == null) return null;

    final customerState = _selectedAddress!.state.toLowerCase().trim();

    DeliveryAreaModel? matchedArea;
    DeliveryAreaModel? remainingIndiaArea;

    for (var area in _store!.deliveryAreas) {
      if (area.states.any((s) => s.toLowerCase().trim() == customerState)) {
        matchedArea = area;
        break;
      }
      if (area.states.contains('*')) {
        remainingIndiaArea = area;
      }
    }

    return matchedArea ?? remainingIndiaArea;
  }

  double _calculateDeliveryFee(double itemTotal) {
    final applicableArea = _getApplicableDeliveryArea();
    if (applicableArea == null) return 0.0; // Fallback

    if (applicableArea.ruleType == 'free') {
      return 0.0;
    } else if (applicableArea.ruleType == 'flat_plus_free_above') {
      if (applicableArea.freeShippingThreshold != null &&
          itemTotal >= applicableArea.freeShippingThreshold!) {
        return 0.0;
      }
      return applicableArea.deliveryCharge;
    } else {
      // 'flat' or any other
      return applicableArea.deliveryCharge;
    }
  }

  Widget _buildFreeShippingProgress(double itemTotal, DeliveryAreaModel area) {
    if (area.ruleType != 'flat_plus_free_above' ||
        area.freeShippingThreshold == null) {
      return const SizedBox.shrink();
    }

    final double threshold = area.freeShippingThreshold!;
    final double progress = (itemTotal / threshold).clamp(0.0, 1.0);
    final double remaining = threshold - itemTotal;
    final bool isFree = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFree ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree
              ? AppColors.primaryGreen.withOpacity(0.4)
              : Colors.grey.shade200,
        ),
        boxShadow: isFree
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isFree ? AppColors.primaryGreen : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFree ? Icons.check : Icons.local_shipping_outlined,
                  color: isFree ? Colors.white : Colors.blue.shade700,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isFree
                      ? "Free Delivery Unlocked"
                      : "Add ₹${remaining.toInt()} more to unlock Free Delivery",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isFree ? AppColors.primaryGreen : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (!isFree) ...[
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                    minHeight: 6,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>().currentCustomer;
    if (_selectedAddress == null &&
        customer != null &&
        customer.savedAddresses != null &&
        customer.savedAddresses!.isNotEmpty) {
      try {
        _selectedAddress = customer.savedAddresses!.firstWhere(
          (addr) => addr.isDefault,
        );
      } catch (_) {
        _selectedAddress = customer.savedAddresses!.first;
      }
    }

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final groupedItems = cartProvider.getStoreGroupedItems();
        final items = groupedItems[widget.storeId] ?? [];

        if (items.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.pop(context);
            }
          });
          return Scaffold(
            appBar: AppBar(title: const Text("Checkout")),
            body: const Center(child: Text("Cart is empty for this store.")),
          );
        }

        final storeName = items.first.storeName;
        final itemTotal = cartProvider.getStoreTotal(widget.storeId);

        final applicableArea = _getApplicableDeliveryArea();
        final double deliveryFee = _calculateDeliveryFee(itemTotal);
        final double platformFee = 9.0;
        final double toPay = itemTotal + deliveryFee + platformFee;

        final bool isStateRestricted =
            _store != null &&
            !_store!.canSellPanIndia &&
            _store!.state.isNotEmpty &&
            _selectedAddress != null &&
            _selectedAddress!.state.toLowerCase().trim() !=
                _store!.state.toLowerCase().trim();

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
              "Checkout",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Address Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Delivering to",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_selectedAddress == null)
                                    const Text(
                                      "No address selected",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  else ...[
                                    Text(
                                      _selectedAddress!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedAddress!.formattedAddress,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: _showAddressBottomSheet,
                              child: Text(
                                _selectedAddress == null ? "Select" : "Change",
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (isStateRestricted) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_off_rounded,
                                color: Colors.red.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Items from this store cannot be delivered to ${_selectedAddress!.state}.\nThis vendor only delivers within ${_store!.state}.",
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Free Shipping Progress Bar
                      if (applicableArea != null)
                        _buildFreeShippingProgress(itemTotal, applicableArea),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => StoreScreen(
                                              storeId: widget.storeId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child:
                                                _store != null &&
                                                    _store!.logoUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: _store!.logoUrl,
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (context, url) =>
                                                            Container(
                                                              color: Colors
                                                                  .grey
                                                                  .shade100,
                                                              width: 48,
                                                              height: 48,
                                                            ),
                                                    errorWidget:
                                                        (
                                                          context,
                                                          url,
                                                          error,
                                                        ) => Container(
                                                          color: Colors
                                                              .grey
                                                              .shade100,
                                                          width: 48,
                                                          height: 48,
                                                          child: const Icon(
                                                            Icons.storefront,
                                                            color: AppColors
                                                                .primaryGreen,
                                                          ),
                                                        ),
                                                  )
                                                : Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.storefront,
                                                      color: AppColors
                                                          .primaryGreen,
                                                      size: 24,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  storeName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "${cartProvider.getStoreItemCount(widget.storeId)} items",
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "Delivery by",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _calculateDeliveryDate(items),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _selectedAddress == null
                                              ? Colors.grey.shade600
                                              : AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Items
                            ...items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProductDetailsScreen(
                                                    productId: item.productId,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl: item.imageUrl,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      width: 64,
                                                      height: 64,
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                          width: 64,
                                                          height: 64,
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.variantLabel,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    "₹${item.price.toInt()}",
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .primaryGreen,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              cartProvider.decrementQuantity(
                                                item.cartItemId,
                                              );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              if (item.quantity >= 10) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Maximum limit of 10 per item reached.',
                                                    ),
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              cartProvider.incrementQuantity(
                                                item.cartItemId,
                                              );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 16,
                                                color: AppColors.primaryGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StoreScreen(storeId: widget.storeId),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: AppColors.primaryGreen,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Add more items from this store",
                                      style: TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Instructions
                      InkWell(
                        onTap: _showInstructionsBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_note,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _deliveryInstructions.isEmpty
                                    ? const Row(
                                        children: [
                                          Text(
                                            "Add Instructions ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "(Optional)",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Instructions",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _deliveryInstructions,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              Icon(
                                _deliveryInstructions.isEmpty
                                    ? Icons.chevron_right
                                    : Icons.edit,
                                color: Colors.grey,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Bill Details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Bill Details",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildBillRow(
                              "Item Total",
                              "₹${itemTotal.toInt()}",
                            ),
                            const SizedBox(height: 12),
                            _buildBillRow(
                              "Delivery Fee",
                              deliveryFee == 0
                                  ? "FREE"
                                  : "₹${deliveryFee.toInt()}",
                              valueColor: deliveryFee == 0
                                  ? AppColors.primaryGreen
                                  : Colors.black87,
                            ),
                            const SizedBox(height: 12),
                            _buildBillRow(
                              "Platform Fee",
                              "₹${platformFee.toInt()}",
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "To Pay",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "₹${toPay.toInt()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_isLoading || isStateRestricted)
                          ? null
                          : _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isStateRestricted
                            ? Colors.grey.shade400
                            : AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isStateRestricted
                                      ? "Address Not Deliverable"
                                      : "Proceed to Payment",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (!isStateRestricted)
                                  Text(
                                    "₹${toPay.toInt()}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
