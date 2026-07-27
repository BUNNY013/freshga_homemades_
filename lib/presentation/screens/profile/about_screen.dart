import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About FreshGa Homemades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo / App Icon Badge
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.home_work_rounded, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'FreshGa Homemades',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'v1.0.0 (Beta Build)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Empowering local homemade artisans and bringing authentic, hygienic, and tradition-rich foods directly from verified homemakers to your doorstep.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Features Card
            _buildSectionCard([
              _buildTile(
                icon: Icons.verified_user_outlined,
                title: 'FSSAI Registered Artisans',
                subtitle: 'All homemade vendors follow strict food safety guidelines.',
              ),
              const Divider(height: 1),
              _buildTile(
                icon: Icons.favorite_border_rounded,
                title: '100% Authentic & Homemade',
                subtitle: 'No preservatives, made fresh in small batches.',
              ),
              const Divider(height: 1),
              _buildTile(
                icon: Icons.local_shipping_outlined,
                title: 'Direct from Home Kitchens',
                subtitle: 'Freshly packed and safely delivered to your address.',
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionCard([
              _buildLinkTile(
                context,
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => _showLegalDialog(
                  context,
                  'Terms of Service',
                  '1. Use of the FreshGa Homemades app constitutes acceptance of our marketplace terms.\n2. Orders placed with homemade artisans are prepared freshly to order.\n3. Platform fees and delivery charges apply as shown at checkout.',
                ),
              ),
              const Divider(height: 1),
              _buildLinkTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _showLegalDialog(
                  context,
                  'Privacy Policy',
                  'We value your privacy. Your contact and delivery address information is only shared with the homemade vendor and assigned delivery partner for the purpose of completing your order.',
                ),
              ),
              const Divider(height: 1),
              _buildLinkTile(
                context,
                icon: Icons.workspace_premium_outlined,
                title: 'FSSAI Compliance Pledge',
                onTap: () => _showLegalDialog(
                  context,
                  'FSSAI Compliance Pledge',
                  'FreshGa ensures all onboarded homemade suppliers hold valid FSSAI registration or licensing appropriate for homemade food businesses.',
                ),
              ),
            ]),

            const SizedBox(height: 32),
            Text(
              'Made with ❤️ for Homemakers & Food Lovers',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
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

  Widget _buildTile({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(height: 1.4, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
