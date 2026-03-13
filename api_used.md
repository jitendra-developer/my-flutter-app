# API Usage Documentation

This document lists the central backend API and external services used within the Vakya Pro Flutter application.

## 1. Vakya Pro Custom Backend API
The application has migrated away from direct Supabase and OpenAI integrations in favor of a centralized custom backend. All authentication, data persistence, and AI logic are managed through this API.

**Base URL**: `https://api.vakyapro.com/api`

**Key Operations & Endpoints:**
- **Authentication (Public):**
  - Standard Register (`POST /auth/register`)
  - Email OTP Register (`POST /auth/email/register`)
  - OTP Verification (`POST /auth/email/verify`)
  - Login (`POST /auth/login`)
  - Google Social Login (`POST /auth/google`)
- **User Profile (Protected):**
  - Get Profile (`GET /auth/me`)
  - Update Profile (`PUT /profile`)
  - Logout (`POST /auth/logout`)
- **AI Features (Protected):**
  - AI Chat (Non-stream: `POST /ai/chat`, Stream: `POST /ai/chat/stream`)
  - Image Generation (`POST /ai/image`)
  - Prompt Generation/Refinement (`POST /prompts/generate`)
- **Chat Sessions (Protected):**
  - List/Create/Update/Delete sessions via `/chat-sessions` endpoints.
- **App Data:**
  - Dynamic App Settings (`GET /app-settings`)
  - Subscription Plans (`GET /plans`)

**Main Implementation Files:**
- `lib/services/api_service.dart` (Central API Client)
- `lib/chat_provider.dart` (State management and AI logic)
- `lib/login_page.dart`, `lib/register.dart`, `lib/screens/otp_verification_screen.dart` (Auth UI)

---

## 2. Google Sign-In SDK
Used for retrieving OAuth ID tokens for social authentication.
- **Main Implementation Files:** `lib/google_esign.dart`

---

## 3. Unsplash Network Images
Direct Unsplash image URLs are used for UI placeholders and prompt previews.
- **Main Implementation Files:** `lib/screens/pre_prompts_page.dart`

