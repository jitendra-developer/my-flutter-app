# API Usage Documentation

This document lists all the external APIs and services used within the Flutter application.

## 1. Supabase API
Supabase is used as the primary backend service for authentication and database management. The application utilizes the `supabase_flutter` package to interface with the Supabase environment.

**Key Operations & Endpoints:**
- **Authentication:**
  - Email/Password Sign Up (`Supabase.instance.client.auth.signUp`)
  - Email/Password Sign In (`Supabase.instance.client.auth.signInWithPassword`)
  - OTP Verification (`Supabase.instance.client.auth.verifyOTP`)
  - Resend OTP (`Supabase.instance.client.auth.resend`)
  - Google OAuth Sign In (`Supabase.instance.client.auth.signInWithOAuth`)
  - Sign Out (`Supabase.instance.client.auth.signOut`)
  - Auth State Changes listener (`Supabase.instance.client.auth.onAuthStateChange`)
- **Database:**
  - **Profiles Table:** Inserting or modifying profile data upon user registration.
  - **Chat Sessions Table:** Fetching, Upserting, and Deleting records within the `chat_sessions` table to save user chat history continuously.

**Main Implementation Files:**
- `lib/main.dart`
- `lib/settings_service.dart`
- `lib/register.dart`
- `lib/login.dart`
- `lib/google_esign.dart`
- `lib/chat_provider.dart`
- `lib/chat_page.dart`
- `lib/phone_verification_page.dart`
- `lib/screens/otp_verification_screen.dart`

---

## 2. OpenAI API
OpenAI powers the core AI chat logic and image generation functionalities. The system connects via the `dart_openai` package using an API Key.

**Key Operations & Endpoints:**
- **Chat Completions:**
  - Used for both standard context text responses and streaming chat completions (`OpenAI.instance.chat.create` and `OpenAI.instance.chat.createStream`).
- **Image Generation:**
  - Generating AI images based on given prompt requests (`OpenAI.instance.image.create`).

**Main Implementation Files:**
- `lib/main.dart` (Key Initialization)
- `lib/chat_provider.dart` (Business Logic for Chat & Images)

---

## 3. Unsplash Network Images
A list of direct Unsplash image URLs is used in the app to display vibrant placeholder/preview images.

**Main Implementation Files:**
- `lib/screens/pre_prompts_page.dart`
