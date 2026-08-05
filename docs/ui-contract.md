# UI Contract (MVP)

Lean visual rules for SwiftUI screens. Not a full design system — enough consistency for slice work without waiting on polished Figma.

Related: `docs/mvp-product-scope.md`, `docs/decisions/ADR-001-ios-architecture.md`.

## Design reference (draft only)

Incomplete community-draft mockups (Home + Chapters only). **Not** the implementation source of truth — this UI contract and ADR-001 win when they conflict.

- File: [Manga - Webtoon App (Community) - Copy](https://www.figma.com/design/4jqGCyeCX6b53QLyTr74aS/Manga---Webtoon-App--Community---Copy-)
- File key: `4jqGCyeCX6b53QLyTr74aS`

Use for mood/inspiration later. Do not block slice work waiting on a finished Figma or a design system.

## Principles

1. **Native SwiftUI first** — use system controls (`.searchable`, `List`, `NavigationStack`, `ContentUnavailableView`, `AsyncImage`, `.refreshable`) before custom chrome.
2. **Code tokens beat draft Figma** — asset catalog colors are canonical. Update Figma later to match, not the other way around.
3. **Design after real payloads** — validate layouts against MangaDex samples (missing cover, long titles, empty tag lists); avoid pixel-perfect mockups of imaginary data.
4. **Dark-only for MVP** — screens use the dark palette below. Light mode is out of scope.

## Color tokens (canonical)

Source: `ShinyMangaApp/Assets.xcassets/AppColors/`.

| Token | Hex | Role |
|-------|-----|------|
| `Background` | `#121212` | Screen background |
| `CardBackground` | `#1E1E1E` | Elevated surfaces / grouped rows |
| `AccentPrimary` | `#E50914` | Primary actions, selected tab accent |
| `AccentSecondary` | `#FF1744` | Optional highlight (use sparingly) |
| `TextPrimary` | `#FFFFFF` | Titles, primary labels |
| `TextSecondary` | `#B3B3B3` | Subtitles, metadata |
| `TextDisabled` | `#757575` | Disabled / placeholder |
| `ErrorRed` | `#F44336` | Error text / destructive emphasis |
| `SuccessGreen` | `#4CAF50` | Success feedback (rare in slice 01) |
| `WarningOrange` | `#FF9800` | Warnings |
| `StarYellow` | `#FFD700` | Rating star (when shown) |

**Conflict note:** Draft Figma used `#DA0037` / `#171717`. Those are superseded by the table above.

Prefer SwiftUI `Color("AccentPrimary")` (or project color helpers) over hard-coded hex in views.

## Typography

Use semantic Dynamic Type styles — no fixed pt sizes for body copy in MVP:

| Role | Style |
|------|--------|
| Screen title | `.largeTitle` or `.title` |
| Section / manga title | `.headline` or `.title2` |
| Body / synopsis | `.body` |
| Metadata (status, tags) | `.subheadline` or `.caption` |
| Secondary footer | `.caption2` |

Bold via `.fontWeight(.semibold)` on titles only. Avoid custom fonts until a later design pass.

## Spacing

Use a 4pt base scale:

| Token | Points | Typical use |
|-------|--------|-------------|
| `xs` | 4 | Tight icon gaps |
| `sm` | 8 | Inline padding |
| `md` | 12 | Compact stacks |
| `lg` | 16 | Default screen / row padding |
| `xl` | 24 | Section separation |

Default list/row horizontal inset: **16**. Avoid one-off spacings outside this scale unless matching a system control.

## Components needed for early slices

Build only what screens need (start with Search → Details):

| Piece | Implementation preference |
|-------|---------------------------|
| Cover thumbnail | `AsyncImage` + placeholder; fixed aspect (e.g. 2:3) |
| Search / result row | `List` / `NavigationLink` with **cover + title only** |
| Loading (first load) | **Skeleton** via `.redacted(reason: .placeholder)` on stand-in rows / detail layout |
| Loading more | List footer `ProgressView` — not a full-list skeleton |
| Empty / error | `ContentUnavailableView` + retry when recoverable (incl. rate-limit failures) |
| Manga Detail | Single title page: metadata now; **chapter list later on the same screen** |
| Screen chrome | System nav bar; no floating custom tab chrome until Home polish |

**Skeleton rules:** use system `.redacted` only in MVP — no custom shimmer SPM packages. Skeleton is visual only; it must not cause extra MangaDex requests.

Do **not** invent a component library (buttons, chips, cards kit) before these pieces exist in real screens.

## Network / MangaDex (UI-relevant)

Full client policy: `docs/decisions/ADR-001-ios-architecture.md` §9.

For UI authors:

- Prefer submit-driven refresh over continuous polling
- On error/429, show retry UI — do not auto-spam the API
- Credit MangaDex in an About/Settings surface before public builds
- Skeleton loading must not trigger extra network calls

## Navigation & chrome

Per ADR-001:

- Root: `TabView` — Home, Search, Library
- **Default selected tab: Home** (Preferences may change this later)
- In-tab: `NavigationStack`
- Prefer system tab bar over draft Figma floating red pill for MVP learning
- Manga Detail is one screen (title info + future chapters); do not design a separate Chapters destination

Large titles optional on Search/Home; details may use inline title with cover hero.

## Accessibility (minimum)

- Meaningful accessibility labels on cover-only controls and icon buttons
- Dynamic Type: do not clip primary titles at default/largest reasonable sizes
- Contrast: primary text on `Background` / `CardBackground` only; avoid white text on busy artwork without a scrim if overlays are added later

## Out of scope (for now)

- Full Figma redesign / component kit
- Custom reader chrome
- Light mode
- Matching incomplete Home / Chapters draft pixel-for-pixel
- Brand typography and motion system

## Follow-up

Slice-01 spec: `docs/specs/01-search-to-manga-details.md`.
