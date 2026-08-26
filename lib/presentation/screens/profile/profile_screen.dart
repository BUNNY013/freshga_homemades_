import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/customer_provider.dart';
import '../../../../providers/following_provider.dart';
import '../../../../providers/wishlist_provider.dart';
import '../../../../screens/customer_home_screen.dart';
import '../../../../screens/dev/seeder_screen.dart';
import '../../../../screens/login_screen.dart';
import '../wishlist/liked_products_screen.dart';
import 'settings_screen.dart';
import 'address_book_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'customer_tickets_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('profile.title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Consumer3<CustomerProvider, FollowingProvider, WishlistProvider>(
        builder: (context, customerProvider, followingProvider, wishlistProvider, child) {
          final customer = customerProvider.currentCustomer;
          final uid = customer?.uid ?? FirebaseAuth.instance.currentUser?.uid;
          final name = customer?.fullName ?? 'Taste Explorer';
          final phone = customer?.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '+91';
          final email = customer?.email ?? 'Not set';
          final addressesCount = customer?.savedAddresses?.length ?? 0;
          final followingCount = followingProvider.followingStoreIds.length;
          final wishlistCount = wishlistProvider.likedProducts.length;

          return StreamBuilder<QuerySnapshot>(
            stream: uid == null
                ? Stream.empty()
                : FirebaseFirestore.instance
                    .collection('orders')
                    .where('customerId', isEqualTo: uid)
                    .snapshots(),
            builder: (context, ordersSnap) {
              final ordersCount = ordersSnap.hasData ? ordersSnap.data!.docs.length : 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 1. Hero Header Card
                    _buildHeroCard(context, name, phone, email, ordersCount, followingCount, wishlistCount),
                    const SizedBox(height: 24),

                // 2. My Account & Activity Section
                _buildSectionTitle('My Account & Activity'),
                const SizedBox(height: 10),
                _buildSectionCard([
                  _buildMenuTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'profile.my_orders'.tr(),
                    subtitle: 'Track active orders and reorder homemade favorites',
                    onTap: () {
                      CustomerHomeScreen.globalKey.currentState?.switchTab(3);
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.location_on_outlined,
                    title: 'Saved Delivery Addresses',
                    subtitle: '$addressesCount saved address(es)',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Following Kitchens',
                    subtitle: '$followingCount followed homemade store(s)',
                    onTap: () {
                      CustomerHomeScreen.globalKey.currentState?.switchTab(2);
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.favorite_rounded,
                    title: 'profile.wishlist'.tr(),
                    subtitle: '$wishlistCount homemade specialty(ies) saved',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedProductsScreen()));
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                // 3. App Settings Section
                _buildSectionTitle('App Settings & Preferences'),
                const SizedBox(height: 10),
                _buildSectionCard([
                  _buildMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'General App Settings',
                    subtitle: 'Theme & Cache management',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.language_rounded,
                    title: 'profile.app_language'.tr(),
                    subtitle: 'Choose your preferred language',
                    onTap: () => _showLanguageSelector(context),
                  ),

                ]),

                const SizedBox(height: 24),

                // 4. Support & Information
                _buildSectionTitle('Support & Information'),
                const SizedBox(height: 10),
                _buildSectionCard([
                  _buildMenuTile(
                    icon: Icons.support_agent_rounded,
                    title: 'profile.support'.tr(),
                    subtitle: 'View your submitted queries and resolutions',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerTicketsScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'Frequently asked questions & WhatsApp support',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'profile.about'.tr(),
                    subtitle: 'FSSAI compliance, Terms of Service & Privacy Policy',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                // 5. Account Actions
                _buildSectionTitle('Account Actions'),
                const SizedBox(height: 10),
                _buildSectionCard([
                  _buildMenuTile(
                    icon: Icons.logout_rounded,
                    title: 'profile.logout'.tr(),
                    subtitle: 'Sign out of your account safely',
                    iconColor: Colors.orange,
                    onTap: () => _showLogoutConfirm(context),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove account and data',
                    iconColor: Colors.red,
                    onTap: () => _showDeleteConfirm(context),
                  ),
                ]),

                const SizedBox(height: 36),
                const Text(
                  'FreshGa Homemades v1.0.0 (Beta)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, String name, String phone, String email, int ordersCount, int followingCount, int wishlistCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar Circle
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'F',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showEditProfileModal(context, name, email),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    if (email != 'Not set') ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Quick Interactive Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBadge('$ordersCount', 'Orders', () => CustomerHomeScreen.globalKey.currentState?.switchTab(3)),
              _buildMetricBadge('$wishlistCount', 'Favourites', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedProductsScreen()))),
              _buildMetricBadge('$followingCount', 'Following', () => CustomerHomeScreen.globalKey.currentState?.switchTab(2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String val, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primaryGreen,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  void _showEditProfileModal(BuildContext context, String initialName, String initialEmail) {
    final nameCtrl = TextEditingController(text: initialName == 'Taste Explorer' ? '' : initialName);
    final emailCtrl = TextEditingController(text: initialEmail == 'Not set' ? '' : initialEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final provider = context.read<CustomerProvider>();
                  await provider.updateProfile(
                    fullName: nameCtrl.text.trim().isEmpty ? 'Taste Explorer' : nameCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Log Out?'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out of your FreshGa account?'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Log Out'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('This action is irreversible. All saved delivery addresses, following preferences, and order history associated with your number will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('English'),
                trailing: context.locale.languageCode == 'en' ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
                onTap: () {
                  context.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('हिंदी (Hindi)'),
                trailing: context.locale.languageCode == 'hi' ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
                onTap: () {
                  context.setLocale(const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('తెలుగు (Telugu)'),
                trailing: context.locale.languageCode == 'te' ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
                onTap: () {
                  context.setLocale(const Locale('te'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }
}
