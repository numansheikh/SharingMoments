import 'dart:convert';
import 'dart:html' as html;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FolderConfigService {
  static const String _configFileName = 'sharing_moments_config.json';
  
  late drive.DriveApi _driveApi;
  Map<String, dynamic>? _config;

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

  // Get or create configuration file
  Future<Map<String, dynamic>> getOrCreateConfig() async {
    if (_config != null) return _config!;

    try {
      // Try to find existing config file
      final configFile = await _findConfigFile();
      if (configFile != null) {
        _config = await _loadConfigFromFile(configFile.id!);
        return _config!;
      }

      // Create new config file
      _config = _getDefaultConfig();
      await _createConfigFile();
      return _config!;
    } catch (e) {
      // Fallback to default config
      _config = _getDefaultConfig();
      return _config!;
    }
  }

  // Find existing config file
  Future<drive.File?> _findConfigFile() async {
    try {
      print('=== _findConfigFile called ===');
      final response = await _driveApi.files.list(
        q: "name='$_configFileName' and trashed=false",
        spaces: 'drive',
      );
      
      print('Found ${response.files?.length ?? 0} config files');
      if (response.files != null && response.files!.isNotEmpty) {
        for (int i = 0; i < response.files!.length; i++) {
          final file = response.files![i];
          print('File $i: ID=${file.id}, Name=${file.name}, Created=${file.createdTime}');
        }
      }
      
      return response.files?.isNotEmpty == true ? response.files!.first : null;
    } catch (e) {
      print('Error in _findConfigFile: $e');
      return null;
    }
  }

  // Load config from file
  Future<Map<String, dynamic>> _loadConfigFromFile(String fileId) async {
    try {
      final response = await _driveApi.files.get(fileId) as http.Response;
      return json.decode(response.body);
    } catch (e) {
      return _getDefaultConfig();
    }
  }

  // Create config file
  Future<void> _createConfigFile() async {
    final file = drive.File()
      ..name = _configFileName
      ..mimeType = 'application/json';

    final media = drive.Media(
      Stream.value(utf8.encode(json.encode(_config))),
      json.encode(_config).length,
    );

    await _driveApi.files.create(file, uploadMedia: media);
  }

  // Get default configuration
  Map<String, dynamic> _getDefaultConfig() {
    return {
      'folders': [
        {
          'name': 'Sharing Moments',
          'isDefault': true,
          'createdAt': DateTime.now().toIso8601String(),
          'sharedFolderUrl': '', // Will be set by master account
          'folderId': '', // Google Drive folder ID
          'settings': {
            'autoPlay': true,
            'interval': 3,
            'showIndicators': true,
            'transition': 'fade'
          }
        }
      ],
      'currentFolder': 'Sharing Moments',
      'version': '1.0',
      'masterAccount': '', // Email of the master account
      'familyMembers': [] // List of family member emails
    };
  }

  // Update folder name
  Future<void> updateFolderName(String newName) async {
    final config = await getOrCreateConfig();
    
    // Update the default folder name
    if (config['folders'] != null && config['folders'].isNotEmpty) {
      config['folders'][0]['name'] = newName;
      config['currentFolder'] = newName;
    }

    // Update the config file
    await _updateConfigFile(config);
    _config = config;
  }

  // Get current folder name
  Future<String> getCurrentFolderName() async {
    final config = await getOrCreateConfig();
    return config['currentFolder'] ?? 'Sharing Moments';
  }

  // Update config file
  Future<void> _updateConfigFile(Map<String, dynamic> newConfig) async {
    print('=== _updateConfigFile called ===');
    print('New config: ${json.encode(newConfig)}');
    
    final configFile = await _findConfigFile();
    print('Found config file: ${configFile?.id}');
    
    if (configFile == null) {
      print('No config file found, creating new one');
      await _createConfigFile();
      return;
    }

    print('Updating existing config file');
    
    // Delete the old file first to prevent multiple versions
    try {
      await _driveApi.files.delete(configFile.id!);
      print('Old config file deleted');
    } catch (e) {
      print('Error deleting old file: $e');
    }
    
    // Create a new file with the updated content
    final newFile = drive.File()
      ..name = _configFileName
      ..mimeType = 'application/json';

    final media = drive.Media(
      Stream.value(utf8.encode(json.encode(newConfig))),
      json.encode(newConfig).length,
    );

    await _driveApi.files.create(newFile, uploadMedia: media);
    print('New config file created successfully');
  }

  // Add new folder
  Future<void> addFolder(String folderName) async {
    final config = await getOrCreateConfig();
    
    if (config['folders'] == null) {
      config['folders'] = [];
    }

    // Check if folder already exists
    final existingFolder = config['folders'].firstWhere(
      (folder) => folder['name'] == folderName,
      orElse: () => null,
    );

    if (existingFolder == null) {
      config['folders'].add({
        'name': folderName,
        'isDefault': false,
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {
          'autoPlay': true,
          'interval': 3,
          'showIndicators': true,
          'transition': 'fade'
        }
      });
    }

    await _updateConfigFile(config);
    _config = config;
  }

  // Get all folders
  Future<List<String>> getAllFolders() async {
    final config = await getOrCreateConfig();
    if (config['folders'] == null) return ['Sharing Moments'];
    
    return (config['folders'] as List)
        .map((folder) => folder['name'] as String)
        .toList();
  }

  // Set current folder
  Future<void> setCurrentFolder(String folderName) async {
    final config = await getOrCreateConfig();
    config['currentFolder'] = folderName;
    await _updateConfigFile(config);
    _config = config;
  }

  // Set shared folder URL (for master account)
  Future<void> setSharedFolderUrl(String folderUrl) async {
    print('=== setSharedFolderUrl called ===');
    print('Input URL: "$folderUrl"');
    
    final config = await getOrCreateConfig();
    print('Current config: ${json.encode(config)}');
    
    // Extract folder ID from URL
    final folderId = _extractFolderIdFromUrl(folderUrl);
    print('Extracted folder ID: "$folderId"');
    
    if (config['folders'] != null && config['folders'].isNotEmpty) {
      config['folders'][0]['sharedFolderUrl'] = folderUrl;
      config['folders'][0]['folderId'] = folderId;
      print('Updated folders[0]: ${config['folders'][0]}');
    }
    
    await _updateConfigFile(config);
    _config = config;
    print('Config updated and saved');
  }

  // Get shared folder URL
  Future<String> getSharedFolderUrl() async {
    print('=== getSharedFolderUrl called ===');
    final config = await getOrCreateConfig();
    print('Raw config from Drive: ${json.encode(config)}');
    print('Config keys: ${config.keys.toList()}');
    if (config['folders'] != null && config['folders'].isNotEmpty) {
      print('Folders array: ${config['folders']}');
      print('First folder: ${config['folders'][0]}');
      final url = config['folders'][0]['sharedFolderUrl'] ?? '';
      print('Extracted URL: "$url"');
      return url;
    }
    print('No folders found in config');
    return '';
  }

  // Get folder ID
  Future<String> getFolderId() async {
    final config = await getOrCreateConfig();
    if (config['folders'] != null && config['folders'].isNotEmpty) {
      return config['folders'][0]['folderId'] ?? '';
    }
    return '';
  }

  // Extract folder ID from Google Drive URL
  String _extractFolderIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Handle different URL formats
      if (pathSegments.contains('folders')) {
        final folderIndex = pathSegments.indexOf('folders');
        if (folderIndex + 1 < pathSegments.length) {
          return pathSegments[folderIndex + 1];
        }
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  // Set master account
  Future<void> setMasterAccount(String email) async {
    final config = await getOrCreateConfig();
    config['masterAccount'] = email;
    await _updateConfigFile(config);
    _config = config;
  }

  // Add family member
  Future<void> addFamilyMember(String email) async {
    final config = await getOrCreateConfig();
    
    if (config['familyMembers'] == null) {
      config['familyMembers'] = [];
    }
    
    if (!config['familyMembers'].contains(email)) {
      config['familyMembers'].add(email);
    }
    
    await _updateConfigFile(config);
    _config = config;
  }

  // Get family members
  Future<List<String>> getFamilyMembers() async {
    final config = await getOrCreateConfig();
    return List<String>.from(config['familyMembers'] ?? []);
  }
}
