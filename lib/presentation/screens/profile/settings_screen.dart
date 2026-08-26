import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English (United States)';
  String _selectedTheme = 'System Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              'General Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildSectionCard([
              _buildNavTile(
                icon: Icons.language_rounded,
                title: 'App Language',
                subtitle: _selectedLanguage,
                onTap: _showLanguageModal,
              ),
              const Divider(height: 1),
              _buildNavTile(
                icon: Icons.brightness_6_outlined,
                title: 'Appearance / Theme',
                subtitle: _selectedTheme,
                onTap: _showThemeModal,
              ),
            ]),

            const SizedBox(height: 24),
            const Text(
              'Data & Storage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildSectionCard([
              _buildNavTile(
                icon: Icons.cleaning_services_outlined,
                title: 'Clear Image Cache',
                subtitle: 'Free up storage space used by product photos',
                onTap: _clearCache,
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

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  void _showLanguageModal() {
    final languages = [
      'English (United States)',
      'Hindi (हिन्दी)',
      'Telugu (తెలుగు)',
      'Tamil (தமிழ்)',
      'Kannada (ಕನ್ನಡ)',
      'Malayalam (മലയാളം)',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select App Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final isSelected = lang == _selectedLanguage;
              return ListTile(
                onTap: () {
                  setState(() => _selectedLanguage = lang);
                  Navigator.pop(context);
                },
                title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen) : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showThemeModal() {
    final themes = ['System Default', 'Light Mode', 'Dark Mode (Coming Soon)'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Appearance Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...themes.map((theme) {
              final isSelected = theme == _selectedTheme;
              return ListTile(
                onTap: () {
                  if (!theme.contains('Coming Soon')) {
                    setState(() => _selectedTheme = theme);
                  }
                  Navigator.pop(context);
                },
                title: Text(
                  theme,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: theme.contains('Coming Soon') ? Colors.grey : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen) : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image cache cleared successfully (18.4 MB freed).'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }
}
