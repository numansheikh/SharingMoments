# Sharing Moments - Cross-Platform Slideshow App

A beautiful, cross-platform slideshow application built with Flutter that displays photos with Google Drive integration.

## 🎯 Project Requirements

### Cross-Platform Support
This app is designed to run on all major platforms:
1. **iOS** - iPhone (portrait/landscape)
2. **iPad** - Tablet interface with optimized layout
3. **Android Phone** - Mobile interface
4. **Android Tablet** - Tablet interface with optimized layout
5. **Google TV** - TV interface with remote navigation support

### Core Features
- 📱 **Cross-platform slideshow** with automatic transitions
- 🎮 **Touch and remote control navigation** (for TV)
- ☁️ **Google Drive integration** for photo storage
- 🎨 **Beautiful dark theme** with purple accents
- ⏯️ **Play/pause controls** with manual navigation
- 📊 **Photo indicators** and counter display
- 🔄 **Responsive design** for all screen sizes

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.35.1 or higher)
- Dart SDK
- For iOS/macOS: Xcode
- For Android: Android Studio with Android SDK
- For TV: Android TV emulator or device

### Installation & Running

1. **Clone and navigate to project:**
   ```bash
   cd sharing_moments
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on different platforms:**

   **Web (Chrome):**
   ```bash
   flutter run -d chrome
   ```

   **iOS Simulator:**
   ```bash
   flutter run -d ios
   ```

   **Android Emulator:**
   ```bash
   flutter run -d android
   ```

   **macOS Desktop:**
   ```bash
   flutter run -d macos
   ```

   **Android TV:**
   ```bash
   flutter run -d android --flavor tv
   ```

## 📱 Platform-Specific Features

### iOS/iPhone
- Optimized for touch gestures
- Swipe navigation between photos
- Haptic feedback for controls
- iOS-style animations and transitions

### iPad
- Larger photo display area
- Split-screen compatibility
- Enhanced navigation controls
- Optimized for landscape orientation

### Android Phone
- Material Design 3 components
- Android-style animations
- Back button navigation support
- Adaptive icon support

### Android Tablet
- Tablet-optimized layouts
- Multi-window support
- Enhanced touch targets
- Landscape-first design

### Google TV
- Remote control navigation
- D-pad support for menu navigation
- TV-optimized UI scaling
- Auto-play functionality
- Screen saver mode

## 🛠️ Development Notes

### Current Status
- ✅ Basic slideshow functionality
- ✅ Cross-platform UI framework
- ✅ Sample photo integration (gradient placeholders)
- ✅ Play/pause controls
- ✅ Navigation buttons
- ✅ Photo indicators
- ✅ Settings dialog with blue theme
- ✅ Google Drive service implementation
- ✅ Access control management system
- ✅ Authentication dialog
- ✅ Demo access control (works without Google Drive)
- 🔄 Google Drive OAuth integration (ready for credentials)
- 🔄 Platform-specific optimizations (in progress)

### Key Files
- `lib/main.dart` - Main application entry point
- `pubspec.yaml` - Dependencies and project configuration
- `android/` - Android-specific configurations
- `ios/` - iOS-specific configurations
- `web/` - Web-specific configurations

### Dependencies
- `flutter` - Core Flutter framework
- `googleapis` - Google Drive API integration
- `googleapis_auth` - OAuth authentication
- `http` - HTTP requests for API calls

## ☁️ Google Drive Integration

### **Folder Structure:**
```
📁 Sharing Moments (Shared Folder)
├── 📄 settings.json (Access Control List)
├── 📁 Photos
│   ├── 📸 photo1.jpg
│   ├── 📸 photo2.jpg
│   └── ...
└── 📁 Thumbnails (optional)
```

### **Access Control System:**
- **Settings file** (`settings.json`) manages access permissions
- **Owner:** Full control over folder and settings
- **Admins:** Can manage access control
- **Viewers:** Can only view photos in slideshow
- **Email-based permissions** stored in Google Drive

### **Features:**
- ✅ **Automatic folder creation** with proper structure
- ✅ **Settings file management** for access control
- ✅ **Add/remove viewers** via email addresses
- ✅ **Folder sharing** with specific permissions
- ✅ **Photo retrieval** from shared folder
- ✅ **Access control dialog** for managing permissions

### **Settings File Format:**
```json
{
  "folderId": "your_shared_folder_id",
  "accessControl": {
    "owner": "your-email@gmail.com",
    "admins": ["admin1@gmail.com"],
    "viewers": ["friend1@gmail.com", "family1@gmail.com"],
    "permissions": {
      "canView": true,
      "canDownload": false,
      "canShare": false
    }
  },
  "slideshowSettings": {
    "autoPlay": true,
    "interval": 3,
    "showIndicators": true,
    "transition": "fade"
  }
}
```

## 🔧 Development Commands

### Hot Reload (during development)
```bash
# Press 'r' in terminal while app is running
```

### Hot Restart
```bash
# Press 'R' in terminal while app is running
```

### Build for Production
```bash
# iOS
flutter build ios

# Android
flutter build apk

# Web
flutter build web

# macOS
flutter build macos
```

## 📋 TODO List

### High Priority
- [x] Implement Google Drive OAuth authentication
- [x] Add photo upload functionality
- [x] Implement photo caching for offline viewing
- [x] Add access control management
- [ ] Add platform-specific navigation (TV remote, touch gestures)

### Medium Priority
- [ ] Add photo editing capabilities
- [ ] Implement slideshow themes
- [ ] Add music/audio support
- [ ] Create photo albums/folders

### Low Priority
- [ ] Add social sharing features
- [ ] Implement photo filters
- [ ] Add slideshow scheduling
- [ ] Create backup/restore functionality

## 🐛 Troubleshooting

### Common Issues
1. **"No pubspec.yaml found"** - Make sure you're in the project root directory
2. **Dependencies not found** - Run `flutter pub get`
3. **Platform not supported** - Check `flutter doctor` for platform setup

### Platform Setup
- **iOS**: Install Xcode from App Store
- **Android**: Install Android Studio and configure SDK
- **TV**: Set up Android TV emulator in Android Studio

## 📞 Support

If you lose this documentation again in Cursor, simply paste these instructions to resume development. The project structure and requirements are now documented for future reference.

---

**Last Updated**: Current session
**Flutter Version**: 3.35.1
**Target Platforms**: iOS, iPad, Android Phone, Android Tablet, Google TV, Web
