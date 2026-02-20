# Project Blueprint - Totan AI Chat App

## Overview
Totan is a modern AI chat application built with Flutter and Supabase. It features a polished onboarding experience, secure authentication, and an interactive chat interface.

## Design & Style
- **Theming**: Adheres to Material Design 3 principles with a **Modern Dark** aesthetic.
- **Color Palette**:
    - **Base**: Charcoal/Deep Grey (#121212) for primary backgrounds (not pure black).
    - **Surfaces**: Elevated surfaces use a slightly lighter grey to provide depth.
    - **Primary Accent**: Vibrant Deep Purple seed color for a modern, premium feel.
- **Components**: Rounded containers (`borderRadius: 20` or `30`), custom social login buttons, and sophisticated shadows.
- **Typography**: Uses `Google Fonts` (Plus Jakarta Sans) for high-quality, legible text with high contrast in dark mode.
- **Navigation**: Uses `go_router` for declarative routing and handling authentication state changes.

## Implemented Features

### Authentication Flow
- **Provider**: Supabase for authentication (email/password, social logins).
- **Screens**:
    - `lib/welcome_page.dart`: Initial landing page.
    - `lib/onboarding_screen.dart`: Introduction to the app.
    - `lib/login_page.dart`: Hub for different login methods.
    - `lib/login.dart`: Email and password login screen.
    - `lib/register.dart`: User registration screen.
    - `lib/screens/otp_verification_screen.dart`: OTP verification for sign-up.
- **Routing**: `go_router` in `lib/main.dart` manages redirects based on the user's authentication session. Logged-in users are sent to `/chat`, while logged-out users are directed to the appropriate public or authentication routes.

### Chat Interface
- **File**: `lib/chat_page.dart`
- **State Management**: `Provider` (`ChatProvider`) for managing chat messages and state.
- **UI**:
    - Displays a list of messages using `ListView.builder`.
    - `MessageBubble` for styling user and AI messages differently.
    - A `ChatInputField` allows users to send messages.
    - Markdown support for rendering AI responses.
    - Options to copy or share AI messages.

### **Logout Functionality**
- **Location**: Implemented in `lib/chat_page.dart`.
- **Trigger**: A "Log out" option was added to the three-dot `PopupMenuButton` in the `AppBar`.
- **Flow**:
    1.  User taps the "Log out" option.
    2.  An `AlertDialog` appears, asking for confirmation ("Are you sure you want to log out?").
    3.  If the user selects "Yes," the `Supabase.instance.client.auth.signOut()` method is called.
    4.  This clears the authentication session, and the `GoRouterRefreshStream` automatically triggers a navigation redirect, sending the user to the `/login` page.
    5.  If the user selects "Cancel," the dialog is dismissed.
- **Result**: Ensures a secure and complete logout, correctly resetting the app state for the next session.
