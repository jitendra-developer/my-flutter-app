# Project Blueprint - VAKYA AI Chat App

## Overview
Vakya AI is a modern AI chat application built with Flutter and Supabase, functioning primarily as an expert Prompt Generator for AI video and image tools, while still retaining general AI assistant capabilities for exploration and answering questions. It features a polished onboarding experience, secure authentication, and an interactive chat interface.

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
- **UI & Default Behavior**:
    - Automatically initializes an empty new chat upon opening the app.
    - Displays a personalized "Welcome Again [User Name]" greeting when the chat is empty.
    - Displays a list of messages using `ListView.builder`.
    - Options to copy, share, edit, or rollback AI messages via long-press on `MessageBubble`.
    - A `ChatInputField` allows users to send text, images, or documents (PDF/TXT) via `image_picker` and `file_picker`.
- **Text-to-Speech & Voice Modality**:
    - Integrated with `flutter_tts` for spoken AI responses.
    - Integrated with `speech_to_text` for voice dictation.
    - **Continuous Voice Mode**: Initiating voice mode (via the mic wave icon) enables a hands-free, continuous conversation loop. The app automatically listens (with a 5-second silence timeout for auto-send), speaks the AI response, and seamlessly re-activates the microphone after the reading is completed without any manual button presses. User typing or pressing the red "End" button terminates this loop.
- **Chat History & History Generation**:
    - Chats are stored in Supabase (`chat_sessions` table) and preserved permanently only when the AI has sent at least one response (minimum 2 messages in the session).
    - Integrating with OpenAI `gpt-3.5-turbo`, a concise 3-5 word title is automatically generated for every new saved chat depending on context.
    - The chat history drawer (`lib/history_page.dart`) allows users to toggle between past threads or delete them.

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
