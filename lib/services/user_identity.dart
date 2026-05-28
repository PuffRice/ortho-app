import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdentityProfile {
  const UserIdentityProfile({
    required this.userId,
    required this.email,
    required this.displayName,
  });

  final String userId;
  final String email;
  final String displayName;
}

class UserIdentityService {
  UserIdentityService._();

  static final UserIdentityService instance = UserIdentityService._();

  static const String _userIdKey = 'local_user_id';
  static const String _emailKey = 'local_user_email';
  static const String _displayNameKey = 'local_user_display_name';

  Future<UserIdentityProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_userIdKey);
    var email = prefs.getString(_emailKey);
    var displayName = prefs.getString(_displayNameKey);

    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_userIdKey, userId);
    }

    email ??= _buildEmail(userId);
    displayName ??= _buildDisplayName(userId);

    await prefs.setString(_emailKey, email);
    await prefs.setString(_displayNameKey, displayName);

    return UserIdentityProfile(
      userId: userId,
      email: email,
      displayName: displayName,
    );
  }

  Future<void> updateProfile({
    required String email,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_displayNameKey, displayName);
  }

  String _buildEmail(String userId) {
    final suffix = userId.split('-').first;
    return 'device-$suffix@local';
  }

  String _buildDisplayName(String userId) {
    final suffix = userId.split('-').first.toUpperCase();
    return 'Device $suffix';
  }
}
