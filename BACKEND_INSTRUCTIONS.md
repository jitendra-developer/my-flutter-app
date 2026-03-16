# Vakya Pro — Complete Backend Developer Instructions
**App:** Vakya Pro (Flutter Android)
**Base URL:** `https://api.vakyapro.com/api`
**Last Updated:** 2026-03-16

All requests include:
```
Content-Type: application/json
Accept: application/json
```
Protected endpoints require:
```
Authorization: Bearer <access_token>
```

All error responses must follow this format (the app reads `errors` first, then `message`):
```json
{
  "message": "Short human-readable error",
  "errors": {
    "field_name": ["Error detail here"]
  }
}
```
> `errors` values can be a `string[]` or plain `string` — both are handled.

---

## TASK 1 — Profile Photo Upload

**Endpoint:** `PUT /api/profile`
**Auth:** Required

The app sends the photo as a Base64 string. Backend must decode it, store it, and return the hosted URL.

**Request:**
```json
{
  "name": "John Doe",
  "avatar": "data:image/jpeg;base64,/9j/4AAQSkZ..."
}
```

**What to do:**
- Decode the Base64 string → save to disk / S3 / CDN
- Return the hosted HTTPS URL in the `avatar` field

**Response `200`:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "avatar": "https://cdn.vakyapro.com/avatars/john-abc123.jpg"
}
```

---

## TASK 2 — Return Avatar on Login & Me

**Endpoints:** `POST /api/auth/login` · `POST /api/auth/google` · `GET /api/auth/me`

Always include `avatar` in the user object:
- Google users → use their Google profile photo URL on first login
- Email users → return uploaded avatar URL if it exists, otherwise `null`

**Required field in every user response:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "avatar": "https://..."
}
```

---

## TASK 3 — Change Password (Authenticated)

**Endpoint:** `PUT /api/profile/password`
**Auth:** Required

**Request:**
```json
{
  "current_password": "oldpassword123",
  "password": "newpassword456",
  "password_confirmation": "newpassword456"
}
```

**What to do:**
- Verify `current_password` against stored hash
- If wrong → `422` with error on `current_password`
- If correct → hash and store new password

**Success `200`:**
```json
{ "message": "Password changed successfully" }
```

**Error `422`:**
```json
{
  "message": "The current password is incorrect.",
  "errors": { "current_password": ["The current password is incorrect."] }
}
```

---

## TASK 4 — Forgot Password: Send OTP

**Endpoint:** `POST /api/auth/password/forgot`
**Auth:** Not required

**Request:**
```json
{ "email": "john@example.com" }
```

**What to do:**
- Check if email exists
- If not found → `422` with error on `email`
- If found → generate 6-digit numeric OTP, store with 10-minute expiry, send via email
- Resending this endpoint must invalidate the old OTP and issue a fresh one

**Success `200`:**
```json
{ "message": "OTP sent to your email" }
```

**Error `422`:**
```json
{
  "message": "No account found with this email address.",
  "errors": { "email": ["No account found with this email address."] }
}
```

---

## TASK 5 — Forgot Password: Reset with OTP

**Endpoint:** `POST /api/auth/password/reset`
**Auth:** Not required

**Request:**
```json
{
  "email": "john@example.com",
  "code": "123456",
  "password": "newpassword456",
  "password_confirmation": "newpassword456"
}
```

**What to do:**
- Look up OTP for the email
- If invalid or expired → `422` with error on `code`
- If valid → hash and store new password, invalidate the OTP

**Success `200`:**
```json
{ "message": "Password reset successfully" }
```

**Error `422`:**
```json
{
  "message": "Invalid or expired code.",
  "errors": { "code": ["Invalid or expired code."] }
}
```

---

## TASK 6 — Pre-Prompts (New Feature)

This is the most important new task. The Pre-Prompts page in the app currently shows hardcoded data. It needs to load from the backend so prompts can be updated without a new app release.

### 6.1 — New Endpoint

**GET** `/api/pre-prompts`
**Auth:** Required (Bearer token)

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "title": "Professional Studio Headshot",
      "category": "Portraits",
      "sort_order": 1,
      "variants": [
        {
          "prompt": "A high-end professional corporate headshot...",
          "image": "https://cdn.vakyapro.com/prompts/headshot-1.jpg"
        },
        {
          "prompt": "Another variant of the headshot prompt...",
          "image": "https://cdn.vakyapro.com/prompts/headshot-2.jpg"
        }
      ]
    }
  ]
}
```

> The app filters prompts by `category` and searches within `title` and `variants[].prompt`.
> Categories currently used in the app: `Portraits`, `Animated`, `Realistic`, `Cyberpunk`, `Cinematic`
> The `sort_order` field controls display order in the masonry grid.

### 6.2 — Database Table

Create a `pre_prompts` table:

| Column | Type | Notes |
|---|---|---|
| `id` | int | primary key, auto-increment |
| `title` | string | display name shown on detail screen |
| `category` | string | must match one of the category chips |
| `sort_order` | int | lower = shown first |
| `is_active` | boolean | set to false to hide without deleting |
| `variants` | JSON | array of `{ "prompt": "...", "image": "..." }` |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

### 6.3 — Seed Data (copy-paste into the database)

Seed all 6 existing prompts exactly as below. Use publicly hosted image URLs (these are Unsplash URLs — you can either keep them or re-host on your own CDN).

---

**Row 1**
```json
{
  "title": "Professional Studio Headshot",
  "category": "Portraits",
  "sort_order": 1,
  "is_active": true,
  "variants": [
    {
      "prompt": "A high-end professional corporate headshot of a person looking directly at the camera. Clean, neutral dark grey seamless paper background. Rembrandt lighting setup casting a soft triangle of light on the cheek. The subject wears sharp, formal business attire, a dark tailored suit. 85mm portrait lens, shallow depth of field, hyper-realistic, highly detailed skin texture.",
      "image": "https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=600&auto=format&fit=crop"
    },
    {
      "prompt": "A high-end professional corporate headshot of a person looking slightly away from the camera. Warm beige seamless paper background. Butterfly lighting setup producing a soft glow. The subject wears modern business casual attire. 85mm portrait lens, shallow depth of field, natural and approachable expression.",
      "image": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=600&auto=format&fit=crop"
    },
    {
      "prompt": "A high-end professional corporate headshot with a slight smile. Soft window light coming from the left. Clean, beautifully blurred modern office environment in the background. The subject is wearing a crisp white shirt. 50mm lens, bright and optimistic corporate portrait.",
      "image": "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=600&auto=format&fit=crop"
    }
  ]
}
```

---

**Row 2**
```json
{
  "title": "Neon City Cyberpunk",
  "category": "Cyberpunk",
  "sort_order": 2,
  "is_active": true,
  "variants": [
    {
      "prompt": "A gritty, futuristic cyberpunk portrait. Vivid neon pink and cyan rim lighting illuminating the subject's face and shoulders in the dark. In the background, a heavily blurred, rainy, futuristic neon city street with glowing Asian characters and holographic signs. 8k resolution, cinematic lighting, conceptual art.",
      "image": "https://images.unsplash.com/photo-1542362567-b07e54358753?q=80&w=600&auto=format&fit=crop"
    },
    {
      "prompt": "A neon-drenched cyberpunk portrait with rain hitting the subject's clear illuminated face shield. Acid green and deep purple lighting. Dark, dirty alleyway with glowing neon tubes and wires hanging in the background. Masterpiece, highly detailed.",
      "image": "https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=600&auto=format&fit=crop"
    }
  ]
}
```

---

**Row 3**
```json
{
  "title": "3D Pixar-Style Avatar",
  "category": "Animated",
  "sort_order": 3,
  "is_active": true,
  "variants": [
    {
      "prompt": "A highly detailed 3D cartoon portrait of a person in the style of a modern Pixar or Disney CGI animated movie. Soft, warm, magical studio lighting. The character has large, expressive eyes, smooth stylized proportions, soft skin, and highly distinct realistic textured hair. Masterpiece, unreal engine 5 render, volumetric lighting.",
      "image": "https://images.unsplash.com/photo-1498334906313-6e099a1bd28d?q=80&w=600&auto=format&fit=crop"
    },
    {
      "prompt": "A 3D cartoon portrait of a person in modern Pixar style, stylized proportions. Holding a magical glowing orb. Cold, magical cyan light bouncing off their face. Large expressive eyes, incredibly detailed Pixar skin shading. Unreal engine 5 render, beautiful cinematic rim lighting.",
      "image": "https://images.unsplash.com/photo-1514755106263-5df3f317b3d3?q=80&w=600&auto=format&fit=crop"
    }
  ]
}
```

---

**Row 4**
```json
{
  "title": "Moody Cinematic Film Look",
  "category": "Cinematic",
  "sort_order": 4,
  "is_active": true,
  "variants": [
    {
      "prompt": "A moody, cinematic still frame inspired by Christopher Nolan films. Teal and orange complementary color grading. Lifted black levels for a vintage film-like matte finish. Emphasized deep shadows, dramatic lighting from a single light source out of frame, subtle anamorphic lens flare, raw photo, 35mm film grain.",
      "image": "https://images.unsplash.com/photo-1535295972055-1c762f4483e5?q=80&w=600&auto=format&fit=crop"
    },
    {
      "prompt": "Cinematic medium shot of a person looking out of a rain-streaked window at night. Low key lighting, high contrast. A glowing streetlamp casting warm golden light over their profile against deep blue shadows. 35mm lens, movie still frame, Kodak Vision3 500T film stock.",
      "image": "https://images.unsplash.com/photo-1533038590840-1c793ba64524?q=80&w=600&auto=format&fit=crop"
    }
  ]
}
```

---

**Row 5**
```json
{
  "title": "Hyper-Realistic Nature Profile",
  "category": "Realistic",
  "sort_order": 5,
  "is_active": true,
  "variants": [
    {
      "prompt": "A hyper-realistic close-up portrait of a person outdoors. Extremely sharp focus on the eye specular highlights and skin pores. Beautiful natural sunlight. In the background, a naturally blurred green forest with a gorgeous, buttery shallow depth of field bokeh. Shot on Sony A7R IV, 50mm f/1.2.",
      "image": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop"
    },
    {
      "prompt": "A hyper-realistic close-up portrait outdoors during golden hour. Warm back-lighting from a low sun casting a halo effect on the subject's hair. Perfectly sharp eye details. Blurred open field background with warm sunset colors. Shot on Canon EOS R5, 85mm f/1.2 L.",
      "image": "https://images.unsplash.com/photo-1479936343636-73cdc5aae0c3?q=80&w=600&auto=format&fit=crop"
    }
  ]
}
```

---

**Row 6**
```json
{
  "title": "Anime Style Transformation",
  "category": "Animated",
  "sort_order": 6,
  "is_active": true,
  "variants": [
    {
      "prompt": "An illustration of a person in the style of a high-budget 1990s Japanese anime film. Vibrant flat cel-shaded colors, dramatic deep crisp shadows, delicate line art. Dynamic composition with stylized atmospheric background details. Makoto Shinkai style, masterwork, 4k anime wallpaper.",
      "image": "https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=600&auto=format&fit=crop"
    },
    {
      "prompt": "An illustration of a person in the style of Studio Ghibli. Soft, lush watercolor backgrounds with vivid green foliage. The character outline is slightly textured and organic. Warm, nostalgic summer afternoon lighting, peaceful atmosphere, masterpiece.",
      "image": "https://images.unsplash.com/photo-1541562232579-512a21360020?q=80&w=600&auto=format&fit=crop"
    }
  ]
}
```

---

### 6.4 — Adding New Prompts Later

Once the table and endpoint are set up, adding new prompts to the app requires **zero app releases** — just insert a new row into the `pre_prompts` table with `is_active = true` and the app will show it automatically on next open.

To add a new category, insert prompts with the new category name and inform the app developer — one line needs to be added to the category chips list in the app.

---

## Summary Checklist

| # | Task | Endpoint | Status |
|---|------|----------|--------|
| 1 | Accept Base64 avatar, store, return hosted URL | `PUT /api/profile` | ⬜ |
| 2 | Return `avatar` URL in login / me responses | `POST /auth/login`, `POST /auth/google`, `GET /auth/me` | ⬜ |
| 3 | Change password with current password verification | `PUT /api/profile/password` | ⬜ |
| 4 | Send 6-digit OTP to email for password reset | `POST /api/auth/password/forgot` | ⬜ |
| 5 | Verify OTP and set new password | `POST /api/auth/password/reset` | ⬜ |
| 6 | Create `pre_prompts` table | — | ⬜ |
| 7 | Seed table with all 6 prompt groups above | — | ⬜ |
| 8 | Build `GET /api/pre-prompts` endpoint | `GET /api/pre-prompts` | ⬜ |

---

## Notes

- Token format: `Authorization: Bearer <token>` — JWT or Sanctum both work
- `pre_prompts` images: Unsplash URLs are included for the seed data. You may keep them or re-host on your own CDN — the app loads any public HTTPS image URL
- `sort_order`: lower number = appears first in the masonry grid
- `is_active = false`: hides a prompt without deleting it — useful for seasonal content
- When adding a brand new category, let the app developer know the exact category name string so it can be added to the filter chips in the app
