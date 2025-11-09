# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flutter + Supabase authentication template** designed for reuse across multiple app projects. It provides complete authentication functionality with email/password authentication.

### Technology Stack
- **Framework**: Flutter 3.x
- **State Management**: Riverpod 3.x
- **Backend**: Supabase (Authentication, Database)
- **Routing**: go_router 17.x
- **Environment**: flutter_dotenv

## Project Structure

```
lib/
├── main.dart                          # App entry point with initialization
├── config/
│   ├── supabase_config.dart          # Supabase client initialization
│   └── router.dart                   # GoRouter configuration with auth guards
├── features/
│   └── auth/
│       ├── providers/
│       │   └── auth_provider.dart     # Riverpod providers for auth state
│       ├── services/
│       │   └── auth_service.dart      # Authentication business logic
│       └── screens/
│           ├── login_screen.dart      # Email login UI
│           ├── signup_screen.dart     # Email registration UI
│           ├── forgot_password_screen.dart  # Password reset UI
│           └── home_screen.dart       # Post-login sample screen
└── core/
    └── constants/
        └── env.dart                   # Environment variable access
```

## Development Commands

### Setup
```bash
# Get dependencies
flutter pub get

# Create .env file from template
cp .env.example .env
# Then edit .env with your Supabase credentials
```

### Running
```bash
# Run on connected device/simulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

### Testing & Quality
```bash
# Run all tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android)
flutter build appbundle

# Build iOS (requires macOS)
flutter build ios
```

## Configuration Requirements

### 1. Environment Variables (.env)
Required before running the app:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anon/public key

### 2. Supabase Setup
- Enable Email authentication in Supabase Dashboard
- Set up redirect URLs for password reset: `io.supabase.flutterquickstart://reset-password/`

## Architecture Patterns

### State Management
- **Riverpod Providers**: All auth state managed through providers
- **StreamProvider**: Monitors auth state changes from Supabase
- **Provider**: Exposes current user and auth service

### Routing
- **GoRouter**: Declarative routing with auth state-based redirects
- **Auto-redirect**: Unauthenticated users → login, authenticated users → home
- Routes: `/login`, `/signup`, `/forgot-password`, `/home`

### Authentication Flow
1. User submits credentials via UI screen
2. Screen calls AuthService method
3. AuthService communicates with Supabase
4. Auth state changes trigger provider updates
5. GoRouter redirect logic responds to auth state
6. UI automatically navigates to appropriate screen

### Error Handling
- All async auth operations wrapped in try-catch
- Errors displayed via SnackBar with user-friendly messages
- Debug logging with ✅/❌ prefixes for easy filtering

## Key Implementation Notes

### Deep Linking
- Configured for Supabase auth redirects
- Scheme: `io.supabase.flutterquickstart://`
- Required for password reset flows

### Material 3 Design
- Uses Material 3 components throughout
- Light/dark theme support via `ThemeMode.system`
- Filled buttons for primary actions, outlined for secondary

### Session Management
- Automatic token refresh enabled
- Session persistence across app restarts
- PKCE flow for enhanced security

## Common Development Tasks

### Adding Additional Auth Methods
If you want to add OAuth providers (Google, Apple, etc.):
1. Add required packages (e.g., `google_sign_in`, `sign_in_with_apple`)
2. Add provider logic to `lib/features/auth/services/auth_service.dart`
3. Add UI buttons to login/signup screens
4. Configure provider in Supabase Dashboard
5. Update platform-specific configuration files (Info.plist, build.gradle)

### Customizing UI
- Modify screens in `lib/features/auth/screens/`
- Update theme in `lib/main.dart` `MaterialApp.router` config
- All screens use Material 3 components for consistency

### Adding Post-Auth Features
1. Create new feature directory in `lib/features/`
2. Add routes to `lib/config/router.dart`
3. Use `ref.watch(currentUserProvider)` to access logged-in user
4. Create providers for feature-specific state

## Template Usage

To use this template for a new project:
1. Clone this repository
2. Update `applicationId` in `android/app/build.gradle.kts`
3. Update bundle identifier in Xcode for iOS
4. Create new Supabase project and update .env with credentials
5. Update app name and branding as needed
6. Build your app features on top of this auth foundation
