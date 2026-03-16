# Vakya Pro — Backend API Specification
**Base URL:** `https://api.vakyapro.com/api`
**App:** Flutter (Android) — Vakya Pro
**Last Updated:** 2026-03-16

All requests must include:
```
Content-Type: application/json
Accept: application/json
```
Protected endpoints additionally require:
```
Authorization: Bearer <access_token>
```

---

## Table of Contents
1. [Authentication](#1-authentication)
2. [User Profile](#2-user-profile)
3. [Password Management](#3-password-management)
4. [AI Features](#4-ai-features)
5. [Chat Sessions](#5-chat-sessions)
6. [Plans](#6-plans)
7. [App Settings](#7-app-settings)

---

## 1. Authentication

### 1.1 Register (direct, no OTP)
**POST** `/auth/register`
> Creates account and returns a session token immediately.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Success Response `200`:**
```json
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

---

### 1.2 Register with Email OTP
**POST** `/auth/email/register`
> Creates account but does NOT return a token — sends OTP to email for verification.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Success Response `200`:**
```json
{
  "message": "OTP sent to your email"
}
```

---

### 1.3 Verify Email OTP
**POST** `/auth/email/verify`
> Verifies the OTP and returns a session token — user is now logged in.

**Request Body:**
```json
{
  "email": "john@example.com",
  "code": "123456"
}
```

**Success Response `200`:**
```json
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

---

### 1.4 Resend Email OTP
**POST** `/auth/email/resend`
> Resends the email verification OTP.

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Success Response `200`:**
```json
{
  "message": "OTP resent"
}
```

---

### 1.5 Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Success Response `200`:**
```json
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

---

### 1.6 Google Sign-In
**POST** `/auth/google`
> Accepts the Google ID token from the client SDK and returns an app session.

**Request Body:**
```json
{
  "token": "<google_id_token>"
}
```

**Success Response `200`:**
```json
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@gmail.com",
    "avatar": "https://lh3.googleusercontent.com/..."
  }
}
```

---

### 1.7 Logout
**POST** `/auth/logout`
🔒 **Protected**

**Request Body:** _(none)_

**Success Response `200`:**
```json
{
  "message": "Logged out successfully"
}
```

> Note: The app clears the local token regardless of this call's result.

---

## 2. User Profile

### 2.1 Get Profile
**GET** `/auth/me`
🔒 **Protected**

**Success Response `200`:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "avatar": "https://cdn.example.com/avatars/john.jpg"
}
```

> The app checks for `avatar`, `profile_photo_url`, and `photo` fields (in that order) to find the profile picture URL. Please use `avatar` as the primary field name.

---

### 2.2 Update Profile
**PUT** `/profile`
🔒 **Protected**

**Request Body:**
```json
{
  "name": "John Updated",
  "avatar": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

> `avatar` is optional. When provided it is a Base64-encoded image string prefixed with `data:image/jpeg;base64,`. The backend should store the image and return the hosted URL in the response.

**Success Response `200`:**
```json
{
  "id": 1,
  "name": "John Updated",
  "email": "john@example.com",
  "avatar": "https://cdn.example.com/avatars/john-new.jpg"
}
```

---

## 3. Password Management

### 3.1 Change Password (authenticated — knows current password)
**PUT** `/profile/password`
🔒 **Protected**

**Request Body:**
```json
{
  "current_password": "oldpassword123",
  "password": "newpassword456",
  "password_confirmation": "newpassword456"
}
```

**Success Response `200`:**
```json
{
  "message": "Password changed successfully"
}
```

**Error Response `422` (validation):**
```json
{
  "message": "The current password is incorrect.",
  "errors": {
    "current_password": ["The current password is incorrect."]
  }
}
```

---

### 3.2 Forgot Password — Send OTP
**POST** `/auth/password/forgot`
> Sends a 6-digit OTP to the registered email for password reset. No auth required.

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Success Response `200`:**
```json
{
  "message": "OTP sent to your email"
}
```

---

### 3.3 Reset Password with OTP
**POST** `/auth/password/reset`
> Verifies the OTP and sets the new password. No auth required.

**Request Body:**
```json
{
  "email": "john@example.com",
  "code": "123456",
  "password": "newpassword456",
  "password_confirmation": "newpassword456"
}
```

**Success Response `200`:**
```json
{
  "message": "Password reset successfully"
}
```

**Error Response `422`:**
```json
{
  "message": "Invalid or expired OTP.",
  "errors": {
    "code": ["Invalid or expired OTP."]
  }
}
```

---

## 4. AI Features

### 4.1 Generate Prompt
**POST** `/prompts/generate`
🔒 **Protected**
> Takes a user's raw idea and generates a refined AI image/chat prompt.

**Request Body:**
```json
{
  "prompt": "a futuristic city at night",
  "history": [],
  "question_count": 0
}
```

> `history` is an array of previous `{ role, content }` message objects for multi-turn context. `question_count` tracks how many follow-up questions have been asked.

**Success Response `200`:**
```json
{
  "response": "A sprawling neon-lit megacity at midnight, aerial view...",
  "question_count": 1
}
```

---

### 4.2 Get Prompt History
**GET** `/prompts`
🔒 **Protected**

**Success Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "prompt": "a futuristic city",
      "response": "...",
      "created_at": "2026-03-16T10:00:00Z"
    }
  ]
}
```

---

### 4.3 AI Chat (non-streaming)
**POST** `/ai/chat`
🔒 **Protected**

**Request Body:**
```json
{
  "messages": [
    { "role": "user", "content": "Hello, who are you?" }
  ],
  "stream": false
}
```

**Success Response `200`:**
```json
{
  "content": "I am Vakya Pro, your AI assistant..."
}
```

---

### 4.4 AI Chat (Streaming — SSE)
**POST** `/ai/chat/stream`
🔒 **Protected**

**Additional Headers:**
```
Accept: text/event-stream
Cache-Control: no-cache
```

**Request Body:**
```json
{
  "messages": [
    { "role": "user", "content": "Write me a poem about the sea." }
  ]
}
```

**Response:** Server-Sent Events stream
```
data: {"content": "The "}
data: {"content": "ocean "}
data: {"content": "roars..."}
data: [DONE]
```

> The app has a **60-second per-event timeout**. If the stream stalls for 60 seconds without a new event, the app automatically falls back to `/ai/chat` (non-streaming). Please ensure the streaming endpoint sends keep-alive events if processing takes a long time.

> The app also accepts the OpenAI-compatible format: `choices[0].delta.content`

---

### 4.5 Generate Image
**POST** `/ai/image`
🔒 **Protected**

**Request Body:**
```json
{
  "prompt": "A photorealistic sunset over the Himalayas",
  "size": "1024x1024"
}
```

**Success Response `200`:**
```json
{
  "url": "https://cdn.example.com/generated/image-abc123.png"
}
```

---

## 5. Chat Sessions

### 5.1 List All Sessions
**GET** `/chat-sessions`
🔒 **Protected**

**Success Response `200`:**
```json
{
  "data": [
    {
      "id": 42,
      "title": "Sci-fi story ideas",
      "messages": [...],
      "created_at": "2026-03-15T08:00:00Z",
      "updated_at": "2026-03-15T09:00:00Z"
    }
  ]
}
```

---

### 5.2 Create Session
**POST** `/chat-sessions`
🔒 **Protected**

**Request Body:**
```json
{
  "title": "My first chat",
  "messages": [
    { "role": "user", "content": "Hello!" },
    { "role": "assistant", "content": "Hi there! How can I help?" }
  ]
}
```

**Success Response `200` or `201`:**
```json
{
  "id": 42,
  "title": "My first chat",
  "messages": [...],
  "created_at": "2026-03-16T10:00:00Z"
}
```

> The app uses the returned `id` (integer) for all subsequent GET/PUT/DELETE calls. Do not use a UUID — use the backend-assigned numeric ID.

---

### 5.3 Get Single Session
**GET** `/chat-sessions/{id}`
🔒 **Protected**

**Success Response `200`:**
```json
{
  "id": 42,
  "title": "My first chat",
  "messages": [
    { "role": "user", "content": "Hello!" },
    { "role": "assistant", "content": "Hi there!" }
  ],
  "created_at": "2026-03-16T10:00:00Z",
  "updated_at": "2026-03-16T10:05:00Z"
}
```

---

### 5.4 Update Session
**PUT** `/chat-sessions/{id}`
🔒 **Protected**

**Request Body:**
```json
{
  "title": "Updated title",
  "messages": [
    { "role": "user", "content": "Hello!" },
    { "role": "assistant", "content": "Hi there!" },
    { "role": "user", "content": "Tell me a joke." }
  ]
}
```

**Success Response `200`:** _(same shape as Get Single Session)_

---

### 5.5 Delete Session
**DELETE** `/chat-sessions/{id}`
🔒 **Protected**

**Success Response `200` or `204`:**
```json
{
  "message": "Session deleted"
}
```

---

## 6. Plans

### 6.1 Get All Plans
**GET** `/plans`
🌐 **Public**

**Success Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Free",
      "price": 0,
      "features": ["10 messages/day", "Basic AI"],
      "is_popular": false
    },
    {
      "id": 2,
      "name": "Pro",
      "price": 499,
      "features": ["Unlimited messages", "GPT-4", "Image generation"],
      "is_popular": true
    }
  ]
}
```

---

## 7. App Settings

### 7.1 Get Multiple Settings
**GET** `/app-settings`
🌐 **Public**

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `prefix` | string | Filter by key prefix e.g. `onboarding_` |
| `keys[]` | string[] | Fetch specific keys e.g. `keys[]=app_version&keys[]=maintenance_mode` |

**Example:** `GET /app-settings?prefix=onboarding_`

**Success Response `200`:**
```json
{
  "data": [
    { "setting_key": "onboarding_slide1_title", "setting_value": "Welcome to Vakya Pro" },
    { "setting_key": "onboarding_slide1_text",  "setting_value": "Your AI-powered assistant" },
    { "setting_key": "onboarding_slide1_image", "setting_value": "https://cdn.example.com/slide1.png" },
    { "setting_key": "onboarding_slide1_active","setting_value": "1" }
  ]
}
```

---

### 7.2 Get Single Setting
**GET** `/app-settings/{key}`
🌐 **Public**

**Example:** `GET /app-settings/app_version`

**Success Response `200`:**
```json
{
  "data": {
    "setting_key": "app_version",
    "setting_value": "2.5.2"
  }
}
```

---

## Onboarding Slides — Setting Keys Convention

The onboarding screen reads settings with the prefix `onboarding_`. For each slide `N` (1–10):

| Key | Value | Notes |
|-----|-------|-------|
| `onboarding_slideN_title` | string | Slide headline |
| `onboarding_slideN_text` | string | Slide body text |
| `onboarding_slideN_image` | URL string | Full image URL |
| `onboarding_slideN_active` | `"1"` or `"0"` | `"0"` hides the slide |

**Example for slide 1:**
```
onboarding_slide1_title  = "Welcome to Vakya Pro"
onboarding_slide1_text   = "Generate stunning AI images from text."
onboarding_slide1_image  = "https://cdn.example.com/onboard1.png"
onboarding_slide1_active = "1"
```

---

## Error Response Format

All error responses should follow this structure:

```json
{
  "message": "Human-readable summary of the error",
  "errors": {
    "field_name": ["Error message for this field"],
    "another_field": ["Another error"]
  }
}
```

> The app reads `errors` first (and joins all field messages), then falls back to `message`. If neither is present, it shows a generic error. The `errors` values can be either a `string[]` or a plain `string` — both are handled.

---

## Notes for Backend Developer

1. **Token format:** The app stores and sends tokens as `Bearer <token>` in the `Authorization` header. JWT or Sanctum tokens both work.

2. **Chat message format:** Messages sent to and from the backend use `{ "role": "user"|"assistant", "content": "..." }` format — same as OpenAI's Chat Completions API.

3. **Avatar upload:** The app sends Base64-encoded images as `data:image/jpeg;base64,...`. The backend should decode, store to disk/CDN, and return the hosted URL in the `avatar` field of the response.

4. **Streaming:** The SSE endpoint must send `data: [DONE]` as the final event to signal stream completion. The app will not stop reading until it sees `[DONE]` or the connection closes.

5. **Numeric IDs:** Chat session IDs must be numeric integers. The app creates a session with POST first, uses the returned `id` for all subsequent requests.

6. **OTP expiry:** No specific expiry is enforced by the app — that is a backend decision. Recommended: 10 minutes.

7. **CORS:** The app makes HTTP requests from a mobile client so CORS headers are not needed, but the API should accept requests from any origin in case of web testing.
