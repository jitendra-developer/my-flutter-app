# Project Blueprint - Totan AI Chat App

## Overview
Totan is a modern AI chat application built with Flutter and Firebase. It features a polished onboarding experience, secure authentication, and an interactive chat interface powered by OpenAI.

## Design & Style
- **Theming**: Adheres to Material Design 3 principles with a **Modern Dark** aesthetic.
- **Color Palette**: 
    - **Base**: Charcoal/Deep Grey (#121212) for primary backgrounds (not pure black).
    - **Surfaces**: Elevated surfaces use a slightly lighter grey to provide depth.
    - **Primary Accent**: Vibrant Deep Purple seed color for a modern, premium feel.
- **Components**: Rounded containers (`borderRadius: 30`), custom social login buttons (GOOGLE/FACEBOOK) with tinted backgrounds, and sophisticated shadows.
- **Typography**: Uses `Google Fonts` (Plus Jakarta Sans) for high-quality, legible text with high contrast in dark mode.

## Current State - Authentication UI
- **File**: `lib/login_page.dart`
- **Structure**: A `Scaffold` containing a centered dark rounded card. Inside the card, a `PageView` managed by a `PageController` handles different authentication states.
- **Internal Pages**:
    1.  **Welcome Page**: Displays logo, app name, and primary "Log in" / "Sign up" actions.
    2.  **Sign In Page**: Internal form for email/password login.
    3.  **Sign Up Page**: Internal form for account creation.
    4.  **Phone Page**: Internal form for phone number verification.
- **Current Flow**: Navigation between these states is handled by `_pageController.jumpToPage()`.

## Planned Change - Navigation & Theme Update
The goal is to move away from internal `PageView` transitions for the primary login and registration flows and instead use standalone screen files, while strictly enforcing the new Modern Dark theme.

1.  **Login Navigation**: Update the 'Log in' button in `lib/login_page.dart` to navigate to the standalone login screen defined in `lib/login.dart` using `Navigator.push`.
2.  **Registration Navigation**: Update the 'Sign up' button in `lib/login_page.dart` to navigate to the standalone registration screen defined in `lib/register.dart` using `Navigator.push`.
3.  **Theme Implementation**: Ensure global theme data in `lib/main.dart` reflects the deep charcoal backgrounds and vibrant purple accents across all standalone screens.