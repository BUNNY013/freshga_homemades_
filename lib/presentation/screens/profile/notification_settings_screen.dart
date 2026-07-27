import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/customer_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late Map<String, bool> _preferences;

  @override
  void initState() {
    super.initState();
    final customer = context.read<CustomerProvider>().currentCustomer;
    _preferences = Map<String, bool>.from(
      customer?.notificationPreferences ?? {
        'order_updates': true,
        'followed_stores': true,
        'promotional_offers': true,
        'whatsapp_alerts': false,
      },
    );
  }

  void _toggle(String key, bool val) async {
    setState(() {
      _preferences[key] = val;
    });
    await context.read<CustomerProvider>().updateNotificationPreferences(_preferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose what notifications you want to receive from FreshGa Homemades.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildSectionCard([
              _buildSwitchTile(
                title: 'Order Status Updates',
                subtitle: 'Get live alerts when your homemade order is accepted, prepared, and out for delivery.',
                icon: Icons.delivery_dining_rounded,
                value: _preferences['order_updates'] ?? true,
                onChanged: (val) => _toggle('order_updates', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'Followed Store Batches',
                subtitle: 'Be the first to know when your followed homemade artisans drop a fresh batch.',
                icon: Icons.favorite_rounded,
                value: _preferences['followed_stores'] ?? true,
                onChanged: (val) => _toggle('followed_stores', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'Promotional Offers & Discounts',
                subtitle: 'Receive festive specials, seasonal pickle alerts, and exclusive discounts.',
                icon: Icons.local_offer_rounded,
                value: _preferences['promotional_offers'] ?? true,
                onChanged: (val) => _toggle('promotional_offers', val),
              ),
            ]),

            const SizedBox(height: 24),
            const Text(
              'Messaging Channels',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildSectionCard([
              _buildSwitchTile(
                title: 'WhatsApp Alerts',
                subtitle: 'Receive digital invoices and instant delivery tracking updates on your WhatsApp number.',
                icon: Icons.chat_bubble_rounded,
                value: _preferences['whatsapp_alerts'] ?? false,
                onChanged: (val) => _toggle('whatsapp_alerts', val),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
      ),
    );
  }
}
