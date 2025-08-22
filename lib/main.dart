import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'services/auth_service.dart';
import 'services/google_drive_service.dart';
import 'services/folder_config_service.dart';
import 'widgets/auth_dialog.dart';
import 'widgets/access_control_demo_dialog.dart';

void main() {
  // Check for OAuth callback
  final uri = Uri.parse(html.window.location.href);
  if (uri.queryParameters.containsKey('code')) {
    // Handle OAuth callback
    final code = uri.queryParameters['code']!;
    _handleOAuthCallback(code);
  }
  
  runApp(const SharingMomentsApp());
}

void _handleOAuthCallback(String code) async {
  try {
    final token = await AuthService.handleCallback(code);
    if (token != null) {
      // Redirect back to app without the code parameter
      final cleanUrl = Uri.parse(html.window.location.href).replace(queryParameters: {});
      html.window.history.pushState({}, '', cleanUrl.toString());
      
      // Show success message
      print('Successfully authenticated with Google Drive!');
    }
  } catch (e) {
    print('OAuth callback error: $e');
    // Show error message to user
    html.window.alert('Authentication failed: $e');
  }
}

class SharingMomentsApp extends StatelessWidget {
  const SharingMomentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharing Moments',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SlideshowScreen(),
    );
  }
}

class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen({super.key});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  List<String> photoUrls = [];
  int currentPhotoIndex = 0;
  bool isLoading = true;
  Timer? slideshowTimer;
  bool isPlaying = true;
  bool isAuthenticated = false;
  GoogleDriveService? _driveService;
  FolderConfigService? _folderConfigService;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadSamplePhotos(); // For demo purposes
    _startSlideshow();
    
    // Check authentication state periodically
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkAuthentication();
      }
    });
  }

  @override
  void dispose() {
    slideshowTimer?.cancel();
    super.dispose();
  }

  void _checkAuthentication() {
    final wasAuthenticated = isAuthenticated;
    final newAuthState = _isUserAuthenticated();
    
    if (newAuthState != wasAuthenticated) {
      setState(() {
        isAuthenticated = newAuthState;
      });
      
      if (newAuthState && !wasAuthenticated) {
        _initializeDriveService();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to Google Drive!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check authentication state when dependencies change
    _checkAuthentication();
  }

  void _initializeDriveService() async {
    final token = AuthService.getStoredToken();
    final expiry = AuthService.getStoredTokenExpiry();
    if (token != null && expiry != null) {
      _driveService = GoogleDriveService();
      _folderConfigService = FolderConfigService();
      
      await _driveService!.initialize(token, expiry);
      await _folderConfigService!.initialize(token, expiry);
      
      await _loadPhotosFromDrive();
    }
  }

  Future<void> _loadPhotosFromDrive() async {
    if (_driveService == null) return;
    
    try {
      setState(() {
        isLoading = true;
      });
      
      final photos = await _driveService!.getPhotos();
      if (photos.isNotEmpty) {
        setState(() {
          photoUrls = photos.map((photo) => photo.id!).toList();
          isLoading = false;
        });
      } else {
        _loadSamplePhotos(); // Fallback to sample photos
      }
    } catch (e) {
      print('Error loading photos from Drive: $e');
      _loadSamplePhotos(); // Fallback to sample photos
    }
  }

  void _loadSamplePhotos() {
    // Sample photos for demonstration
    // In a real app, these would come from Google Drive API
    setState(() {
      photoUrls = [
        'photo1',
        'photo2', 
        'photo3',
        'photo4',
        'photo5',
      ];
      isLoading = false;
    });
  }

  void _startSlideshow() {
    slideshowTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isPlaying && photoUrls.isNotEmpty) {
        setState(() {
          currentPhotoIndex = (currentPhotoIndex + 1) % photoUrls.length;
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _nextPhoto() {
    if (photoUrls.isNotEmpty) {
      setState(() {
        currentPhotoIndex = (currentPhotoIndex + 1) % photoUrls.length;
      });
    }
  }

  void _previousPhoto() {
    if (photoUrls.isNotEmpty) {
      setState(() {
        currentPhotoIndex = currentPhotoIndex == 0 
            ? photoUrls.length - 1 
            : currentPhotoIndex - 1;
      });
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SettingsDialog();
      },
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.blueGrey,
    ];
    return colors[index % colors.length];
  }

  String _getCurrentUserEmail() {
    final token = AuthService.getStoredToken();
    if (token != null) {
      // For now, return a placeholder. In a real implementation,
      // we would decode the JWT token or call Google Drive API
      // to get the actual user email
      return 'Loading...';
    }
    return 'Not signed in';
  }

  Future<String> _getActualUserEmail() async {
    if (_driveService != null) {
      try {
        return await _driveService!.getCurrentUserEmail();
      } catch (e) {
        print('Error getting user email: $e');
        return 'Error loading email';
      }
    }
    return 'Not connected';
  }

  bool _isUserAuthenticated() {
    return AuthService.getStoredToken() != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen photo display
          if (!isLoading && photoUrls.isNotEmpty)
            Container(
              width: double.infinity,
              height: double.infinity,
              child: PageView.builder(
                itemCount: photoUrls.length,
                controller: PageController(initialPage: currentPhotoIndex),
                onPageChanged: (index) {
                  setState(() {
                    currentPhotoIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getColorForIndex(index),
                          _getColorForIndex(index).withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo,
                            size: 80,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Photo ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Gradient Placeholder',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Loading indicator
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sharing Moments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isAuthenticated)
                        Text(
                          'Signed in as: Connected',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (isAuthenticated) {
                            // Show account info or sign out option
                            String userEmail = 'Connected';
                            try {
                              if (_driveService != null) {
                                userEmail = await _getActualUserEmail();
                              }
                            } catch (e) {
                              userEmail = 'Connected';
                            }
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text(
                                    'Google Drive Connected',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'You are signed in as: $userEmail',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Status: Connected to Google Drive',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('OK', style: TextStyle(color: Colors.blue)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        AuthService.signOut();
                                        setState(() {
                                          isAuthenticated = false;
                                        });
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Signed out of Google Drive'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      },
                                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AuthDialog(
                                onAuthSuccess: () {
                                  _checkAuthentication();
                                },
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isAuthenticated ? Icons.cloud_done : Icons.cloud,
                          color: isAuthenticated ? Colors.green : Colors.white,
                          size: 30,
                        ),
                        tooltip: isAuthenticated ? 'Connected to Google Drive' : 'Connect to Google Drive',
                      ),
                      IconButton(
                        onPressed: _showSettingsDialog,
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Photo counter
                  Text(
                    '${currentPhotoIndex + 1} / ${photoUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Navigation controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _previousPhoto,
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextPhoto,
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Photo indicators
          if (photoUrls.length > 1)
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photoUrls.length,
                  (index) => Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentPhotoIndex 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  double slideshowSpeed = 3.0;
  bool autoPlay = true;
  bool showIndicators = true;
  String sharedFolderUrl = '';
  FolderConfigService? _folderConfigService;

  @override
  void initState() {
    super.initState();
    _loadCurrentFolderName();
  }

  Future<void> _loadCurrentFolderName() async {
    // Get the folder config service from the parent widget
    final parentState = context.findAncestorStateOfType<_SlideshowScreenState>();
    if (parentState?._folderConfigService != null) {
      _folderConfigService = parentState!._folderConfigService;
      try {
        final folderUrl = await _folderConfigService!.getSharedFolderUrl();
        setState(() {
          sharedFolderUrl = folderUrl;
        });
      } catch (e) {
        print('Error loading folder configuration: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slideshow Speed
              const Text(
                'Slideshow Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: slideshowSpeed,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey[700],
                      onChanged: (value) {
                        setState(() {
                          slideshowSpeed = value;
                        });
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${slideshowSpeed.toInt()}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Auto Play Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Auto Play',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: autoPlay,
                    onChanged: (value) {
                      setState(() {
                        autoPlay = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Show Indicators Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Show Photo Indicators',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: showIndicators,
                    onChanged: (value) {
                      setState(() {
                        showIndicators = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Shared Folder Configuration Section
              const Text(
                'Shared Folder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste the Google Drive folder URL shared by the master account',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Shared Folder URL Input
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Google Drive Folder URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'https://drive.google.com/drive/folders/xxx?usp=drive_link',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
                onChanged: (value) {
                  sharedFolderUrl = value;
                },
              ),
              const SizedBox(height: 12),

              // Current URL Display
              if (sharedFolderUrl.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connected to: ${sharedFolderUrl.length > 50 ? '${sharedFolderUrl.substring(0, 50)}...' : sharedFolderUrl}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Update URL Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (sharedFolderUrl.isNotEmpty && _folderConfigService != null) {
                      try {
                        await _folderConfigService!.setSharedFolderUrl(sharedFolderUrl);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Shared folder URL updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating folder URL: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Connect to Shared Folder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Access Control Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // For now, show demo access control
                    showDialog(
                      context: context,
                      builder: (context) => const AccessControlDemoDialog(),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Manage Access Control'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Apply settings
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings applied!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
