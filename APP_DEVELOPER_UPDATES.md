# App Developer Update — Reels + Learn Tracking
**App:** Vakya Pro (Flutter)  
**Base URL:** `https://api.vakyapro.com/api`  
**Auth:** Bearer token (same as existing protected calls)

---

## Summary

New analytics features added:
- Reels: `shares_count`, view/watch tracking via `POST /api/reels/{id}/view`
- Learn: `views_count`, view/watch tracking via `POST /api/learn/{id}/view`
- Reels feed supports `saved_only=1` for Saved tab

All read endpoints are cache-optimized for faster first paint. Write endpoints return the new counts so you can update the UI optimistically.

---

## Reels Integration

### Fetch feed
```
GET /api/reels[?saved_only=1]
Authorization: Bearer <token>
Accept: application/json
```

Response item (fields used in the app):
```json
{
  "id": 1,
  "title": "…",
  "description": "…",
  "prompt": "…",
  "video_url": "https://…",
  "thumbnail_url": null,
  "views_count": 840,
  "likes_count": 120,
  "saves_count": 45,
  "shares_count": 18,
  "comments_count": 24,
  "is_liked": false,
  "is_saved": true,
  "is_shared": false,
  "created_at": "2026-03-18T08:00:00Z"
}
```

### Like / Save / Share
- `POST /api/reels/{id}/like` → `{ "liked": true, "likes_count": 121 }`
- `POST /api/reels/{id}/save` → `{ "saved": true, "saves_count": 46 }`
- `POST /api/reels/{id}/share` → `{ "shared": true, "shares_count": 19 }`

Update the UI counters immediately using response payloads (no refetch required).

### View tracking
```
POST /api/reels/{id}/view
Authorization: Bearer <token>
Content-Type: application/json

{
  "watch_duration_ms": 5200,
  "is_completed": false
}
```
Rules:
- Adds `watch_duration_ms` to total watch time.
- If `watch_duration_ms >= 1000` (1s), increments `views_count` by 1.

Response:
```json
{ "views_count": 841, "watch_time_ms": 1234567 }
```

Suggested client behaviour (Flutter):
- Start a timer on play; accumulate milliseconds.
- Send one event when the user leaves the reel (pause/back) OR every 5–10 seconds (debounced).
- For very short watches (<3s), send anyway (counts watch time, not a view).

---

## Learn Integration

### Fetch list
```
GET /api/learn
Authorization: Bearer <token>
```

Each item includes:
```json
{
  "id": 1,
  "title": "…",
  "description": "…",
  "category": "Basics",
  "video_url": "https://www.youtube.com/watch?v=…",
  "thumbnail_url": null,
  "duration": "3:12",
  "sort_order": 1,
  "is_active": true,
  "views_count": 102
}
```

### View tracking
```
POST /api/learn/{id}/view
Authorization: Bearer <token>
Content-Type: application/json

{
  "watch_duration_ms": 6200,
  "is_completed": true
}
```

Response:
```json
{ "views_count": 103, "watch_time_ms": 43210 }
```

Client behaviour mirrors Reels (debounce + final send on exit).

---

## Error Handling
Return shapes remain unchanged. Blocked accounts receive:
```
403 { "message": "Your account is blocked." }
```
Use your existing interceptor to display a friendly message and sign the user out if required.

---

## Implementation Checklist (Flutter)

- Reels
  - [ ] Add `shares_count` and `is_shared` to model
  - [ ] Add Saved tab → call `GET /api/reels?saved_only=1`
  - [ ] Wire “Share” action to `POST /api/reels/{id}/share` and update counter
  - [ ] Start/stop timers around playback; post `watch_duration_ms` using `/reels/{id}/view`

- Learn
  - [ ] Add `views_count` to LearnVideo model
  - [ ] Post `watch_duration_ms` using `POST /api/learn/{id}/view`

- Common
  - [ ] Optimistic UI for like/save/share using response counts
  - [ ] Ensure Bearer token headers on all protected endpoints
  - [ ] Handle 403 blocked account gracefully

---

If you need code snippets in Dart for the timers/debounce or API calls, tell us which player widgets you use and we’ll tailor examples accordingly.
*** End Patch***}``` -->
