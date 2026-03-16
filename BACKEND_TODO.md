# Vakya Pro — Backend Tasks (2026-03-16)

These are the backend changes required for today's app updates.
The app code is already built on the frontend side — the backend just needs to implement / verify these.

---

## 1. Profile Photo — Store & Return URL

**Endpoint:** `PUT /api/profile`

**What the app sends:**
```json
{
  "name": "John Doe",
  "avatar": "data:image/jpeg;base64,/9j/4AAQSkZ..."
}
```

**What the backend must do:**
- Decode the Base64 string into an image file
- Store the image (disk / S3 / CDN — your choice)
- Return the publicly accessible hosted URL in the response

**What the backend must return:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "avatar": "https://cdn.vakyapro.com/avatars/john-abc123.jpg"
}
```

> The `avatar` field in the response must be a full HTTPS URL.
> The app will cache this URL and display it as the profile photo everywhere (profile page + sidebar).

---

## 2. Profile Photo — Return on Login / Me

**Endpoints:** `POST /api/auth/login`, `POST /api/auth/google`, `GET /api/auth/me`

**What the backend must do:**
- Always include the `avatar` field in the user object in these responses
- For Google Sign-In users: populate `avatar` with the Google profile photo URL on first login
- For email users: return the uploaded avatar URL (from step 1 above) if one exists, otherwise return `null`

**Expected field in response:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "avatar": "https://..."   ← this field is required
}
```

> Without this the profile page shows initials instead of the user's photo on first open.

---

## 3. Change Password (authenticated user)

**Endpoint:** `PUT /api/profile/password`
**Auth:** Required (Bearer token)

**Request:**
```json
{
  "current_password": "oldpassword123",
  "password": "newpassword456",
  "password_confirmation": "newpassword456"
}
```

**What the backend must do:**
- Verify `current_password` matches the user's stored (hashed) password
- If wrong → return `422` with an error on `current_password`
- If correct → hash and store `password` as the new password

**Success response `200`:**
```json
{
  "message": "Password changed successfully"
}
```

**Error response `422`:**
```json
{
  "message": "The current password is incorrect.",
  "errors": {
    "current_password": ["The current password is incorrect."]
  }
}
```

---

## 4. Forgot Password — Send OTP to Email

**Endpoint:** `POST /api/auth/password/forgot`
**Auth:** Not required (public)

**Request:**
```json
{
  "email": "john@example.com"
}
```

**What the backend must do:**
- Check if the email exists in the database
- If not found → return `422` with a clear error message
- If found → generate a random 6-digit numeric OTP
- Store the OTP against the email with an expiry (recommended: 10 minutes)
- Send the OTP to the email (email subject: something like "Your Vakya Pro password reset code")

**Success response `200`:**
```json
{
  "message": "OTP sent to your email"
}
```

**Error response `422` (email not found):**
```json
{
  "message": "No account found with this email address.",
  "errors": {
    "email": ["No account found with this email address."]
  }
}
```

> The user can tap "Resend" in the app which calls this same endpoint again — make sure resending invalidates the old OTP and issues a fresh one.

---

## 5. Forgot Password — Reset with OTP

**Endpoint:** `POST /api/auth/password/reset`
**Auth:** Not required (public)

**Request:**
```json
{
  "email": "john@example.com",
  "code": "123456",
  "password": "newpassword456",
  "password_confirmation": "newpassword456"
}
```

**What the backend must do:**
- Look up the OTP stored for this email
- If OTP is invalid or expired → return `422` with error on `code`
- If OTP is valid → hash and store `password` as the user's new password
- Invalidate / delete the OTP so it cannot be reused
- Return success

**Success response `200`:**
```json
{
  "message": "Password reset successfully"
}
```

**Error response `422` (wrong OTP):**
```json
{
  "message": "Invalid or expired code.",
  "errors": {
    "code": ["Invalid or expired code."]
  }
}
```

---

## Summary Checklist

| # | Task | Endpoint | Status |
|---|------|----------|--------|
| 1 | Accept Base64 avatar, store image, return hosted URL | `PUT /api/profile` | ⬜ To Do |
| 2 | Return `avatar` URL in login/me responses | `POST /auth/login`, `POST /auth/google`, `GET /auth/me` | ⬜ To Do |
| 3 | Change password with current password verification | `PUT /api/profile/password` | ⬜ To Do |
| 4 | Send 6-digit OTP to email for password reset | `POST /api/auth/password/forgot` | ⬜ To Do |
| 5 | Verify OTP and set new password | `POST /api/auth/password/reset` | ⬜ To Do |

---

## Error Response Format (reminder)

All error responses across all endpoints must follow this format so the app can display them:

```json
{
  "message": "Short human-readable error",
  "errors": {
    "field_name": ["Error detail"]
  }
}
```

> Values inside `errors` can be either a `string[]` or a plain `string` — both are handled by the app.
