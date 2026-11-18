import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_colors.dart';
import '../config/app_routes.dart';
import '../models/local_models.dart';
import '../services/local_db.dart';
import '../services/google_drive_backup_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/user_identity.dart';
import 'widgets/help_topic.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserEntity?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userFuture = _loadUser();
  }

  Future<UserEntity?> _loadUser() async {
    final db = await LocalDb.instance.open();
    final profile = await UserIdentityService.instance.getProfile();
    return db.getUserByUserId(profile.userId);
  }

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
                      AppColors.primaryViolet.withValues(alpha: 0.35),
                      AppColors.primaryDeep.withValues(alpha: 0.0),
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
                    FutureBuilder<UserEntity?>(
                      future: _userFuture,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                backgroundImage: _profileImage(user?.photoUrl),
                                child: user?.photoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppColors.textSecondary,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user?.displayName ?? 'Your Profile',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                user?.email ?? 'Premium Member',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Account Settings Section
                    _buildSectionHeader('Account Settings'),
                    const SizedBox(height: 12),
                    _buildProfileMenuItem(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'Update your profile details',
                      onTap: () async {
                        await Navigator.of(context)
                            .pushNamed(AppRoutes.personalInformation);
                        if (mounted) {
                          setState(() {
                            _userFuture = _loadUser();
                          });
                        }
                      },
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

                    // Preferences
                    _buildSectionHeader('Preferences'),
                    const SizedBox(height: 12),
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
                      icon: Icons.category,
                      title: 'Manage Categories',
                      subtitle: 'Edit or remove categories',
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRoutes.manageCategories);
                      },
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.swap_horiz,
                      title: 'Transfer fees',
                      subtitle: 'Choose an expense category for fees',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.transferFeeSettings),
                    ),
                    _buildGoogleBackupMenuItem(),

                    const SizedBox(height: 24),

                    // Support & Info
                    _buildSectionHeader('Support & Info'),
                    const SizedBox(height: 12),
                    _buildProfileMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'FAQs & support',
                      onTap: _openHelpCenter,
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
                      subtitle: 'App version 1.0.4',
                      onTap: _openAboutUs,
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

  ImageProvider? _profileImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }
    return NetworkImage(photoUrl);
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
                    color: Colors.white.withValues(alpha: 0.08),
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

  Widget _buildGoogleBackupMenuItem() {
    return FutureBuilder<GoogleDriveBackupStatus>(
      future: GoogleDriveBackupService.instance.status(),
      builder: (context, snapshot) {
        final backup = snapshot.data;
        final subtitle = backup == null || !backup.connected
            ? 'Optional — not connected'
            : backup.sizeBytes == null
                ? 'Connected • No backup yet'
                : 'Connected • ${_formatBytes(backup.sizeBytes!)} • Last: ${_formatTimestamp(context, backup.modifiedAt)}';
        return _buildProfileMenuItem(
          icon: Icons.backup_outlined,
          title: 'Google Drive Backup',
          subtitle: subtitle,
          onTap: _openGoogleBackup,
        );
      },
    );
  }

  Future<void> _openGoogleBackup() async {
    final backup = GoogleDriveBackupService.instance;
    final status = await backup.status();
    if (!mounted) return;
    if (!status.connected) {
      final remote = await backup.connect();
      if (!mounted) return;
      setState(() {});
      if (remote != null) {
        final restore = await _confirmRestore(remote);
        if (restore == true) await _restoreGoogleBackup(remote);
      } else {
        _showInfo(
            context, 'Google Drive connected. No existing backup was found.');
      }
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          if (status.modifiedAt != null)
            ListTile(
              leading:
                  const Icon(Icons.schedule, color: AppColors.textSecondary),
              title: const Text('Last backup',
                  style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(
                _formatTimestamp(context, status.modifiedAt),
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ListTile(
            leading:
                const Icon(Icons.cloud_upload, color: AppColors.textPrimary),
            title: const Text('Back up now',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(context, 'backup'),
          ),
          SwitchListTile(
            value: status.automaticBackup,
            title: const Text('Automatic backup after sync',
                style: TextStyle(color: AppColors.textPrimary)),
            onChanged: (value) {
              Navigator.pop(context, value ? 'enable-auto' : 'disable-auto');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Disconnect Google',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => Navigator.pop(context, 'disconnect'),
          ),
        ]),
      ),
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'backup') {
        final db = await LocalDb.instance.open();
        await backup.backupNow(db);
        if (mounted) {
          _showInfo(context, 'Backup completed.');
        }
      } else if (action == 'disconnect') {
        await backup.disconnect();
      } else {
        await backup.setAutomaticBackup(action == 'enable-auto');
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) _showInfo(context, error.toString());
    }
  }

  Future<bool?> _confirmRestore(GoogleDriveRemoteBackup backup) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Restore backup?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'A Google Drive backup (${_formatBytes(backup.sizeBytes)}) was found. Restoring it will permanently overwrite all current data on this device.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore')),
        ],
      ),
    );
  }

  Future<void> _restoreGoogleBackup(GoogleDriveRemoteBackup backup) async {
    try {
      await GoogleDriveBackupService.instance.restore(backup);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('Restore complete',
              style: TextStyle(color: AppColors.textPrimary)),
          content: const Text('Restart Ortho to safely load the restored data.',
              style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Close app'))
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showInfo(context, error.toString());
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _openHelpCenter() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Help Center',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 16),
              HelpTopic(
                question: 'How is my data saved?',
                answer:
                    'Your data is stored securely on this device. If sync is enabled, changes are also sent to your connected Supabase account.',
              ),
              HelpTopic(
                question: 'How do Google Drive backups work?',
                answer:
                    'Google Drive is optional. A backup is stored in the private app-data area of the Google account you connect. You can back up manually or after every successful sync.',
              ),
              HelpTopic(
                question: 'How can I restore on a new device?',
                answer:
                    'Connect the same Google account from Google Drive Backup. If a backup is found, Ortho will ask whether you want to restore it and warn you before replacing local data.',
              ),
              HelpTopic(
                question: 'Why is a transaction missing?',
                answer:
                    'Pull to refresh the Home screen. If sync is enabled, open Data Status and use Push or Download to check the latest data.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAboutUs() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('About Ortho',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 14),
              Text(
                  'Ortho helps you track income, expenses, accounts, and budgets in one place.',
                  style:
                      TextStyle(color: AppColors.textSecondary, height: 1.45)),
              SizedBox(height: 12),
              Text(
                  'Your financial data stays under your control with local SQLite storage, optional Supabase sync, and optional Google Drive backups.',
                  style:
                      TextStyle(color: AppColors.textSecondary, height: 1.45)),
              SizedBox(height: 20),
              Text('Version 1.0.4',
                  style: TextStyle(
                      color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            ],
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

    final userIdFuture = UserIdentityService.instance.getProfile().then((
      profile,
    ) {
      final authId = SupabaseService().getCurrentUser()?.id;
      return authId ?? profile.userId;
    });
    var statusFuture =
        userIdFuture.then((userId) => sync.getStatus(userId: userId));
    var pendingFuture =
        userIdFuture.then((userId) => sync.getPendingSyncs(userId: userId));
    var isPushing = false;
    var isDownloading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void refresh() {
              setState(() {
                statusFuture = userIdFuture
                    .then((userId) => sync.getStatus(userId: userId));
                pendingFuture = userIdFuture
                    .then((userId) => sync.getPendingSyncs(userId: userId));
              });
            }

            Future<void> runManualSync({
              required bool download,
            }) async {
              setState(() {
                if (download) {
                  isDownloading = true;
                } else {
                  isPushing = true;
                }
              });

              try {
                final userId = await userIdFuture;
                if (download) {
                  await sync.downloadRemoteSnapshot(userId: userId);
                } else {
                  await sync.pushLocalChanges(userId: userId);
                }
                if (context.mounted) {
                  _showInfo(
                    context,
                    download
                        ? 'Downloaded latest Supabase data.'
                        : 'Local changes pushed to Supabase.',
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  _showInfo(context, error.toString());
                }
              } finally {
                if (context.mounted) {
                  setState(() {
                    isPushing = false;
                    isDownloading = false;
                    statusFuture = userIdFuture
                        .then((userId) => sync.getStatus(userId: userId));
                    pendingFuture = userIdFuture.then(
                      (userId) => sync.getPendingSyncs(userId: userId),
                    );
                  });
                }
              }
            }

            return FractionallySizedBox(
              heightFactor: 0.82,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
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
                            onPressed: refresh,
                            icon: const Icon(
                              Icons.refresh,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<SyncStatus>(
                        future: statusFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Text(
                              'Unable to load status.',
                              style: TextStyle(color: AppColors.textMuted),
                            );
                          }

                          final status = snapshot.data ??
                              const SyncStatus(
                                localLastUpdated: null,
                                remoteLastUpdated: null,
                              );

                          final headline = _statusHeadline(status);
                          final localLabel = _formatTimestamp(
                            context,
                            status.localLastUpdated,
                          );
                          final remoteLabel = _formatTimestamp(
                            context,
                            status.remoteLastUpdated,
                          );
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
                              _statusRow('Local (SQLite)', localLabel),
                              _statusRow('Remote (Supabase)', remoteLabel),
                              _statusRow(
                                'Pending sync',
                                status.pendingOutboxCount.toString(),
                              ),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _syncActionButton(
                              icon: Icons.cloud_upload_outlined,
                              label: 'Push local',
                              isLoading: isPushing,
                              onPressed: isDownloading || isPushing
                                  ? null
                                  : () => runManualSync(download: false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _syncActionButton(
                              icon: Icons.cloud_download_outlined,
                              label: 'Download',
                              isLoading: isDownloading,
                              onPressed: isDownloading || isPushing
                                  ? null
                                  : () => runManualSync(download: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Pending syncs',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<PendingSync>>(
                        future: pendingFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Text(
                              'Unable to load pending syncs.',
                              style: TextStyle(color: AppColors.textMuted),
                            );
                          }

                          final pending =
                              snapshot.data ?? const <PendingSync>[];
                          if (pending.isEmpty) {
                            return const Text(
                              'No pending syncs.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            );
                          }

                          return Column(
                            children: pending
                                .map(
                                  (entry) => _pendingSyncTile(context, entry),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _syncActionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _pendingSyncTile(BuildContext context, PendingSync entry) {
    final attemptedAt = _formatTimestamp(context, entry.lastAttemptAt);
    final hasError = entry.errorMessage != null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (hasError ? Colors.redAccent : AppColors.primaryPurple)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (hasError ? Colors.redAccent : AppColors.primaryPurple)
              .withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasError ? Icons.error_outline : Icons.schedule_outlined,
                color: hasError ? Colors.redAccent : AppColors.primaryPurple,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.entityType} ${entry.action}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${entry.attempts}x',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Text(
              entry.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${entry.entityId} - $attemptedAt',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
      return '-';
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
