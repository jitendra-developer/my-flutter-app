# Reels — Backend Implementation Guide
### Vakya Pro · `https://api.vakyapro.com/api`

> **The Flutter app is already complete.**
> Every API call, request body, and expected response shape is hardcoded in the app.
> Once the backend implements these endpoints exactly as documented below,
> the Reels feature will work with **zero app rebuild required**.

---

## Quick Reference — All Endpoints the App Calls

| # | Method | Endpoint | Auth | Purpose |
|---|--------|----------|------|---------|
| 1 | GET | `/api/reels` | ✅ Bearer | Fetch all reels for the Feed |
| 2 | POST | `/api/reels/{id}/like` | ✅ Bearer | Toggle like on a reel |
| 3 | POST | `/api/reels/{id}/save` | ✅ Bearer | Toggle save on a reel |
| 4 | POST | `/api/reels/{id}/share` | ✅ Bearer | Record a share, increment `shares_count` |
| 4 | GET | `/api/reels/{id}/comments` | ✅ Bearer | Fetch comments for a reel |
| 5 | POST | `/api/reels/{id}/comments` | ✅ Bearer | Post a comment on a reel |
| 6 | POST | `/api/reels/{id}/view` | ✅ Bearer | Record watch duration and view count |
| — | POST | `/api/admin/reels` | ✅ Bearer + Admin role | Admin uploads a new reel |
| — | PUT | `/api/admin/reels/{id}` | ✅ Bearer + Admin role | Admin edits a reel |
| — | DELETE | `/api/admin/reels/{id}` | ✅ Bearer + Admin role | Admin deletes a reel |

> All requests include `Authorization: Bearer {token}` and `Accept: application/json`.

---

## 1. Database Tables

### `reels`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK AUTO | |
| `created_by` | BIGINT FK → users | Admin who uploaded |
| `title` | VARCHAR(255) | Shown on reel card and player |
| `description` | TEXT nullable | Short caption / subtitle |
| `prompt` | TEXT nullable | The AI prompt the video demonstrates |
| `video_url` | VARCHAR(500) nullable | YouTube URL **or** direct CDN mp4/HLS URL |
| `video_path` | VARCHAR(500) nullable | Internal storage path if file was uploaded |
| `thumbnail_url` | VARCHAR(500) nullable | If null, app auto-generates from YouTube ID |
| `is_active` | BOOLEAN default 1 | Only active reels returned to users |
| `order` | INT default 0 | Manual sort override (lower = first) |
| `views_count` | BIGINT default 0 | Increment on view |
| `watch_time_ms` | BIGINT default 0 | Sum of all view durations in milliseconds |
| `likes_count` | BIGINT default 0 | Denormalised counter — used for Trending/Popular sort |
| `saves_count` | BIGINT default 0 | Denormalised counter |
| `shares_count` | BIGINT default 0 | Denormalised counter |
| `comments_count` | BIGINT default 0 | Denormalised counter |
| `created_at` | TIMESTAMP | Used for Latest sort |
| `updated_at` | TIMESTAMP | |

### `reel_likes`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK AUTO | |
| `reel_id` | BIGINT FK → reels CASCADE DELETE | |
| `user_id` | BIGINT FK → users CASCADE DELETE | |
| `created_at` | TIMESTAMP | |

**Unique constraint:** `(reel_id, user_id)` — one like per user per reel.

### `reel_saves`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK AUTO | |
| `reel_id` | BIGINT FK → reels CASCADE DELETE | |
| `user_id` | BIGINT FK → users CASCADE DELETE | |
| `created_at` | TIMESTAMP | |

**Unique constraint:** `(reel_id, user_id)` — one save per user per reel.

### `reel_comments`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK AUTO | |
| `reel_id` | BIGINT FK → reels CASCADE DELETE | |
| `user_id` | BIGINT FK → users CASCADE DELETE | |
| `body` | TEXT | Comment text, max 2000 chars |
| `is_visible` | BOOLEAN default 1 | Soft-hide for moderation |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

### `reel_shares`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK AUTO | |
| `reel_id` | BIGINT FK → reels CASCADE DELETE | |
| `user_id` | BIGINT FK → users CASCADE DELETE | |
| `created_at` | TIMESTAMP | |

### `reel_view_events`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK AUTO | |
| `reel_id` | BIGINT FK → reels CASCADE DELETE | |
| `user_id` | BIGINT FK → users CASCADE DELETE | |
| `watch_duration_ms` | INT | Milliseconds watched for this event |
| `is_completed` | BOOLEAN default 0 | If user reached end |
| `created_at` | TIMESTAMP | |

---

## 2. Endpoint Contracts

### 2.1 — GET `/api/reels`

The app calls this on Feed page open and on pull-to-refresh.

**Request:**
```
GET /api/reels
Authorization: Bearer {token}
Accept: application/json
```

No query params required (app does not paginate yet — return all active reels).
You may add `page` / `per_page` in the future without breaking anything.

**Optional query params:**
- `saved_only=1` → returns only reels the user has saved (for Saved tab)

**Response — the app reads these fields:**
```json
{
  "data": [
    {
      "id": 1,
      "title": "Cinematic Drone Shot",
      "description": "Use this AI prompt to create a drone video.",
      "prompt": "Create a cinematic aerial drone shot over misty mountains at sunrise...",
      "video_url": "https://youtube.com/shorts/dQw4w9WgXcQ",
      "thumbnail_url": null,
      "views_count": 840,
      "likes_count": 120,
      "saves_count": 45,
      "shares_count": 18,
      "comments_count": 18,
      "is_liked": false,
      "is_saved": true,
      "is_shared": false,
      "is_liked": false,
      "is_saved": true,
      "created_at": "2026-03-10T08:00:00Z"
    }
  ]
}
```

**Critical fields the app uses:**

| Field | Used for |
|-------|---------|
| `id` | Like / Save / Comment API calls |
| `video_url` | Playback — YouTube URLs auto-detected by regex, direct mp4 streamed via VideoPlayer |
| `thumbnail_url` | Grid thumbnail — if `null`, app extracts from YouTube URL automatically |
| `is_liked` | Heart icon state in player |
| `is_saved` | Bookmark icon state in player + grid badge |
| `shares_count` | Share counter display |
| `likes_count` | Counter shown in player; also used for **Trending / Popular sort** in Feed |
| `created_at` | Used for **Latest sort** in Feed |

**Sort order to return:** `ORDER BY is_active DESC, order ASC, created_at DESC`
(active reels, manual order first, then newest).

**N+1 prevention:** Eager-load `is_liked` and `is_saved` with a subquery or `loadExists`, not a loop.

---

### 2.2 — POST `/api/reels/{id}/like`

**Request:**
```
POST /api/reels/5/like
Authorization: Bearer {token}
Accept: application/json
(no body needed)
```

**Behaviour:**
- If the user has **not** liked this reel → insert row in `reel_likes`, increment `reels.likes_count`
- If the user **has** already liked → delete row, decrement `reels.likes_count`
- Use `firstOrCreate` / `updateOrCreate` with atomic increment to avoid race conditions

**Response:**
```json
{
  "liked": true,
  "likes_count": 121
}
```

The app reads `liked` (bool) and `likes_count` (int) to update the UI immediately without refetching the full list.

---

### 2.3 — POST `/api/reels/{id}/save`

Same toggle logic as likes but for saves.

**Request:**
```
POST /api/reels/5/save
Authorization: Bearer {token}
Accept: application/json
(no body needed)
```

**Response:**
```json
{
  "saved": true,
  "saves_count": 46
}
```

The app reads `saved` (bool) and `saves_count` (int).

---

### 2.4 — POST `/api/reels/{id}/share`

**Request:**
```
POST /api/reels/5/share
Authorization: Bearer {token}
Accept: application/json
(no body needed)
```

**Response:**
```json
{
  "shared": true,
  "shares_count": 19
}
```

---

### 2.5 — GET `/api/reels/{id}/comments`

**Request:**
```
GET /api/reels/5/comments
Authorization: Bearer {token}
Accept: application/json
```

**Response:**
```json
{
  "data": [
    {
      "id": 7,
      "body": "Create a cinematic video showing a sunrise over mountains with golden hour lighting...",
      "user": {
        "id": 42,
        "name": "Priya S.",
        "avatar": "https://cdn.vakyapro.com/avatars/42.jpg"
      },
      "created_at": "2026-03-15T10:22:00Z"
    }
  ]
}
```

- Return `ORDER BY created_at DESC` (newest first)
- Only return rows where `is_visible = true`
- The app shows an **"AI Prompt"** badge on comments longer than 60 characters — no backend work needed for that
- Include `user.avatar` as a URL string or `null`

---

### 2.6 — POST `/api/reels/{id}/comments`

**Request:**
```
POST /api/reels/5/comments
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json

{
  "body": "This prompt is incredible, try adding 'neon lights' for a cyberpunk version!"
}
```

**Validation:**
- `body`: required, string, max 2000 characters

**Behaviour:** Insert row into `reel_comments`, increment `reels.comments_count` by 1.

**Response:**
```json
{
  "data": {
    "id": 99,
    "body": "This prompt is incredible...",
    "user": {
      "id": 5,
      "name": "Rahul K.",
      "avatar": null
    },
    "created_at": "2026-03-17T09:00:00Z"
  }
}
```

---

### 2.7 — POST `/api/reels/{id}/view`

Record watch duration and increment view counter if the watch time passes the minimum threshold.

**Request:**
```
POST /api/reels/5/view
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json

{
  "watch_duration_ms": 5200,
  "is_completed": false
}
```

**Behaviour:**
- Always adds `watch_duration_ms` to `reels.watch_time_ms`
- If `watch_duration_ms >= 1000` (1s), increments `reels.views_count` by 1

**Response:**
```json
{
  "views_count": 841,
  "watch_time_ms": 1234567
}
```

---

## 3. Admin: Upload / Manage Reels

Admins upload reels from the backend panel (not the Flutter app).

### POST `/api/admin/reels`

```
POST /api/admin/reels
Authorization: Bearer {admin_token}
Content-Type: multipart/form-data

Fields:
  title          string, required, max:255
  description    string, nullable
  prompt         string, nullable          ← the AI prompt the video demonstrates
  video_url      string, nullable          ← YouTube link OR direct CDN URL
  video_file     file, nullable            ← mp4 / webm (max 500 MB recommended)
  thumbnail_url  string, nullable
  order          integer, nullable, default 0
  is_active      boolean, nullable, default true
```

**Logic:**
- If `video_file` is provided → upload to S3 / R2 / GCS at `reels/{id}/video.mp4`, set `video_path`, set `video_url` to the **permanent public CDN URL**
- If `video_url` is a YouTube URL and `thumbnail_url` is null → leave null (app auto-generates from YouTube ID)
- Validate: at least one of `video_url` or `video_file` must be provided

### PUT `/api/admin/reels/{id}`

Same fields as POST, all optional. Used to update title, description, prompt, toggle active, change order.

### DELETE `/api/admin/reels/{id}`

Soft-delete (`is_active = false`) or hard-delete — your choice. If hard-delete, cascade to `reel_likes`, `reel_saves`, `reel_comments`.

---

## 4. Storage & CDN

- Store uploaded video files under `reels/{id}/video.mp4` in your cloud bucket (S3 / Cloudflare R2 / GCS)
- `video_url` in the DB **must be a permanent public URL** — do **not** use expiring signed URLs, as the app streams directly without re-fetching
- Thumbnails stored at `reels/{id}/thumb.jpg` — set `thumbnail_url` to the CDN URL
- For YouTube reels, leave `thumbnail_url` null — the app builds the thumbnail as:
  `https://img.youtube.com/vi/{youtube_id}/hqdefault.jpg`

**Supported video formats the app can play:**
- YouTube (any youtube.com/watch, youtu.be, youtube.com/shorts, youtube.com/embed URL)
- Direct mp4 / HLS (`.m3u8`) hosted on CDN

---

## 5. Permissions

| Action | Who can do it |
|--------|--------------|
| View reel list | Any authenticated user |
| Like / Unlike | Any authenticated user |
| Save / Unsave | Any authenticated user |
| Post comment | Any authenticated user |
| Delete own comment | Comment owner or admin |
| Hide comment | Admin only (set `is_visible = false`) |
| Upload reel | Admin only |
| Edit / Delete reel | Admin only |

---

## 6. Recommended Database Indexes

```sql
-- Fast is_liked / is_saved lookup per user
CREATE UNIQUE INDEX idx_reel_likes_user ON reel_likes (reel_id, user_id);
CREATE UNIQUE INDEX idx_reel_saves_user ON reel_saves (reel_id, user_id);

-- Comments: newest first per reel
CREATE INDEX idx_reel_comments_reel_date ON reel_comments (reel_id, created_at DESC);

-- Feed list: active reels, sorted by order and date
CREATE INDEX idx_reels_feed ON reels (is_active, `order`, created_at DESC);

-- Trending / Popular sort
CREATE INDEX idx_reels_likes ON reels (is_active, likes_count DESC);

-- High watch time
CREATE INDEX idx_reels_watch ON reels (is_active, watch_time_ms DESC);
```

---

## 7. Laravel Migration Snippets

```php
// reels
Schema::create('reels', function (Blueprint $table) {
    $table->id();
    $table->foreignId('created_by')->constrained('users');
    $table->string('title');
    $table->text('description')->nullable();
    $table->text('prompt')->nullable();
    $table->string('video_url', 500)->nullable();
    $table->string('video_path', 500)->nullable();
    $table->string('thumbnail_url', 500)->nullable();
    $table->boolean('is_active')->default(true);
    $table->integer('order')->default(0);
    $table->unsignedBigInteger('views_count')->default(0);
    $table->unsignedBigInteger('watch_time_ms')->default(0);
    $table->unsignedBigInteger('likes_count')->default(0);
    $table->unsignedBigInteger('saves_count')->default(0);
    $table->unsignedBigInteger('shares_count')->default(0);
    $table->unsignedBigInteger('comments_count')->default(0);
    $table->timestamps();
    $table->index(['is_active', 'order', 'created_at']);
    $table->index(['is_active', 'likes_count']);
    $table->index(['is_active', 'shares_count']);
    $table->index(['is_active', 'watch_time_ms']);
});

// reel_likes
Schema::create('reel_likes', function (Blueprint $table) {
    $table->id();
    $table->foreignId('reel_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->timestamp('created_at')->useCurrent();
    $table->unique(['reel_id', 'user_id']);
});

// reel_saves
Schema::create('reel_saves', function (Blueprint $table) {
    $table->id();
    $table->foreignId('reel_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->timestamp('created_at')->useCurrent();
    $table->unique(['reel_id', 'user_id']);
});

// reel_comments
Schema::create('reel_comments', function (Blueprint $table) {
    $table->id();
    $table->foreignId('reel_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->text('body');
    $table->boolean('is_visible')->default(true);
    $table->timestamps();
    $table->index(['reel_id', 'created_at']);
});

// reel_shares
Schema::create('reel_shares', function (Blueprint $table) {
    $table->id();
    $table->foreignId('reel_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->timestamp('created_at')->useCurrent();
});

// reel_view_events
Schema::create('reel_view_events', function (Blueprint $table) {
    $table->id();
    $table->foreignId('reel_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->unsignedInteger('watch_duration_ms')->default(0);
    $table->boolean('is_completed')->default(false);
    $table->timestamp('created_at')->useCurrent();
});
```

---

## 8. Laravel Resource — Exact Response Shape

The app expects these **exact field names**. Do not rename them.

```php
// app/Http/Resources/ReelResource.php

public function toArray($request): array
{
    $user = $request->user();

    return [
        'id'             => $this->id,
        'title'          => $this->title,
        'description'    => $this->description,
        'prompt'         => $this->prompt,
        'video_url'      => $this->video_url,
        'thumbnail_url'  => $this->thumbnail_url,
        'views_count'    => $this->views_count,
        'shares_count'   => $this->shares_count,
        'likes_count'    => $this->likes_count,
        'saves_count'    => $this->saves_count,
        'comments_count' => $this->comments_count,
        'is_liked'       => $user
            ? $this->whenLoaded('likedByUser', true, false)  // see tip below
            : false,
        'is_saved'       => $user
            ? $this->whenLoaded('savedByUser', true, false)
            : false,
        'is_shared'      => false, // fill via scoped relationship or EXISTS subquery
        'created_at'     => $this->created_at?->toIso8601String(),
    ];
}
```

**Avoiding N+1 on the list endpoint — scoped relationship trick:**

```php
// In your controller:
$userId = $request->user()->id;

$reels = Reel::where('is_active', true)
    ->orderBy('order')
    ->orderByDesc('created_at')
    ->with([
        'likedByUser'  => fn($q) => $q->where('user_id', $userId),
        'savedByUser'  => fn($q) => $q->where('user_id', $userId),
    ])
    ->get();

// In Reel model:
public function likedByUser()
{
    return $this->hasMany(ReelLike::class, 'reel_id');
}

public function savedByUser()
{
    return $this->hasMany(ReelSave::class, 'reel_id');
}
```

Then in the Resource, `$this->likedByUser->isNotEmpty()` gives `is_liked` for the current user with a single query.

---

## 9. Routes (Laravel `api.php`)

```php
Route::middleware('auth:sanctum')->group(function () {

    // Reels — user-facing
    Route::get('/reels',                       [ReelController::class, 'index']);
    Route::post('/reels/{reel}/like',          [ReelController::class, 'toggleLike']);
    Route::post('/reels/{reel}/save',          [ReelController::class, 'toggleSave']);
    Route::post('/reels/{reel}/share',         [ReelController::class, 'share']);
    Route::post('/reels/{reel}/view',          [ReelController::class, 'view']);
    Route::get('/reels/{reel}/comments',       [ReelCommentController::class, 'index']);
    Route::post('/reels/{reel}/comments',      [ReelCommentController::class, 'store']);

    // Reels — admin
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::post('/reels',            [AdminReelController::class, 'store']);
        Route::put('/reels/{reel}',      [AdminReelController::class, 'update']);
        Route::delete('/reels/{reel}',   [AdminReelController::class, 'destroy']);
    });

});
```

---

## 10. What the App Does Automatically (No Backend Work Needed)

These things are handled entirely on the Flutter side — **do not implement on backend**:

| Feature | How the app handles it |
|---------|----------------------|
| YouTube thumbnail | Extracted from `video_url` regex — `https://img.youtube.com/vi/{id}/hqdefault.jpg` |
| YouTube playback | `youtube_player_flutter` package — just pass the YouTube URL |
| Direct video playback | `video_player` package — just pass the mp4/HLS CDN URL |
| Trending / Popular sort | Client-side sort by `likes_count` DESC |
| Latest sort | Client-side sort by `created_at` DESC |
| Only Videos filter | Client-side — shows only reels from Feed |
| Only Images filter | Client-side — shows only pre-prompts from Feed |
| Saved reels list | Client-side filter — shows reels where `is_saved == true` |
| Optimistic like/save UI | App updates UI instantly, rolls back on API error |
| "AI Prompt" comment badge | Applied client-side to comments longer than 60 chars |

---

## 11. Error Responses

Return standard JSON errors the app already handles:

```json
{ "message": "Unauthenticated." }           // 401
{ "message": "This action is unauthorized." } // 403
{ "message": "No query results for model."  } // 404
{ "errors": { "body": ["The body field is required."] } } // 422
```

---

*Send this file to your backend developer. Once these 5 endpoints are live at `https://api.vakyapro.com/api`, the Reels section in the Feed will be fully functional with no app update needed.*
