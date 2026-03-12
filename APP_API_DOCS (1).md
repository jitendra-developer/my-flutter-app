# 📱 VakyaPro Mobile App API Documentation

**Base URL**: `https://vakyapro.com` (Production)  
**API Prefix**: All endpoints are under `/api`

This documentation lists all API endpoints required for the **User Mobile App**.
Note: Admin APIs are excluded as the app is for end-users only.

---

## � Common Requirements

- Headers
  - `Content-Type: application/json`
  - `Accept: application/json`
  - For protected endpoints: `Authorization: Bearer <access_token>`
- Auth Tokens
  - Issued by login/register endpoints (Laravel Sanctum)
  - Include the token in every protected request
- Important
  - App should call only these backend APIs. Do not connect to Supabase or OpenAI directly from the app.

---

## ✅ Mobile App Integration Notes (Android/Flutter)

- Base URL
  - This doc uses `https://vakyapro.com/api`
  - If mobile app is using `https://api.vakyapro.com/api`, keep it consistent across all endpoints via a single config/env value
- Always send JSON headers
  - Missing `Accept: application/json` can cause non-JSON (HTML/redirect) responses from Laravel, which breaks JSON parsing in the app
- Chat sessions ID type
  - `/api/chat-sessions/{chatSession}` expects backend session identifier (normally numeric `id`)
  - Do not generate a UUID locally and use it in `{chatSession}` unless backend explicitly supports UUID routing
- Recommended chat persistence flow
  - On first message (or when starting a new chat), call `POST /api/chat-sessions` and store returned session `id`
  - For every subsequent message/AI reply, call `PUT /api/chat-sessions/{id}` using the stored backend `id`
  - Keep “current session id” in app state aligned with the backend `id` returned from create

---

## �🔐 1. Authentication (Public)

### Register New User
Create a new user account.

- **Endpoint**: `POST /api/auth/register`
- **Headers**: `Content-Type: application/json`
- **Body**:
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "secretpassword",
    "password_confirmation": "secretpassword"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "message": "User registered successfully",
    "user": { "id": 1, "name": "John Doe", "email": "john@example.com" },
    "access_token": "1|laravel_sanctum_token...",
    "token_type": "Bearer"
  }
  ```

### Login
Login with email and password.

- **Endpoint**: `POST /api/auth/login`
- **Body**:
  ```json
  {
    "email": "john@example.com",
    "password": "secretpassword"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Login successful",
    "user": { ... },
    "access_token": "...",
    "token_type": "Bearer"
  }
  ```

### Google Social Login
Login or Register using Google Sign-In.

- **Endpoint**: `POST /api/auth/google`
- **Body**:
  ```json
  {
    "token": "GOOGLE_ID_TOKEN_FROM_APP_SDK"
  }
  ```
- **Response**: Same as Login (returns access_token).

---

### Email OTP (Register & Verify)
Email-based verification for new account registration.

- Register (sends OTP)
  - **Endpoint**: `POST /api/auth/email/register`
  - **Body**:
    ```json
    {
      "name": "John Doe",
      "email": "john@example.com",
      "password": "secretpassword",
      "password_confirmation": "secretpassword"
    }
    ```
  - **Response (201 Created)**:
    ```json
    {
      "message": "OTP sent",
      "user": { "id": 1, "name": "John Doe", "email": "john@example.com" },
      "expires_at": "2026-03-11T12:34:56Z"
    }
    ```
- Verify OTP
  - **Endpoint**: `POST /api/auth/email/verify`
  - **Body**:
    ```json
    {
      "email": "john@example.com",
      "code": "123456"
    }
    ```
  - **Response (200 OK)**:
    ```json
    {
      "message": "Email verified",
      "user": { ... },
      "access_token": "...",
      "token_type": "Bearer"
    }
    ```
- Resend OTP
  - **Endpoint**: `POST /api/auth/email/resend`
  - **Body**:
    ```json
    {
      "email": "john@example.com"
    }
    ```
  - **Response (200 OK)**: `{ "message": "OTP resent" }`

---

## 👤 2. User Profile (Protected)

**Requirement**: All requests below must include Header: `Authorization: Bearer <access_token>`

### Get Current User Profile
Fetch user details, plan info, and credits.

- **Endpoint**: `GET /api/auth/me`
- **Response**:
  ```json
  {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "plan_id": 2,
    "credits": 50,
    "avatar": "https://lh3.googleusercontent.com/..."
  }
  ```

### Update Profile
User ka profile update karein (name/avatar).

- **Endpoint**: `PUT /api/profile`
- **Body**:
  ```json
  {
    "name": "John Updated",
    "avatar": "https://example.com/avatar.png"
  }
  ```

### Logout
Invalidate current session token.

- **Endpoint**: `POST /api/auth/logout`
- **Response**: `{ "message": "Logged out successfully" }`

---

## 📲 3. Phone OTP

Phone OTP verification is currently disabled. Use Email OTP flow for registration and verification.

---

## 🤖 4. AI Features (Protected)

### Generate / Refine Prompt
Send user input to AI engine for refinement.

- **Endpoint**: `POST /api/prompts/generate`
- **Body**:
  ```json
  {
    "prompt": "I need a marketing post for instagram",
    "history": [], // Optional: Previous conversation context
    "question_count": 0 // Optional: For multi-step refinement
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "data": "Here is a refined prompt: Create an engaging Instagram carousel post about..."
  }
  ```

### Get Prompt History
User ki prompt history.

- **Endpoint**: `GET /api/prompts`
- **Response**:
  ```json
  {
    "data": [
      { "id": 1, "original_prompt": "...", "refined_prompt": "...", "created_at": "..." }
    ]
  }
  ```

### AI Chat (Non-stream)
Flutter ke `OpenAI.instance.chat.create` jaisa flow backend se.

- **Endpoint**: `POST /api/ai/chat`
- **Body**:
  ```json
  {
    "messages": [
      { "role": "user", "content": "Hello" }
    ]
  }
  ```
- **Response**:
  ```json
  {
    "content": "Hello from AI",
    "raw": { }
  }
  ```

### AI Chat (Stream)
Server-Sent Events (SSE).

- **Endpoint**: `POST /api/ai/chat/stream`
- **Headers**: `Accept: text/event-stream`
- **Body**: Same as `/api/ai/chat`

### AI Image Generation
Flutter ke image generation jaisa flow backend se.

- **Endpoint**: `POST /api/ai/image`
- **Body**:
  ```json
  {
    "prompt": "A cute robot mascot logo",
    "size": "1024x1024"
  }
  ```

---

## 💬 5. Chat Sessions (Protected)

App chat history ko backend me save/restore karne ke liye.

**Important**:
- `{chatSession}` should be the backend session identifier (usually numeric `id` returned by `POST /api/chat-sessions`)
- If the app generates a UUID locally for session id, it will not match backend routes/tables unless backend supports UUIDs

### List Sessions
- **Endpoint**: `GET /api/chat-sessions`

### Create Session
- **Endpoint**: `POST /api/chat-sessions`
- **Body**:
  ```json
  {
    "title": "First Chat",
    "messages": [
      { "role": "user", "content": "Hi" }
    ]
  }
  ```

### Get Session
- **Endpoint**: `GET /api/chat-sessions/{chatSession}`

### Update / Upsert Session
- **Endpoint**: `PUT /api/chat-sessions/{chatSession}`
- **Body**:
  ```json
  {
    "title": "Updated Title",
    "messages": [
      { "role": "user", "content": "Hi" },
      { "role": "assistant", "content": "Hello" }
    ]
  }
  ```

### Delete Session
- **Endpoint**: `DELETE /api/chat-sessions/{chatSession}`

---

## 💳 6. Plans & Data (Public)

### Get Subscription Plans
List all available plans for upgrade screen.

- **Endpoint**: `GET /api/plans`
- **Response**:
  ```json
  {
    "data": [
      { "id": 1, "name": "Free", "price": 0, "monthly_limit": 10 },
      { "id": 2, "name": "Pro", "price": 29, "monthly_limit": 500 }
    ]
  }
  ```

---

## ❗ 7. Error Format & Status Codes

- Validation Error (422)
  ```json
  {
    "message": "The given data was invalid.",
    "errors": {
      "email": ["The email has already been taken."]
    }
  }
  ```
- Unauthorized (401)
  ```json
  { "message": "Unauthenticated." }
  ```
- Not Found (404)
  ```json
  { "message": "Not Found" }
  ```

---

## 🔁 Auth Flow Summary (App)

1) Register with email → receive OTP email  
2) Verify OTP → app stores `access_token`  
3) Use token in all protected endpoints via `Authorization: Bearer <token>`  
4) On logout, call `/api/auth/logout` and clear token on device
