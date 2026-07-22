import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../screens/customer_home_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final double amountPaid;
  final String paymentMethod;
  final DateTime date;

  const OrderSuccessScreen({
    Key? key,
    required this.orderId,
    required this.amountPaid,
    required this.paymentMethod,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd MMM, yyyy').format(date);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Success Animation / Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle confetti elements
                  ...List.generate(8, (index) {
                    final isEven = index % 2 == 0;
                    return Transform.translate(
                      offset: Offset(
                        (index * 20.0 - 70) * (isEven ? 1 : -1),
                        (index * 15.0 - 50) * (isEven ? -1 : 1)
                      ),
                      child: Container(
                        width: isEven ? 6.0 : 4.0,
                        height: isEven ? 6.0 : 4.0,
                        decoration: BoxDecoration(
                          color: [Colors.green, Colors.orange, Colors.red, Colors.teal][index % 4],
                          shape: index % 3 == 0 ? BoxShape.rectangle : BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 60),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Text
              const Text(
                "Payment Successful!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Your order has been placed successfully.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Order Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 20),
                    _buildSummaryRow("Order ID", "#$orderId"),
                    const SizedBox(height: 16),
                    _buildSummaryRow("Date", formattedDate),
                    const SizedBox(height: 16),
                    _buildSummaryRow("Amount Paid", "₹${amountPaid.toInt()}"),
                    const SizedBox(height: 16),
                    _buildSummaryRow("Payment Method", paymentMethod),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Order Details (Placeholder for now, going to home)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("View Order Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: () {
                    // Navigate back to Home
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                      (route) => false,
                    );
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Continue Shopping", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
