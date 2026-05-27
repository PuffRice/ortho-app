import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_routes.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/user_identity.dart';

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
                      icon: Icons.sync,
                      title: 'Data Status',
                      subtitle: 'Local vs Supabase freshness',
                      onTap: () => _openDataStatusSheet(context),
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

  void _openDataStatusSheet(BuildContext context) {
    final sync = SyncService.instance;
    if (sync == null) {
      _showInfo(context, 'Sync service is not configured.');
      return;
    }

    final userIdFuture = UserIdentityService.instance
        .getProfile()
        .then((profile) => profile.userId);
    var statusFuture = userIdFuture.then((userId) {
      final authId = SupabaseService().getCurrentUser()?.id;
      return sync.getStatus(userId: authId ?? userId);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Data Status',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            statusFuture = userIdFuture.then((userId) {
                              final authId =
                                  SupabaseService().getCurrentUser()?.id;
                              return sync.getStatus(userId: authId ?? userId);
                            });
                          });
                        },
                        icon: const Icon(Icons.refresh,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<SyncStatus>(
                    future: statusFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Unable to load status.',
                          style: const TextStyle(color: AppColors.textMuted),
                        );
                      }

                      final status = snapshot.data ??
                          const SyncStatus(
                            localLastUpdated: null,
                            remoteLastUpdated: null,
                          );

                      final headline = _statusHeadline(status);
                      final localLabel =
                          _formatTimestamp(context, status.localLastUpdated);
                      final remoteLabel =
                          _formatTimestamp(context, status.remoteLastUpdated);
                      final lagText = _formatLag(
                        status.localLastUpdated,
                        status.remoteLastUpdated,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _statusRow('Local (Isar)', localLabel),
                          _statusRow('Remote (Supabase)', remoteLabel),
                          _statusRow(
                            'Pending sync',
                            status.pendingOutboxCount.toString(),
                          ),
                          if (status.lastSyncError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Last sync error: ${status.lastSyncError}',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (lagText != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              lagText,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  String _statusHeadline(SyncStatus status) {
    if (status.pendingOutboxCount > 0) {
      return 'Local changes are waiting to sync';
    }
    if (status.localLastUpdated == null && status.remoteLastUpdated == null) {
      return 'No data yet';
    }
    if (status.isRemoteNewer) {
      return 'Supabase is ahead';
    }
    if (status.isLocalNewer) {
      return 'Local is ahead';
    }
    return 'Local and Supabase are in sync';
  }

  String _formatTimestamp(BuildContext context, DateTime? value) {
    if (value == null) {
      return '—';
    }
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date $time';
  }

  String? _formatLag(DateTime? local, DateTime? remote) {
    if (local == null || remote == null) {
      return null;
    }
    if (local.isAtSameMomentAs(remote)) {
      return null;
    }
    final isRemoteAhead = remote.isAfter(local);
    final diff =
        isRemoteAhead ? remote.difference(local) : local.difference(remote);
    final label = _formatDuration(diff);
    return isRemoteAhead
        ? 'Supabase leads by $label.'
        : 'Local leads by $label.';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays >= 1) {
      final days = duration.inDays;
      return '$days day${days == 1 ? '' : 's'}';
    }
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    return 'moments';
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.bgSecondary,
      ),
    );
  }
}
