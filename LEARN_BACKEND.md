# Learn Section — Backend Requirements
**For: Backend Developer**
**App: Vakya Pro**
**Feature: In-app Learn Videos**

---

## Overview

The app has a **Learn** section accessible from the sidebar.
It displays a list of tutorial/help **videos** (YouTube or any direct video URL) loaded from the backend, so content can be added or updated without releasing a new app version.

### How the app uses backend data

| Field          | What the app does with it |
|----------------|---------------------------|
| `video_url`    | Opens in the device browser / YouTube app when the card is tapped |
| `thumbnail_url`| Used as the card cover image. **If null**, the app automatically extracts the YouTube thumbnail from `video_url` using `https://img.youtube.com/vi/{VIDEO_ID}/hqdefault.jpg` — so you don't need to set this manually for YouTube links |
| `title`        | Shown below the thumbnail as the card title |
| `description`  | Shown as a subtitle line on the card |
| `category`     | Used for the filter chips (`Basics`, `Voice`, `Tips`, `Settings`) |
| `duration`     | Display label shown as a badge on the thumbnail corner (e.g. `"5:30"`) |
| `sort_order`   | Controls the display order (ascending) |
| `is_active`    | If `false`, the row is excluded from API response |
| `views_count`  | Read-only counter; can be shown on the card if needed |

**Loading behaviour:** The app shows animated skeleton (placeholder) cards while the API call is in flight, then replaces them with real data. If the call fails, built-in fallback cards are shown instead — no error state is visible to the user.

---

## What You Need to Build

### 1. Database Table — `learn_videos`

| Column          | Type           | Notes |
|-----------------|----------------|-------|
| `id`            | BIGINT (PK)    | Auto-increment |
| `title`         | VARCHAR(255)   | Video title shown on the card |
| `description`   | TEXT           | Short subtitle (1-2 sentences) |
| `category`      | VARCHAR(50)    | One of: `Basics`, `Voice`, `Tips`, `Settings` (extendable — tell the frontend dev when you add new ones) |
| `video_url`     | VARCHAR(500)   | Full YouTube URL or any video URL (e.g. `https://youtu.be/abc123` or `https://www.youtube.com/watch?v=abc123`) |
| `thumbnail_url` | VARCHAR(500)   | **Optional.** Leave null for YouTube videos — the app auto-generates the thumbnail. Set this for non-YouTube videos or to override the auto-thumbnail. |
| `duration`      | VARCHAR(20)    | Display label only — e.g. `"5:30"`, `"10:02"`. Not computed by the app. |
| `sort_order`    | INT            | Display order, ascending. Default 0. |
| `is_active`     | BOOLEAN        | Only `true` rows are returned to the app. Default `true`. |
| `created_at`    | TIMESTAMP      | Auto-set on insert |
| `updated_at`    | TIMESTAMP      | Auto-set on update |

---

### 2. API Endpoint — `GET /api/learn`

**Auth:** Required (Bearer JWT token — same as all other protected endpoints)

**Returns:** All rows where `is_active = true`, ordered by `sort_order ASC, id ASC`

#### Success Response — `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Getting Started with Vakya Pro",
      "description": "A quick intro to the app — chat, voice mode, and more.",
      "category": "Basics",
      "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "thumbnail_url": null,
      "duration": "3:12",
      "sort_order": 1,
      "is_active": true,
      "views_count": 102
    },
    {
      "id": 2,
      "title": "How to Use Voice Mode",
      "description": "Hands-free AI conversations using continuous voice mode.",
      "category": "Voice",
      "video_url": "https://youtu.be/SomeVideoId",
      "thumbnail_url": null,
      "duration": "4:45",
      "sort_order": 2,
      "is_active": true
    }
  ]
}
```

### 2.1 — View tracking — `POST /api/learn/{id}/view`

Record a watch event for analytics and counters.

Request:
```json
{
  "watch_duration_ms": 6200,
  "is_completed": true
}
```

Rules:
- Adds `watch_duration_ms` to total watch time.
- If `watch_duration_ms >= 1000` (1 second), `views_count` increments by 1.
- Recommended to send once on exit or every 5–10 seconds (debounced).

Response 200:
```json
{
  "views_count": 103,
  "watch_time_ms": 43210
}
```

#### Error Response — `401 Unauthorized`

```json
{
  "success": false,
  "message": "Unauthenticated."
}
```

> **Note:** The app reads the `data` key from the response map. If you return a plain JSON array at the top level, that also works — the app handles both formats.

---

### 3. How YouTube Thumbnail Auto-Extraction Works

You do **not** need to set `thumbnail_url` for YouTube videos.

The app parses `video_url` and extracts the YouTube video ID, then constructs:
```
https://img.youtube.com/vi/{VIDEO_ID}/hqdefault.jpg
```

Supported YouTube URL formats:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://www.youtube.com/embed/VIDEO_ID`
- `https://www.youtube.com/shorts/VIDEO_ID`

For **non-YouTube** video URLs (Vimeo, direct MP4, etc.) you must set `thumbnail_url` manually, otherwise the card shows a purple gradient placeholder.

---

### 4. Admin / CMS Access

You need a way to manage videos without a code deploy. Options:

- **Option A** — Admin CRUD endpoints:
  `POST /api/admin/learn`, `PUT /api/admin/learn/{id}`, `DELETE /api/admin/learn/{id}`

- **Option B** — Manage directly via existing admin dashboard / DB.

The team needs to be able to:
- Add new video rows
- Edit `video_url`, `title`, `description`, `category`, `duration`, `thumbnail_url`, `sort_order`
- Toggle `is_active` to publish/unpublish without deleting

---

### 5. Seed Data (Copy-Paste Ready)

Insert these rows to get the section live immediately.
Replace `video_url` values with real YouTube links before going to production.

```sql
INSERT INTO learn_videos
  (title, description, category, video_url, thumbnail_url, duration, sort_order, is_active)
VALUES
(
  'Getting Started with Vakya Pro',
  'A quick intro to the app — chat, voice mode, and more.',
  'Basics',
  'https://www.youtube.com/watch?v=REPLACE_ME',
  NULL, '3:12', 1, true
),
(
  'How to Use Voice Mode',
  'Hands-free AI conversations using continuous voice mode.',
  'Voice',
  'https://www.youtube.com/watch?v=REPLACE_ME',
  NULL, '4:45', 2, true
),
(
  'Writing Better Prompts',
  'Tips for getting the best responses from the AI.',
  'Tips',
  'https://www.youtube.com/watch?v=REPLACE_ME',
  NULL, '5:20', 3, true
),
(
  'Changing Language Settings',
  'Switch the app and AI language in seconds.',
  'Settings',
  'https://www.youtube.com/watch?v=REPLACE_ME',
  NULL, '2:05', 4, true
),
(
  'Managing Your Profile',
  'Update name, avatar, and password from the profile page.',
  'Settings',
  'https://www.youtube.com/watch?v=REPLACE_ME',
  NULL, '3:30', 5, true
),
(
  'Image Generation Tips',
  'Get stunning AI images with the right prompt keywords.',
  'Tips',
  'https://www.youtube.com/watch?v=REPLACE_ME',
  NULL, '6:15', 6, true
);
```

---

### 6. Adding New Categories

Current filter chips in the app: `All` | `Basics` | `Voice` | `Tips` | `Settings`

If you add a new category (e.g. `Advanced`), **tell the frontend developer** to add the string to the `_categories` list in [lib/screens/learn_page.dart](lib/screens/learn_page.dart). Until then, videos with unknown categories will not appear in any filter tab (but they do appear under "All").

---

### 7. Summary Checklist

- [ ] Create `learn_videos` table with the columns above
- [ ] Implement `GET /api/learn` (auth-protected, `is_active = true`, ordered by `sort_order`)
- [ ] Response shape: `{ "success": true, "data": [...] }`
- [ ] `thumbnail_url` can be `null` — app handles it for YouTube URLs automatically
- [ ] Insert 6 seed rows (replace `REPLACE_ME` with real YouTube video IDs)
- [ ] Optionally expose admin CRUD endpoints or manage via DB/admin panel directly
