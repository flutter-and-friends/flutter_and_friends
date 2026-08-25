# Badge Creator + NDEF Collection — Spec

Status: proposal (not yet implemented)
Work item: WI-015
App repo: `felangel/flutter_and_friends` · Package repo: `flutter-and-friends/friends_badge`

## 1. Summary

Add a **badge frame creator** to the Flutter & Friends app. A user composes their
conference badge from:

- an **image** — one of 32 bundled capybaras **or** a photo from their phone,
- optional **text** — name + role/title, in a couple of curated fonts,
- a **template** that arranges image and text on the badge,

then writes the result to the e-paper badge over NFC — exactly as the app does
today for plain images.

In addition, the `friends_badge` package gains **NDEF write/read** so a badge can
store a small data payload (a profile URL + name/socials). This unlocks two
experiences from a single tap:

- **Any phone** tapping the badge opens the stored URL directly (Twitter,
  LinkedIn, personal site, …) — no app required.
- **A phone with the F&F app** can *collect* the person — name + links stored
  locally, Capydex-style — so you remember who you spoke to after the conference.

## 2. Background & constraints (verified against source)

- **Panel**: 240 × 416 px portrait, palette `blackWhiteYellowRed`
  (`BadgeSpecification.size3_7inchPassiveBWRY`).
- **Badge NFC**: a **NFC Forum Type 4 Tag** (see `friends_badge/docs/NFC_FORMAT.md`).
  The NDEF data area is a file addressed via ISO-DEP `SELECT` / `READ BINARY` /
  `UPDATE BINARY` — the *same transport* the image write already uses
  (`IsoDepAndroid` / `Iso7816Ios` behind the package's `NfcWriter` abstraction).
  → NDEF write is **purely additive**; it does not interfere with the custom
  `0xD0 0xD1` image-chunk protocol.
- **Package today only writes the image bitmap**
  (`CommonNfcImplementation.writeOverNfc`). There is **no NDEF API** yet.
- **Existing app flow** (`lib/friends_badge/`): `FriendsBadgeCubit` →
  `FriendsBadgePage`: pick image → `BadgeImage` → dither-kernel carousel →
  `WriteToBadgeButton` (`WaitingForNfcTap.showLoading(job: image.writeToBadge(kernel: k))`).
  The new creator feeds into this same pipeline.

## 3. Capybara assets — DONE

All 32 images from the Drive folder are downloaded and copied to:

```
assets/badge_templates/capybaras/   (32 files, 8.8 MB)
```

Decision: **bundle in-app** (works offline, no network dependency).

Remaining asset chores (part of implementation):

- Register the folder in `pubspec.yaml` under `flutter.assets`
  (`- assets/badge_templates/capybaras/`).
- Expose a constant list of asset paths (generated or hand-written) for the
  gallery picker.

## 4. Badge Creator (app)

New screen, reachable from the existing **Friends Badge** settings entry
(replaces / extends `FriendsBadgePage`).

### 4.1 Flow

1. **Pick an image source**: capybara gallery (grid of 32) or phone gallery
   (existing `image_picker` flow).
2. **Pick a template** (see §5).
3. **Enter text** (name, role) when the template uses it.
4. **Pick a font** (see §6).
5. **Live preview** at badge resolution, reusing the existing dither-kernel
   carousel (`BadgeImage.allSupportedKernels`).
6. **Write**: existing `writeToBadge`; optionally also write NDEF (§7) when the
   user provided a link.

### 4.2 State

Extend `FriendsBadgeCubit` / `FriendsBadgeState` with: selected template, name,
role, font choice, and the composed `BadgeImage`. Composition is pure
Dart/image work — no NFC until "Write" is tapped.

## 5. Templates (4)

All render to a 240 × 416 canvas. Text is drawn with `TextPainter` onto an
offscreen `Canvas`, rasterized to `img.Image`, wrapped in `BadgeImage`.

| # | Template | Layout |
|---|----------|--------|
| 1 | **Image Only** | Full-bleed image. Identical to today's behaviour (no text). |
| 2 | **Classic** | Image top ~60%, horizontal divider, name (large) then role (smaller) below. Matches the example: `{image}` / `-------` / `Johannes Pietilä Löhnn` / `Organizer`. |
| 3 | **Overlay** | Full-bleed image with a solid band across the bottom holding name + role. |
| 4 | **Framed** | Image inset with a thick border + accent stripe (red/yellow), name/role beneath. |

Text colours come from the badge palette (black/white + optional red/yellow
accent) so the image quantizes cleanly.

## 6. Fonts

Two curated faces via `google_fonts`:

- a **bold display** face for the name,
- a **clean sans** for the role.

Rationale: the panel is low-resolution and dithered; a heavy name face survives
quantization, and a neutral sans keeps the role legible. Rendered in pure
black/white (never mid-gray) to avoid dither noise on glyphs.

## 7. NDEF support (friends_badge package)

Owned by the package (user maintains it). All new code — nothing existing is
modified except an optional parameter on `writeToBadge`.

### 7.1 New API surface

- `NdefRecord` / `NdefMessage` — model + builders:
  - `NdefRecord.uri(Uri)` → NFC Forum well-known **U** record.
  - `NdefRecord.text(String)` → NFC Forum **T** record.
- `NdefBadgeWriter` — Type 4 flow: `SELECT` NDEF file → `UPDATE BINARY` with the
  serialized message, over the existing `NfcWriter` abstraction.
- `NdefBadgeReader` — `SELECT` → `READ BINARY` → parse to `NdefMessage`
  (powers the Capydex collect).
- `BadgeImage.writeToBadge({NdefMessage? ndef})` — when provided, the NDEF
  message is written as an extra step after the image flash completes.

### 7.2 Payload design (one write → both experiences)

Decision: **static data only, no hosting** (avoids any GDPR surface). There is no
`flutterfriends.dev/p/<id>` profile page.

The written NDEF message contains **two records**:

```
[ U record ]  <a personal URL the user types — their LinkedIn / Twitter / site>
[ T record ]  "Johannes Pietilä Löhnn · Organizer · x.com/johannes · linkedin.com/in/johannes"
```

- **Direct-tap (any phone, no app)**: the OS reads the **U** record first →
  opens the browser to that personal link. The URL is user-supplied, not hosted
  by the conference.
- **App collect**: the F&F app reads **both** records → stores `{name, urls}`
  locally; can still offer to open the link.

Both records live on the badge together — the two experiences are not mutually
exclusive. The **T** record carries the display name + role so the dex entry has
a real name (a URL-only badge would collect a bare link).

## 8. Capydex collection (app)

- `CollectedPeopleCubit` — a `HydratedCubit`, mirroring `FavoritesCubit`'s
  persistence pattern (`fromJson`/`toJson`).
- State: list of `{name, role, urls, collectedAt}`.
- List view: collected people; tapping an entry opens their links.
- Settings entry point next to the existing Friends Badge tile.

### 8.1 Collecting: foreground dispatch (decision)

Decision: **as long as the F&F app is open (in the foreground), tapping a badge
collects it to the dex** — no manual "Collect" button press required first.

- **Android**: foreground dispatch — the app registers for NFC tags while in the
  foreground, so a tap that would normally make the OS open the browser is
  delivered to the app *first*. The app parses the badge, adds the person, shows
  a "Collected ⟨name⟩ ✓" confirmation, and does **not** leave the app / open a
  browser.
- **iOS**: Core NFC has no silent background handoff to a foreground app, but the
  app holds an NFC reader session open while on the badge/dex screen, so a tap
  collects in place. Same user experience: app open → tap → collected.

> ⚠️ **Needs on-device confirmation.** NFC foreground dispatch / reader-session
> behaviour cannot be exercised in the container — verify on real Android and iOS
> hardware during implementation.

## 9. Implementation order

1. **`friends_badge`: NDEF write** — foundational, independently testable.
2. **App: Badge Creator** — gallery + templates + text + fonts (fastest visible
   value).
3. **`friends_badge`: NDEF read**.
4. **App: Capydex collection**.

## 10. Out of scope / open questions

- **Profile page hosting** (`flutterfriends.dev/p/<id>`): **descoped.** Static
  badge data only, no hosting, no GDPR surface. The URL on the badge is a
  personal link the user types themselves.
- **vCard record vs URL+text**: vCard is richer but heavier and less universally
  surfaced by phone OSes than a plain URL. **URL + text** chosen for v1.
- **Active-badge NDEF write path**: whether it goes over BLE or the same NFC
  path — resolve against the active-badge protocol when implementing §7.
