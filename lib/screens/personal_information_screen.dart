import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../cqrs/commands.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';
import '../services/local_db.dart';
import '../services/supabase_service.dart';
import '../services/user_identity.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  static const String _bucket = 'profile-photos';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _picker = ImagePicker();

  late Future<void> _loadFuture;
  UserIdentityProfile? _identity;
  UserEntity? _user;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _pickedImageMimeType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final identity = await UserIdentityService.instance.getProfile();
    final db = await LocalDb.instance.open();
    final user = await db.getUserByUserId(identity.userId);

    _identity = identity;
    _user = user;
    _nameController.text = user?.displayName ?? identity.displayName;
    _emailController.text = user?.email ?? identity.email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: -320,
            left: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                height: 650,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryViolet.withOpacity(0.36),
                      AppColors.accentPink.withOpacity(0.08),
                      AppColors.primaryDeep.withOpacity(0.0),
                    ],
                    stops: const [0, 0.42, 1],
                    radius: 0.82,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<void>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(onRetry: _retryLoad);
                }
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _Header(saving: _saving, onSave: _save),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          children: [
                            const SizedBox(height: 10),
                            Center(
                              child: _AvatarPicker(
                                photoUrl: _user?.photoUrl,
                                pickedImageBytes: _pickedImageBytes,
                                onTap: _pickImage,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _FieldLabel(label: 'Full name'),
                            const SizedBox(height: 8),
                            _ProfileTextField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your name.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            _FieldLabel(label: 'Email address'),
                            const SizedBox(height: 8),
                            _ProfileTextField(
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (!email.contains('@')) {
                                  return 'Enter a valid email.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _InfoCard(
                              text:
                                  'Profile photos are uploaded to Supabase Storage, then the public URL is saved in users.photo_url and mirrored into SQLite during sync.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _retryLoad() {
    setState(() {
      _loadFuture = _loadProfile();
    });
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = image.name;
      _pickedImageMimeType = image.mimeType;
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    final identity = _identity;
    if (identity == null) {
      _showMessage('Profile is not ready yet.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      var photoUrl = _user?.photoUrl;
      if (_pickedImageBytes != null) {
        photoUrl = await _uploadProfilePhoto(
          userId: identity.userId,
          bytes: _pickedImageBytes!,
          fileName: _pickedImageName,
          mimeType: _pickedImageMimeType,
        );
      }

      final email = _emailController.text.trim();
      final displayName = _nameController.text.trim();
      await UserIdentityService.instance.updateProfile(
        email: email,
        displayName: displayName,
      );

      final cqrs = await CqrsService.create();
      await cqrs.bus.execute(
        CreateUserCommand(
          userId: identity.userId,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          now: DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }
      _showMessage('Personal information updated.');
      Navigator.of(context).pop();
    } catch (error) {
      _showMessage('Failed to update profile: $error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<String> _uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String? fileName,
    required String? mimeType,
  }) async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized) {
      throw StateError('Supabase is not configured for photo uploads.');
    }

    final contentType = mimeType ?? _contentTypeFor(fileName);
    final extension = _extensionFor(fileName, contentType);
    final objectPath =
        '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$extension';
    await supabase.client.storage.from(_bucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return supabase.client.storage.from(_bucket).getPublicUrl(objectPath);
  }

  String _contentTypeFor(String? fileName) {
    final lower = fileName?.toLowerCase() ?? '';
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _extensionFor(String? fileName, String contentType) {
    final lower = fileName?.toLowerCase() ?? '';
    if (lower.endsWith('.png')) {
      return 'png';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    if (contentType == 'image/png') {
      return 'png';
    }
    if (contentType == 'image/webp') {
      return 'webp';
    }
    return 'jpg';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.bgSecondary,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          ),
          const Expanded(
            child: Text(
              'Personal Information',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.accentCoral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.photoUrl,
    required this.pickedImageBytes,
    required this.onTap,
  });

  final String? photoUrl;
  final Uint8List? pickedImageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (pickedImageBytes != null) {
      image = MemoryImage(pickedImageBytes!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      image = NetworkImage(photoUrl!);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryViolet,
                  AppColors.accentPink,
                  AppColors.accentOrange,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.32),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.08),
                backgroundImage: image,
                child: image == null
                    ? const Icon(
                        Icons.person,
                        size: 54,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryViolet, AppColors.accentCoral],
                ),
                border: Border.all(color: AppColors.bgPrimary, width: 3),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        errorStyle: const TextStyle(color: AppColors.accentCoral),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.09)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primaryViolet),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accentCoral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accentCoral),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_done_outlined,
            color: AppColors.incomePositive,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.accentCoral),
            const SizedBox(height: 12),
            const Text(
              'Unable to load personal information.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
