import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const String _settingsFileName = 'settings.json';
  static const String _photosFolderName = 'Photos';
  
  late drive.DriveApi _driveApi;
  String? _folderId;
  Map<String, dynamic>? _settings;

  // Initialize the service
  Future<void> initialize(String accessToken, DateTime expiry) async {
    final token = AccessToken('Bearer', accessToken, expiry);
    final credentials = AccessCredentials(
      token,
      null, // refresh token
      _scopes,
    );
    final client = authenticatedClient(http.Client(), credentials);
    _driveApi = drive.DriveApi(client);
  }

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
  ];

  // Create or get the shared folder
  Future<String> getOrCreateSharedFolder({String? folderName}) async {
    try {
      // First, try to find existing settings file
      final settingsFile = await _findSettingsFile();
      if (settingsFile != null) {
        _folderId = await _getFolderIdFromSettings(settingsFile.id!);
        return _folderId!;
      }

      // Try to find existing folder with the specified name
      if (folderName != null) {
        final existingFolder = await _findFolderByName(folderName);
        if (existingFolder != null) {
          _folderId = existingFolder.id!;
          await _createSettingsFile();
          await _createPhotosFolder();
          return _folderId!;
        }
      }

      // Create new shared folder structure
      _folderId = await _createSharedFolder(folderName: folderName);
      await _createSettingsFile();
      await _createPhotosFolder();
      
      return _folderId!;
    } catch (e) {
      throw Exception('Failed to setup shared folder: $e');
    }
  }

  // Find existing settings file
  Future<drive.File?> _findSettingsFile() async {
    try {
      final response = await _driveApi.files.list(
        q: "name='$_settingsFileName' and trashed=false",
        spaces: 'drive',
      );
      
      return response.files?.isNotEmpty == true ? response.files!.first : null;
    } catch (e) {
      return null;
    }
  }

  // Find folder by name
  Future<drive.File?> _findFolderByName(String folderName) async {
    try {
      final response = await _driveApi.files.list(
        q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
      );
      
      return response.files?.isNotEmpty == true ? response.files!.first : null;
    } catch (e) {
      return null;
    }
  }

  // Create the main shared folder
  Future<String> _createSharedFolder({String? folderName}) async {
    final folder = drive.File()
      ..name = folderName ?? 'Sharing Moments'
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await _driveApi.files.create(folder);
    return createdFolder.id!;
  }

  // Create settings file
  Future<void> _createSettingsFile() async {
    final settings = {
      'folderId': _folderId,
      'accessControl': {
        'owner': await _getCurrentUserEmail(),
        'admins': [],
        'viewers': [],
        'permissions': {
          'canView': true,
          'canDownload': false,
          'canShare': false,
        }
      },
      'slideshowSettings': {
        'autoPlay': true,
        'interval': 3,
        'showIndicators': true,
        'transition': 'fade'
      }
    };

    final file = drive.File()
      ..name = _settingsFileName
      ..parents = [_folderId!]
      ..mimeType = 'application/json';

    final media = drive.Media(
      Stream.value(utf8.encode(json.encode(settings))),
      settings.toString().length,
    );

    await _driveApi.files.create(file, uploadMedia: media);
  }

  // Create photos folder
  Future<void> _createPhotosFolder() async {
    final folder = drive.File()
      ..name = _photosFolderName
      ..parents = [_folderId!]
      ..mimeType = 'application/vnd.google-apps.folder';

    await _driveApi.files.create(folder);
  }

  // Get current user email
  Future<String> _getCurrentUserEmail() async {
    final about = await _driveApi.about.get();
    return about.user?.emailAddress ?? 'unknown@email.com';
  }

  // Public method to get current user email
  Future<String> getCurrentUserEmail() async {
    final about = await _driveApi.about.get();
    return about.user?.emailAddress ?? 'unknown@email.com';
  }

  // Load settings from file
  Future<Map<String, dynamic>> loadSettings() async {
    if (_settings != null) return _settings!;

    final settingsFile = await _findSettingsFile();
    if (settingsFile == null) {
      throw Exception('Settings file not found');
    }

    final response = await _driveApi.files.get(
      settingsFile.id!,
    ) as http.Response;

    _settings = json.decode(response.body);
    return _settings!;
  }

  // Update settings file
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    final settingsFile = await _findSettingsFile();
    if (settingsFile == null) {
      throw Exception('Settings file not found');
    }

    final file = drive.File()
      ..name = _settingsFileName;

    final media = drive.Media(
      Stream.value(utf8.encode(json.encode(newSettings))),
      newSettings.toString().length,
    );

    await _driveApi.files.update(
      file,
      settingsFile.id!,
      uploadMedia: media,
    );

    _settings = newSettings;
  }

  // Add viewer to access list
  Future<void> addViewer(String email) async {
    final settings = await loadSettings();
    final viewers = List<String>.from(settings['accessControl']['viewers'] ?? []);
    
    if (!viewers.contains(email)) {
      viewers.add(email);
      settings['accessControl']['viewers'] = viewers;
      await updateSettings(settings);
    }
  }

  // Remove viewer from access list
  Future<void> removeViewer(String email) async {
    final settings = await loadSettings();
    final viewers = List<String>.from(settings['accessControl']['viewers'] ?? []);
    
    viewers.remove(email);
    settings['accessControl']['viewers'] = viewers;
    await updateSettings(settings);
  }

  // Get all photos from the shared folder
  Future<List<drive.File>> getPhotos() async {
    final photosFolder = await _findPhotosFolder();
    if (photosFolder == null) return [];

    final response = await _driveApi.files.list(
      q: "'${photosFolder.id}' in parents and trashed=false and (mimeType contains 'image/')",
      spaces: 'drive',
    );

    return response.files ?? [];
  }

  // Find photos folder
  Future<drive.File?> _findPhotosFolder() async {
    if (_folderId == null) return null;

    final response = await _driveApi.files.list(
      q: "'$_folderId' in parents and name='$_photosFolderName' and trashed=false",
      spaces: 'drive',
    );

    return response.files?.isNotEmpty == true ? response.files!.first : null;
  }

  // Get folder ID from settings
  Future<String> _getFolderIdFromSettings(String settingsFileId) async {
    final response = await _driveApi.files.get(
      settingsFileId,
    ) as http.Response;

    final settings = json.decode(response.body);
    return settings['folderId'];
  }

  // Share folder with specific user
  Future<void> shareFolderWithUser(String email, {String role = 'reader'}) async {
    if (_folderId == null) {
      throw Exception('Folder not initialized');
    }

    final permission = drive.Permission()
      ..type = 'user'
      ..emailAddress = email
      ..role = role;

    await _driveApi.permissions.create(permission, _folderId!);
  }

  // Get folder sharing link
  Future<String> getFolderSharingLink() async {
    if (_folderId == null) {
      throw Exception('Folder not initialized');
    }

    return 'https://drive.google.com/drive/folders/$_folderId';
  }
}
