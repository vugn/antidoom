# How AntiDoom Counts Videos

AntiDoom does not count *scroll events*. It counts **distinct videos** that actually appear on screen. As a result:

- a swipe that bounces back isn't counted,
- scrolling in the comment sheet isn't counted,
- one swipe that fires many events isn't counted several times,
- a video that advances on its own (auto-advance, no scroll event) is still counted.

The main code lives in:

| File | Responsibility |
| :--- | :--- |
| `android/.../services/ReelDetector.kt` | Reads the screen and builds the video fingerprint |
| `android/.../services/AntiDoomAccessibilityService.kt` | Schedules screen reads, applies counting rules, check-ins & blocks |
| `android/.../utils/TrackerPrefs.kt` | Stores daily counts & the history of counted videos |

---

## Overview

```text
accessibility event (any type)
        │   only a trigger, never counted directly
        ▼
in a short-video feed?  ── no ──> ignore
        │ yes
        ▼
read the screen (at most every 250 ms)
        │
        ▼
ReelDetector.detect()
   ├─ Paused  (comments/share sheet open) ──> don't count
   ├─ NoKey   (layout can't be read)      ──> fallback: count swipe gestures
   └─ Reel(fingerprint)
        │
        ▼
fingerprint changed? ── no ──> still the same video
        │ yes
        ▼
stable for ≥ 750 ms?  ── not yet ──> check again later (quick flicks / half-visible videos don't count)
        │ yes
        ▼
already counted today (last 40)? ── yes ──> "revisit", not counted
        │ no
        ▼
+1 video  →  floating counter, check-in every N, block at M
```

---

## 1. When you're "in a short-video feed"

Each app is checked for an on-screen element specific to its feed that is currently **visible** (`isVisibleToUser`), for example `reel_recycler` in YouTube Shorts or `clips_viewer_view_pager` in Instagram Reels. Regular home feeds, Explore and Search are not counted.

## 2. The video fingerprint

`ReelDetector` walks the accessibility tree of the visible page, up to 500 nodes. Only nodes whose **centre is inside the screen** are read, so the previous and next videos are ignored. From those nodes it takes:

1. **Creator**, taken from:
   - an `@handle`, including handles inside sentences such as "Go to channel @x" or "Subscribe to @x";
   - Instagram's "Reel by x" pattern.
2. **Caption**: the longest of up to 4 candidate texts, cut to 40 characters. An expanded caption ("… more") therefore still matches the same video.

Text that is **discarded**, because it changes while the same video plays or doesn't identify the video:

- Numbers: likes, views, comments, timestamps ("2 hours ago"). Every digit run is replaced with `#`.
- Button labels, in English & Indonesian: Like/Suka, Share/Bagikan, Follow/Ikuti, Subscribe, Remix, Save/Simpan, "View product", "Show more", "Original sound", "Reposted", "Liked by", and similar.
- Video progress ("0 minutes 1 second of 0 minutes 42 seconds").
- Short text, under 12 characters.

The final fingerprint has the form `creator|caption`.

### Privacy

Each part of the fingerprint is **hashed** (first 6 bytes of SHA-256) before it is compared or stored. The history on the phone therefore contains values like `3f9a1c0b2e7d|a81c…`, not creator names or captions. The readable text only appears in the `adb logcat -s AntiDoomDetect` log of **debug** builds. Nothing is sent anywhere.

## 3. Counting rules

| Rule | Value | Why |
| :--- | :--- | :--- |
| Screen-read throttle | 250 ms | Events arrive constantly while a video plays |
| Minimum time on screen | 750 ms | Videos that only pass by during a quick or half swipe aren't counted |
| Video history | last 40, per day, persisted | Scrolling back to an earlier video doesn't count it again, even after the process restarts |
| Same video, text still loading | treated as the same | `@x` followed by `@x\|caption` is one video (`sameReel`: one fingerprint's parts are contained in the other's) |
| Comment / share sheet open | paused | Comment text must not change the fingerprint |

## 4. Fallback

If an app's screen can't be read (`NoKey`), for example after a layout change, AntiDoom falls back to the old method: one vertical swipe gesture counts once. Events less than 500 ms apart belong to the same swipe, and horizontal swipes are ignored.

Once a fingerprint has been read successfully in an app, the fallback is turned off for that app so swipes aren't counted twice. X (Twitter) always uses the fallback, because its timeline isn't a one-video-per-screen feed.

## 5. Known limitations

- If the caption can't be read and only the creator name is available, two different videos from the same creator on the same day can be treated as one.
- Element IDs and labels can change when the target app updates. Check the `AntiDoomDetect` log in a debug build, then update the ID/label lists in `ReelDetector.kt`.
- Fingerprinting supports YouTube Shorts, Instagram Reels, TikTok and Facebook Reels, all tested on a Xiaomi (HyperOS 3, Android 16) in November 2026.
- YouTube also covers modified builds (Morphe, ReVanced, ReVanced Extended, Vanced and any other `*.android.youtube` package, see `YouTubeApps.kt`). Their view ids use their own package as the prefix (`app.morphe.android.youtube:id/reel_recycler`), so every Shorts id is built from the package on screen.
- Facebook 585 strips view ids (`(name removed)`). The reel page is the node described "Reels tab details" that covers the screen centre (on Home the same node sits off-screen to the right); the creator comes from "View X's reels" / "Follow X" and the caption from that node's parent description. Indonesian labels are guessed, not yet checked on a device.
- Instagram only fingerprints inside a visible `clips_viewer_view_pager`, so profile pages never count as a reel.
- The floating counter shows only in a short-video feed. When the screen reads "not a feed" twice, 0.7 s apart, it hides (profile, DMs, search, account switcher, Home), and it comes back when the feed does.
- TikTok reads the video page directly: the visible `<package>:id/view_rootview` that covers the screen centre, the creator from `:id/title` (a display name, no "@") and the caption from `:id/desc` (cut at the "…more" tail). Without a `view_rootview` on screen (profile, inbox, search, shop) TikTok is not treated as a feed. Tested on TikTok 47.6.3 (`com.ss.android.ugc.trill`) on Xiaomi HyperOS 3: 10 swipes counted 10, scrolling back and the comments sheet counted nothing.

## Debugging

```bash
# every screen read & every counted video (debug builds)
adb logcat -s AntiDoomDetect
```

Example:

```text
V AntiDoomDetect: scan [com.instagram.android]: Reel(key=…, label=@sahabatkuncup|rasanya ada tuntutan…)
D AntiDoomDetect: counted [com.instagram.android]: @sahabatkuncup|rasanya ada tuntutan…
D AntiDoomDetect: revisit, not counted: @small_vaness|small_vaness and mmracing_chiptuning
```
