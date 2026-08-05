# ADR-001: iOS Architecture for MVP

## Status

Accepted (amended 2026-08-02: MangaDex API client compliance; amended 2026-08-05: iOS 18 deployment floor, Detail screen IA)

## Date

2026-07-27

## Context

ShinyMangaApp is a solo learning project: an iOS manga reader with SwiftUI, to learn SwiftUI fluency. Product scope is defined in `docs/mvp-product-scope.md`.

MVP outcome:

> A user can find a manga, open a chapter, read it, leave, and resume later.

Constraints from product scope:

- iOS only
- MangaDex as the only catalog/chapter source ([API docs](https://api.mangadex.org/docs/swagger.html), [limitations](https://api.mangadex.org/docs/2-limitations/))
- Online-first, anonymous (no MangaDex login in MVP)
- Local library and reading progress
- Prefer delivering a thin vertical slice (Search → Detail title page first) over completeness

Current codebase draft:

- UIKit `AppDelegate` / `SceneDelegate` + coordinator pattern (`MainCoordinator`, tab coordinators)
- SwiftUI screens are placeholders hosted in `UIHostingController`
- Alamofire 5.10 behind `NetworkServiceProtocol` + endpoint enums
- Swinject is present in Package.resolved but unused in app code
- Semantic color assets exist under `Assets.xcassets/AppColors/`
- Deployment target: **iOS 18** (project and app targets aligned)

We need a single architecture decision so slice-01 and later work do not mix competing patterns (UIKit coordinators vs SwiftUI navigation, Swinject vs manual wiring, SwiftData vs ad-hoc persistence). Choosing MangaDex also obligates every network feature to honor their published client limitations — that policy belongs here, not only in individual feature specs.

## Decision



### 1. UI: SwiftUI-first, NavigationStack for feature navigation

- New feature UI is SwiftUI.
- Use `TabView` + `NavigationStack` for the root shell and in-tab navigation.
- Prefer native SwiftUI APIs for learning: `.searchable`, `List`, `AsyncImage`, `ContentUnavailableView`, `.refreshable`.
- Do not extend the UIKit coordinator pattern for new features.
- Treat the existing `AppDelegate` / `SceneDelegate` / coordinator shell as draft scaffolding to replace when implementing the first real screens (or in a dedicated bootstrap task before slice-01).

Rationale: the primary learning goal is SwiftUI (navigation, state, lists, async UI). Keeping UIKit coordinators as the long-term navigation model splits attention and under-represents the skills most SwiftUI interview loops exercise.

### 2. State: `@Observable` view models (Observation framework)

- Screen state lives in `@Observable` types owned by views (or injected via environment for shared services).
- Avoid introducing Combine-heavy `ObservableObject` / `@Published` as the default for new code unless bridging a library that requires it.

Rationale: iOS 18+ is the floor; Observation is the current recommended path and simpler for new learners than dual Combine/Observation mental models.

### 3. Networking: keep Alamofire behind a protocol

- Keep `NetworkServiceProtocol` + `AlamofireNetworkService`.
- Keep typed endpoint enums (`APIEndpoint`, `MangaEndpoints`).
- Map MangaDex JSON into app domain models in a repository layer; views do not decode raw API DTOs.
- Default API host is production **`https://api.mangadex.org`**. Do not default to `api.mangadex.dev` (dev/experimental host with a separate rate-limit bucket).
- All MangaDex client code must follow **§9 MangaDex API client compliance** below.

Rationale: Alamofire is already integrated and useful for request building/validation. Hiding it behind a protocol keeps tests injectable and leaves room to swap later without rewriting features. A single host + shared compliance policy prevents each feature from inventing its own rate-limit or User-Agent behavior.

### 4. Dependency wiring: manual composition, not Swinject (MVP)

- Construct network/repository/view-model dependencies at the app/root or feature entry.
- Depend on protocols at boundaries (`NetworkServiceProtocol`, repositories) so tests can inject fakes/mocks.
- Do not adopt Swinject for MVP feature work.

Rationale: a DI container adds indirection before the object graph is understood. Manual composition is enough for a solo MVP, teaches ownership clearly, and still supports testing (see Testing below). Swinject remains in the workspace only until deliberately removed or revisited in a later ADR.

### 5. Persistence: SwiftData for local library and progress

- When implementing library/resume (delivery order step 3), use SwiftData for saved titles and reading progress.
- Slice 01 (Search → Details) may ship with no persistence beyond optional lightweight preferences if needed.

Rationale: product scope requires local library/progress without accounts. SwiftData is Apple’s current persistence path on supported iOS versions and is a high-value learning target. UserDefaults alone will not scale cleanly once chapter progress exists.

### 6. App structure: feature folders + shared infrastructure

Suggested layout (adjust names as needed, keep the separation):

```text
ShinyMangaApp/
  App/                 # entry, root TabView
  Features/
    Search/
    MangaDetail/
    Reader/            # later
    Library/           # later
    Home/              # later
  Core/
    Networking/        # protocol, Alamofire, endpoints
    Models/            # domain models
    Persistence/       # SwiftData models/stores (when needed)
  DesignSystem/        # colors/theme helpers only; not a full component library yet
```

Rationale: feature folders map to vertical slices; shared networking/persistence stay thin.

### 7. Tabs for MVP (product over incomplete Figma)

Initial tabs:

1. Home (browse — thin placeholder until after Search → Detail → Reader; **default selected tab at launch**)
2. Search
3. Library (local favorites / continue reading)

Do not build Explore, notifications, or profile/auth for MVP. A Preferences setting to choose the default launch tab is deferred until Preferences exist.

### 7a. Manga Detail screen IA

- **One** Detail / title-page screen owns cover, metadata, and (later) the chapter list on a single scrollable page.
- Slice 01 ships metadata only on that screen.
- Do **not** introduce a separate “Chapters” route; append chapters in a later slice on the same `MangaDetail` feature.

### 8. Testing without Swinject

Skipping Swinject does **not** block tests. Both layers remain viable:


| Layer                                                 | What it covers                                               | How without Swinject                                                     |
| ----------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------ |
| **Unit tests** (`ShinyMangaAppTests`)                 | Repositories, view models, mappers, sorting/pagination logic | Inject fake `NetworkServiceProtocol` / repository stubs via initializers |
| **UI automation** (`ShinyMangaAppUITests` / XCUITest) | Tap search, see results, open details                        | Drive the running app by accessibility labels; no DI container required  |


Interview-relevant habit: keep business logic out of SwiftUI views so unit tests stay easy; use UI tests sparingly for critical flows (e.g. Search → Details).

### 9. MangaDex API client compliance

**Source of truth** for MangaDex request policy across the whole app. Feature specs apply these rules; they do not redefine them.

Official docs:

- [Limitations and Requirements](https://api.mangadex.org/docs/2-limitations/)
- [Acceptable Usage Policy](https://api.mangadex.org/docs/)
- [Swagger](https://api.mangadex.org/docs/swagger.html)

#### Required client behavior

| Rule | App expectation |
| ---- | ---------------- |
| HTTPS / TLS | Call `https://api.mangadex.org` (TLS 1.2+; prefer 1.3) |
| `User-Agent` required, not spoofed | Every API request sends an app-identifying UA, e.g. `ShinyMangaApp/<version> (iOS)` — never omit or impersonate a browser |
| No `Via` header | Do not route API calls through non-transparent proxies that inject `Via` |
| ~5 requests/second per IP | Design UIs and repositories to stay polite (batch via `includes[]`, avoid per-keystroke fan-out, avoid prefetching detail for every list row) |
| HTTP **429** | Surface a recoverable error; back off; **do not** tight-loop retry (persistence can escalate to temporary **403** / IP blocks) |
| Collection `limit` | Never request more than **100** (MangaDex collection cap; feeds may allow higher later — check Swagger per endpoint) |
| Collection window | Never request where `offset + limit > 10_000` |
| Acceptable use | Credit MangaDex; no ads or paid access to API-provided content; honor scanlation removal rules when reading ships |
| Efficiency | Prefer one sufficient request over many redundant ones |

#### Images (covers / pages)

MangaDex docs require **web** clients to proxy API/image traffic (CORS / hotlink rules). For this **native iOS** learning MVP, loading images via `AsyncImage` (or equivalent) from `uploads.mangadex.org` / `@Home` CDNs is accepted **without** a reverse-proxy backend. Revisit if shipping a web client or if MangaDex blocks direct mobile loads. Still require polite rates, proper API `User-Agent`, and MangaDex credit.

#### Endpoint-specific limits

Additional per-endpoint quotas exist (writes, auth, `GET /at-home/server/{id}`, etc.). Anonymous MVP read paths (`GET /manga`, `GET /manga/{id}`) are unlikely to hit them in normal use. Chapter/reader work **must** respect `@Home` and any feed limits when those endpoints are adopted.

#### Ownership

- Implement shared helpers in `Core/Networking` (default headers, pagination guards, 429 mapping).
- Feature specs document *how* they stay polite (e.g. search-on-submit), not a second copy of the global table.

### 10. Non-goals (architecture)

- MangaDex OAuth / account sync
- Multi-source providers
- Offline download pipeline
- Full design system / custom component kit before real screens exist
- VIPER / TCA / full coordinator frameworks for MVP
- Defaulting to `api.mangadex.dev` or omitting `User-Agent`
- Image/API reverse-proxy backend for the native MVP



## Alternatives Considered



### Keep UIKit coordinators long-term + SwiftUI views

- Pros: Matches current draft; familiar if coming from UIKit apps; explicit navigation objects.
- Cons: Weakens SwiftUI learning; more bridging (`UIHostingController`); duplicates navigation concepts.
- Rejected for MVP direction: learning SwiftUI is a primary project goal.



### Pure URLSession instead of Alamofire

- Pros: No third-party dependency; forces deeper networking learning.
- Cons: Reworks existing draft; more boilerplate for validation/decoding pipeline.
- Rejected for now: keep Alamofire; revisit only if the abstraction leaks badly.



### Use Swinject for all dependencies

- Pros: Explicit container; scales in large teams.
- Cons: Overkill for solo MVP; hides construction; steeper learning curve alongside SwiftUI.
- Rejected for MVP.



### UserDefaults / files only for library and progress

- Pros: Minimal setup for first save flag.
- Cons: Awkward for relationships (manga ↔ chapters ↔ progress); weaker query/model story.
- Rejected as the primary store once library/progress ships; SwiftData preferred.



### The Composable Architecture (TCA)

- Pros: Strong testability and unidirectional data flow.
- Cons: Steep learning cost; heavy for first SwiftUI project; slows MVP delivery.
- Rejected for MVP.



## Consequences



### Positive

- Clear SwiftUI learning path aligned with product delivery order.
- Networking draft can be reused rather than rewritten.
- Local-first MVP stays implementable without auth backend.
- Shared MangaDex compliance avoids contradictory per-feature rate-limit behavior.
- Later ADRs can supersede pieces (e.g. introduce Swinject, replace Alamofire) without rewriting product scope.



### Negative / tradeoffs

- Existing UIKit coordinator bootstrap becomes throwaway or migration work.
- Swinject in Package.resolved is unused debt until removed.
- SwiftData has a learning curve and migration story once models evolve.
- Native SwiftUI screens will not match the incomplete Figma draft initially (accepted: UI contract + later design pass).
- Direct CDN image loads are a pragmatic exception to MangaDex’s web proxy guidance; may need revisiting for production/web.



### Follow-ups

1. ~~Write `docs/ui-contract.md`~~ (done — keep UI notes pointing at this ADR for network policy).
2. ~~Write `docs/specs/01-search-to-manga-details.md`~~ (done — apply §9; do not duplicate the full compliance table).
3. Plan bootstrap task: SwiftUI app entry replacing coordinator shell (before or as part of slice 01).
4. Optionally remove unused Swinject package when cleaning dependencies.
5. Centralize `User-Agent`, pagination caps, and 429 handling in `Core/Networking` when implementing slice 01.



## References

- Product scope: `docs/mvp-product-scope.md`
- UI contract: `docs/ui-contract.md`
- Slice 01: `docs/specs/01-search-to-manga-details.md`
- MangaDex API: [https://api.mangadex.org/docs/swagger.html](https://api.mangadex.org/docs/swagger.html)
- MangaDex limitations: [https://api.mangadex.org/docs/2-limitations/](https://api.mangadex.org/docs/2-limitations/)
- MangaDex acceptable use: [https://api.mangadex.org/docs/](https://api.mangadex.org/docs/)
- Existing draft: `AppDelegate.swift`, `MainCoordinator.swift`, `Services/Network/*`

