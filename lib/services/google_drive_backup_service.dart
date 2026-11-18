import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
import 'local_db.dart';

class GoogleDriveBackupStatus {
  const GoogleDriveBackupStatus({
    required this.connected,
    required this.automaticBackup,
    this.email,
    this.sizeBytes,
    this.modifiedAt,
  });

  final bool connected;
  final bool automaticBackup;
  final String? email;
  final int? sizeBytes;
  final DateTime? modifiedAt;
}

class GoogleDriveRemoteBackup {
  const GoogleDriveRemoteBackup({
    required this.fileId,
    required this.sizeBytes,
    this.modifiedAt,
  });

  final String fileId;
  final int sizeBytes;
  final DateTime? modifiedAt;
}

class GoogleDriveBackupService {
  GoogleDriveBackupService._();
  static final instance = GoogleDriveBackupService._();

  static const _name = 'ortho-backup.sqlite';
  static const _emailKey = 'google_backup_email';
  static const _autoKey = 'google_backup_automatic';
  static const _fileIdKey = 'google_backup_file_id';
  static const _sizeKey = 'google_backup_size';
  static const _modifiedKey = 'google_backup_modified';

  final _signIn = GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]);

  Future<GoogleDriveBackupStatus> status() async {
    final prefs = await SharedPreferences.getInstance();
    final modified = prefs.getString(_modifiedKey);
    return GoogleDriveBackupStatus(
      connected: prefs.containsKey(_emailKey),
      automaticBackup: prefs.getBool(_autoKey) ?? false,
      email: prefs.getString(_emailKey),
      sizeBytes: prefs.getInt(_sizeKey),
      modifiedAt: modified == null ? null : DateTime.tryParse(modified),
    );
  }

  /// Connects an optional Google account and discovers any backup made on
  /// another device with the same account.
  Future<GoogleDriveRemoteBackup?> connect() async {
    final account = await _signIn.signIn();
    if (account == null) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, account.email);
    final backup = await findRemoteBackup();
    if (backup != null) await _saveMetadata(backup);
    return backup;
  }

  Future<void> disconnect() async {
    await _signIn.disconnect();
    final prefs = await SharedPreferences.getInstance();
    for (final key in [_emailKey, _fileIdKey, _sizeKey, _modifiedKey]) {
      await prefs.remove(key);
    }
    await prefs.setBool(_autoKey, false);
  }

  Future<void> setAutomaticBackup(bool enabled) async {
    if (enabled && !(await status()).connected) {
      throw StateError(
          'Connect Google Drive before enabling automatic backup.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoKey, enabled);
  }

  Future<void> backupNow(AppDatabase database) async {
    final client = await _client();
    if (client == null) {
      throw StateError('Connect Google Drive to create a backup.');
    }
    final temporary =
        File('${Directory.systemTemp.path}${Platform.pathSeparator}$_name');
    try {
      if (await temporary.exists()) await temporary.delete();
      await database.backupTo(temporary.path);
      final bytes = await temporary.readAsBytes();
      final api = drive.DriveApi(client);
      final prefs = await SharedPreferences.getInstance();
      final existingId = prefs.getString(_fileIdKey);
      final media = drive.Media(Stream.value(bytes), bytes.length);
      final uploaded = existingId == null
          ? await api.files.create(
              drive.File()
                ..name = _name
                ..parents = ['appDataFolder'],
              uploadMedia: media,
              $fields: 'id,size,modifiedTime',
            )
          : await api.files.update(
              drive.File()..name = _name,
              existingId,
              uploadMedia: media,
              $fields: 'id,size,modifiedTime',
            );
      await _saveMetadata(GoogleDriveRemoteBackup(
        fileId: uploaded.id!,
        sizeBytes: int.tryParse(uploaded.size ?? '') ?? bytes.length,
        modifiedAt: uploaded.modifiedTime ?? DateTime.now().toUtc(),
      ));
    } finally {
      client.close();
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> backupAfterSync(AppDatabase database) async {
    if ((await status()).automaticBackup) await backupNow(database);
  }

  Future<GoogleDriveRemoteBackup?> findRemoteBackup() async {
    final client = await _client();
    if (client == null) return null;
    try {
      final files = (await drive.DriveApi(client).files.list(
                spaces: 'appDataFolder',
                q: "name = '$_name'",
                orderBy: 'modifiedTime desc',
                pageSize: 1,
                $fields: 'files(id,size,modifiedTime)',
              ))
          .files;
      if (files == null || files.isEmpty || files.first.id == null) return null;
      final file = files.first;
      return GoogleDriveRemoteBackup(
        fileId: file.id!,
        sizeBytes: int.tryParse(file.size ?? '') ?? 0,
        modifiedAt: file.modifiedTime,
      );
    } finally {
      client.close();
    }
  }

  /// Replaces all local SQLite data. The caller must restart the app before
  /// accessing the database again.
  Future<void> restore(GoogleDriveRemoteBackup backup) async {
    final client = await _client();
    if (client == null) throw StateError('Google connection has expired.');
    try {
      final media = await drive.DriveApi(client).files.get(
            backup.fileId,
            downloadOptions: drive.DownloadOptions.fullMedia,
          ) as drive.Media;
      final bytes = await _readAll(media.stream);
      await LocalDb.instance.close();
      final path = await AppDatabase.databasePath();
      for (final suffix in ['', '-wal', '-shm']) {
        final file = File('$path$suffix');
        if (await file.exists()) await file.delete();
      }
      await File(path).writeAsBytes(bytes, flush: true);
      await _saveMetadata(backup);
    } finally {
      client.close();
    }
  }

  Future<dynamic> _client() async {
    if (await _signIn.signInSilently() == null) return null;
    return _signIn.authenticatedClient();
  }

  Future<void> _saveMetadata(GoogleDriveRemoteBackup backup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fileIdKey, backup.fileId);
    await prefs.setInt(_sizeKey, backup.sizeBytes);
    if (backup.modifiedAt != null) {
      await prefs.setString(
          _modifiedKey, backup.modifiedAt!.toUtc().toIso8601String());
    }
  }

  Future<Uint8List> _readAll(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
