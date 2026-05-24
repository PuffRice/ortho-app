import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: -360,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 720,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryViolet.withOpacity(0.35),
                      AppColors.primaryDeep.withOpacity(0.0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: AppColors.textSecondary,
                        ),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Profile Section
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            child: const Icon(Icons.person,
                                size: 50, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'John Doe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Premium Member',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Account Settings Section
                    _buildSectionHeader('Account Settings'),
                    const SizedBox(height: 12),
                    _buildProfileMenuItem(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'Update your profile details',
                      onTap: () {},
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Security',
                      subtitle: 'Password & authentication',
                      onTap: () {},
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Manage alerts & updates',
                      onTap: () {},
                    ),

                    const SizedBox(height: 24),

                    // Payment Settings
                    _buildSectionHeader('Payment Methods'),
                    const SizedBox(height: 12),
                    _buildProfileMenuItem(
                      icon: Icons.credit_card,
                      title: 'Bank Accounts',
                      subtitle: 'Manage your bank connections',
                      onTap: () {},
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.account_balance_wallet,
                      title: 'Manage Accounts',
                      subtitle: 'Edit or remove your accounts',
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRoutes.manageAccounts);
                      },
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.payment,
                      title: 'Payment Cards',
                      subtitle: 'Add or remove payment cards',
                      onTap: () {},
                    ),

                    const SizedBox(height: 24),

                    // Preferences
                    _buildSectionHeader('Preferences'),
                    const SizedBox(height: 12),
                    _buildProfileMenuItem(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.category,
                      title: 'Manage Categories',
                      subtitle: 'Edit or remove categories',
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRoutes.manageCategories);
                      },
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.brightness_4,
                      title: 'Theme',
                      subtitle: 'Dark mode',
                      onTap: () {},
                    ),

                    const SizedBox(height: 24),

                    // Support & Info
                    _buildSectionHeader('Support & Info'),
                    const SizedBox(height: 12),
                    _buildProfileMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'FAQs & support',
                      onTap: () {},
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.info_outline,
                      title: 'About Us',
                      subtitle: 'App version 1.0.0',
                      onTap: () {},
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Space for floating navbar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
