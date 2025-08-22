# Google Drive Integration Setup Guide

## 🚀 Quick Start

### 1. Google Cloud Console Setup

1. **Go to [Google Cloud Console](https://console.cloud.google.com/)**
2. **Create a new project** or select existing one
3. **Enable Google Drive API:**
   - Go to "APIs & Services" > "Library"
   - Search for "Google Drive API"
   - Click "Enable"

### 2. Create OAuth Credentials

1. **Go to "APIs & Services" > "Credentials"**
2. **Click "Create Credentials" > "OAuth 2.0 Client IDs"**
3. **Configure OAuth consent screen:**
   - User Type: External
   - App name: "Sharing Moments"
   - User support email: Your email
   - Developer contact: Your email
   - Scopes: Add `https://www.googleapis.com/auth/drive.file`

4. **Create OAuth 2.0 Client ID:**
   - Application type: Web application
   - Name: "Sharing Moments Web Client"
   - Authorized JavaScript origins: `http://localhost:8080`
   - Authorized redirect URIs: `http://localhost:8080/auth/callback`

### 3. Update Credentials in Code

Replace the placeholder values in `lib/services/auth_service.dart`:

```dart
static const String _clientId = 'YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com';
static const String _clientSecret = 'YOUR_ACTUAL_CLIENT_SECRET';
```

### 4. Test the Integration

1. **Run the app:** `flutter run -d chrome --web-port=8080`
2. **Click the cloud icon** in the top right
3. **Sign in with Google**
4. **Grant permissions** to access Drive
5. **Test access control** in settings

## 🔧 How It Works

### **Authentication Flow:**
1. User clicks cloud icon
2. OAuth popup opens
3. User signs in with Google
4. App gets access token
5. Token stored in localStorage
6. App connects to Google Drive

### **Folder Structure Created:**
```
📁 Sharing Moments (in your Drive)
├── 📄 settings.json (Access control list)
└── 📁 Photos (Your photos go here)
```

### **Access Control:**
- **Settings dialog** → "Manage Access Control"
- **Add viewers** by email address
- **Remove viewers** from the list
- **All changes saved** to settings.json in Drive

## 🛠️ Troubleshooting

### **Common Issues:**

1. **"Invalid client" error:**
   - Check client ID and secret are correct
   - Ensure redirect URI matches exactly

2. **"Access denied" error:**
   - Check OAuth consent screen is configured
   - Verify scopes are added correctly

3. **"CORS error":**
   - Ensure localhost:8080 is in authorized origins
   - Check redirect URI matches

4. **"Token expired":**
   - App will automatically refresh tokens
   - If persistent, clear localStorage and re-authenticate

### **Development Tips:**

- **Use Chrome DevTools** to monitor network requests
- **Check Console** for error messages
- **Test with different Google accounts**
- **Verify folder permissions** in Google Drive

## 📱 Next Steps

After setup is complete:

1. **Upload photos** to the "Photos" folder in Drive
2. **Add viewers** through the access control dialog
3. **Test on different devices** (iOS, Android, TV)
4. **Customize settings** in the settings dialog

## 🔒 Security Notes

- **Client secret** should be kept secure
- **Access tokens** are stored in localStorage (web only)
- **Permissions** are scoped to specific Drive folders
- **Users can revoke access** at any time

## 📞 Support

If you encounter issues:
1. Check the browser console for errors
2. Verify Google Cloud Console settings
3. Test with a fresh browser session
4. Check Google Drive folder permissions
