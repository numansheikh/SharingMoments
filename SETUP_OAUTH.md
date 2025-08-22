# Google OAuth Setup Instructions

## Prerequisites
1. A Google account
2. Access to Google Cloud Console

## Step 1: Create a Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Drive API

## Step 2: Configure OAuth Consent Screen
1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" user type
3. Fill in the required information:
   - App name: "Sharing Moments"
   - User support email: your email
   - Developer contact information: your email
4. Add scopes:
   - `https://www.googleapis.com/auth/drive.file`
   - `https://www.googleapis.com/auth/drive.metadata.readonly`
5. Add test users (your family members' email addresses)
6. Publish the app

## Step 3: Create OAuth 2.0 Credentials
1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client IDs"
3. Choose "Web application"
4. Set authorized JavaScript origins:
   - `http://localhost:8080`
   - `http://127.0.0.1:8080`
5. Set authorized redirect URIs:
   - `http://localhost:8080/auth/callback`
   - `http://127.0.0.1:8080/auth/callback`
6. Copy the Client ID and Client Secret

## Step 4: Update the App
1. Open `lib/services/auth_service.dart`
2. Replace `YOUR_GOOGLE_CLIENT_ID_HERE` with your actual Client ID
3. Replace `YOUR_GOOGLE_CLIENT_SECRET_HERE` with your actual Client Secret
4. Save the file

## Step 5: Test the Setup
1. Run the app: `flutter run -d chrome --web-port=8080`
2. Click the cloud icon to sign in
3. Complete the OAuth flow

## Security Notes
- Never commit your actual credentials to version control
- The credentials in this template are safe to commit
- For production, use environment variables or secure credential management
