# Spec: 01 — Search → Manga Details

## Status

Accepted for implementation (amended 2026-08-05: iOS 18, Home launch, list row = cover+title, Detail screen IA = meta now / chapters same screen later).

## Objective

Deliver the first vertical slice of the MVP:

> An anonymous user can search MangaDex by title, browse results, and open a manga **title page** (Detail) with enough metadata to decide whether to read later.

This validates networking, domain mapping, SwiftUI navigation, and loading/empty/error UX. The Detail screen is the long-term home for **title info + chapter list** on one scrollable page; **chapters are deferred to the next slice on that same screen** (not a separate destination). Reader remains later still.

Aligned with:

- Product delivery order §1: `docs/mvp-product-scope.md`
- Architecture: `docs/decisions/ADR-001-ios-architecture.md`
- Visual rules: `docs/ui-contract.md`
- MangaDex API: [Swagger](https://api.mangadex.org/docs/swagger.html)
- MangaDex client policy (source of truth): `docs/decisions/ADR-001-ios-architecture.md` §9
- MangaDex limits (upstream): [Limitations and Requirements](https://api.mangadex.org/docs/2-limitations/)
- Acceptable use (upstream): [MangaDex API docs](https://api.mangadex.org/docs/)



## Assumptions

Correct these before coding if wrong:

1. Preferred display language for titles/descriptions is **English (`en`)**, with fallback to the first available localized string.
2. Default `contentRating` filter for search is `safe` **+** `suggestive` **only** (exclude erotica/pornographic until Preferences exist).
3. Slice 01 includes a minimal SwiftUI app shell (`TabView`: Home / Search / Library). Home and Library can remain thin placeholders; **default selected tab is Home**.
4. **No** follow/favorite persistence in this slice (ADR: SwiftData starts with library step).
5. **No chapter list and no reader in this slice.** Chapters will be added later **on the same Detail screen** (below metadata), not as a separate pushed screen.
6. Draft Figma Home/Chapters screens are **inspiration only**; Search has no Figma — use native SwiftUI + UI contract. Figma’s combined title+chapters layout is the intended end-state IA for Detail.
7. Existing Alamofire + `NetworkServiceProtocol` draft is reused; views never decode raw MangaDex DTOs.
8. Deployment floor is **iOS 18+** (project/app targets aligned; no iOS 26-only APIs required).
9. Search runs **on submit only** (not while typing).
10. Search results support **pagination** (load more via `limit` / `offset`).
11. Detail is pushed **only from Search’s `NavigationStack`** in this slice (Detail remains a reusable feature for later tabs).
12. Production API host is **`https://api.mangadex.org`** (not `api.mangadex.dev`).
13. Draft authenticated follow endpoint stubs are **removed** until auth exists.
14. First-load loading UX uses **skeleton placeholders** (SwiftUI `.redacted`); load-more uses a footer spinner.
15. Networking follows **ADR-001 §9** (User-Agent, rate limits, pagination caps, 429 handling).
16. Search result rows show **cover + localized title only** (no author/artist on the list).
17. Detail navigates by **manga id** and loads `GET /manga/{id}` (may pass title for the nav bar).
18. Default launch tab is **Home**; a Preferences setting to choose the default tab is **out of scope** until Preferences exist.



## User stories

1. As a user, I open the app on **Home**, then can switch to Search, type a title query, and submit to search.
2. As a user, I see matching manga with **cover and title**, and can load more pages of results.
3. As a user, I can tap a result and see a Detail **title page** (cover, title, synopsis, status, tags, author/artist when available).
4. As a user, I understand loading, empty, and error states and can retry failed requests.



## Success criteria

Concrete, testable:

- [ ] App launches with **Home** selected; Search and Library tabs are reachable.
- [ ] Search tab is reachable from the app root without UIKit coordinator navigation for this flow.
- [ ] Submitting a non-empty trimmed title (keyboard search / explicit submit) calls `GET /manga` with `title`, `limit`, `offset`, `includes[]=cover_art`. Typing alone does **not** fire requests.
- [ ] Empty/whitespace submit does not call the API; idle/prompt state remains.
- [ ] Results list shows **cover thumbnail + primary title only**; missing cover shows a placeholder. Prefer list cover quality suffix `.256.jpg` when available.
- [ ] User can load additional pages (increase `offset`) until no more results (`offset + pageCount >= total` or empty page), without requesting `offset + limit > 10_000`.
- [ ] First search / first detail load shows **skeleton** UI (`.redacted` placeholders), not only a bare spinner.
- [ ] Load-more uses a list footer progress indicator (not a full-list skeleton).
- [ ] Query with no matches shows `ContentUnavailableView`-style empty results.
- [ ] Network/API failure (including HTTP 429) shows an error state with retry; retries are user-driven or backed off — no tight auto-retry loops.
- [ ] All MangaDex API requests send a non-spoofed app `User-Agent`.
- [ ] Tapping a row **pushes** Detail inside Search’s `NavigationStack` by **manga id** and loads `GET /manga/{id}` with `includes[]` for cover, author, artist (detail is not prefetched for every list row).
- [ ] Detail (title page) shows: cover, title, synopsis (or “No description”), publication status if present, tags (truncate to ~8 with remainder indicated), authors/artists when included in relationships.
- [ ] Detail does **not** show a chapter list yet, but the screen/layout is owned as the future home for chapters (no separate Chapters route introduced).
- [ ] Unit tests cover title localization fallback and at least one repository/mapper path with a fake network + fixture JSON.
- [ ] No crash on missing optional fields (null description, missing cover art relationship).
- [ ] No `follow` / `unfollow` MangaDex endpoints remain in the networking layer for this slice.



## Out of scope

- Chapter list UI and chapter feed API (**same Detail screen later** — not a separate Chapters screen)
- Reader, downloads
- Library save / Continue Reading / SwiftData
- Preferences / default-tab picker (launch stays Home until then)
- Advanced filters (tags, year, demographic UI)
- Ratings / view counts (may need separate statistics endpoints — defer)
- MangaDex auth, follow, notifications, profile
- Home “Most Popular” polish / pixel Figma parity
- Swinject, TCA, custom design system
- Custom shimmer libraries / animated skeleton kits (use `.redacted` only)
- Image/API reverse proxy backend (web hotlink/CORS proxy rules; not required for native slice 01)



## Tech stack (this slice)


| Layer   | Choice                                                                                    |
| ------- | ----------------------------------------------------------------------------------------- |
| UI      | SwiftUI, `NavigationStack`, `.searchable`, `List`, `AsyncImage`, `ContentUnavailableView` |
| State   | `@Observable` view models                                                                 |
| Network | Alamofire behind `NetworkServiceProtocol`                                                 |
| API     | MangaDex production `https://api.mangadex.org` (not `api.mangadex.dev`)                  |
| DI      | Manual composition at feature/app root                                                    |
| Tests   | Swift Testing + hand-written fakes (no mock framework)                                    |




## Commands

```bash
# Open / build in Xcode
xed ShinyMangaApp.xcworkspace

# Unit tests (scheme may vary — use the app’s test scheme in Xcode)
xcodebuild test -workspace ShinyMangaApp.xcworkspace -scheme ShinyMangaApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Adjust simulator name to what’s installed locally.

## Project structure (target)

Per ADR-001 — create only what this slice needs:

```text
ShinyMangaApp/
  App/                         # SwiftUI entry, root TabView
  Features/
    Search/
      SearchView.swift
      SearchViewModel.swift
    MangaDetail/
      MangaDetailView.swift
      MangaDetailViewModel.swift
  Core/
    Networking/                # migrate/reuse existing Services/Network
    Models/                    # domain Manga, etc.
    Mapping/                   # DTO → domain (optional folder)
  DesignSystem/                # color helpers only if needed
```

Legacy UIKit coordinators / placeholders: replace or bypass for the Search path in a bootstrap step before or with this slice (see Tasks).

## MangaDex mapping



### Search — `GET /manga`

Suggested query params for MVP:


| Param              | Value                                                              |
| ------------------ | ------------------------------------------------------------------ |
| `title`            | Submitted query (trimmed; skip request if empty)                   |
| `limit`            | **20** default; never greater than **100** (MangaDex collection cap) |
| `offset`           | Page offset for load-more (`0`, then `20`, `40`, …)                |
| `includes[]`       | **`cover_art` only** (list shows cover + title; no author/artist)  |
| `contentRating[]`  | `safe`, `suggestive`                                               |
| `order[relevance]` | use if supported cleanly — else omit                               |

Repository should expose total/count (or enough metadata) so the UI can stop loading when there is no next page.

**Pagination hard stop (MangaDex):** reject or avoid requests where `offset + limit > 10_000`. Stop “load more” before that ceiling.




### Detail — `GET /manga/{id}`


| Param        | Value                           |
| ------------ | ------------------------------- |
| `includes[]` | `cover_art`, `author`, `artist` |




### Domain model (minimum)

```text
Manga
  id: UUID
  title: String                 // localized
  description: String?          // localized
  status: String?               // ongoing | completed | hiatus | cancelled
  tags: [String]                // display names
  authors: [String]
  artists: [String]
  coverURL: URL?                // built from uploads host + manga id + filename
```

Cover pattern (MangaDex uploads):

`https://uploads.mangadex.org/covers/{mangaId}/{fileName}`

For **search list** thumbnails, prefer the `.256.jpg` quality suffix when building `coverURL`. Detail may use a larger/default cover.

### Localization helper

For `title` / `description` maps:

1. Prefer `en`
2. Else first non-empty value in the map
3. Else `"Untitled"` / `nil` description



### Explicit non-use this slice

- Authenticated follow APIs (`PUT/DELETE /manga/{id}/follow`): **delete** draft endpoint stubs from the networking layer until auth exists — do not leave unused call sites.
- `api.mangadex.dev`: reserved for experimental MangaDex features / separate rate-limit bucket; **not** the default host for this app.



## MangaDex API compliance (this slice)

**Do not redefine global policy here.** Follow `docs/decisions/ADR-001-ios-architecture.md` §9.

Slice-01 applications of that policy:

| Concern | Slice 01 behavior |
| ------- | ----------------- |
| Host | `https://api.mangadex.org` only |
| Search trigger | Submit only (reduces request rate vs typing debounce) |
| In-flight search | One at a time; ignore/cancel stale responses on new submit |
| List row | Cover + title only; `includes[]=cover_art` |
| Detail loading | Only when a row is opened by id — no list-wide detail prefetch |
| Pagination | Default `limit` **20** (≤ 100); stop load-more before `offset + limit > 10_000` |
| Errors | Map 429 (and other failures) to retryable UI; no tight auto-retry loops |
| Covers | Native `AsyncImage` from uploads CDN per ADR §9 image exception; list prefers `.256.jpg` |
| Endpoints | Anonymous `GET /manga`, `GET /manga/{id}` only; delete follow stubs |
| Chapters | Not in this slice; next slice extends **same** Detail screen |



## UX behavior


| State        | Search                                              | Detail (title page)                                    |
| ------------ | --------------------------------------------------- | ------------------------------------------------------ |
| Idle         | Prompt to type a title and submit                   | N/A                                                    |
| Loading      | **Skeleton rows** via `.redacted(reason: .placeholder)` | **Skeleton** title-page layout via `.redacted`        |
| Loading more | Footer/spinner while fetching next `offset` page    | N/A                                                    |
| Success      | Cover + title rows; load-more when more pages exist | Metadata sections (chapters region empty / omitted)    |
| Empty        | No results for submitted query                      | Rare if navigated from list; handle deleted/missing id |
| Error        | Message + Retry (incl. rate-limit friendly copy)    | Message + Retry                                        |

**Search trigger:** keyboard search / explicit submit only. Do not debounce-search on every keystroke in this slice.

**Skeleton:** presentation-only — does not change request volume. Prefer system `.redacted` over custom shimmer packages.

**Navigation:** Detail is a reusable feature module, but slice 01 only pushes it from Search’s `NavigationStack`. No deep links, universal links, or cross-tab detail routing yet.

**Screen IA (phased):** One `MangaDetail` title page. Slice 01 ships metadata only. A later slice appends the chapter list **below** on this same screen — do not invent a separate Chapters route.

Follow `docs/ui-contract.md` for color, type, spacing, and native controls.

## Testing strategy


| Level  | What                                                                                                               |
| ------ | ------------------------------------------------------------------------------------------------------------------ |
| Unit   | Mapper/localization; repository search/detail with `FakeNetworkService` + JSON fixtures under `ShinyMangaAppTests` |
| Manual | Simulator: search a known title (e.g. “One Piece”), open detail, airplane mode retry                               |
| UITest | Optional later; not required to close this slice                                                                   |




## Boundaries

**Always**

- Keep business logic out of SwiftUI views (view models / repositories).
- Map API → domain before the UI.
- Handle missing optionals defensively.
- Use UI contract tokens (no one-off Figma hex).
- Obey **ADR-001 §9** for all MangaDex traffic.

**Ask first**

- Adding SPM dependencies.
- Changing content-rating defaults.
- Raising deployment target.
- Calling authenticated MangaDex endpoints.
- Introducing an image/API proxy service.
- Changing global MangaDex compliance (amend ADR-001, don’t fork policy in a feature spec).

**Never**

- Decode MangaDex DTOs inside views.
- Store API secrets in the repo (public API needs none for anonymous read).
- Scope creep into chapter feed/reader/library in this slice (chapters belong on Detail **later**, same screen).
- Call or keep draft MangaDex follow/unfollow endpoints without auth.
- Default the client to `api.mangadex.dev` for normal development or release builds.
- Fire search on every keystroke or tight-loop retry on 429.
- Spoof `User-Agent` or omit it on API calls.
- Duplicate or contradict ADR-001 §9 in this file.



## Suggested implementation order

1. **Bootstrap** — SwiftUI `App` / root `TabView` (Home / Search / Library); **Home selected by default**; Search hosts real UI. Remove unused follow endpoint stubs from networking draft. Align deployment docs with **iOS 18**.
2. **Domain + DTOs + mappers** — fixtures from real MangaDex (`api.mangadex.org`) responses.
3. **Repository** — `search(title:offset:)` (paginated, capped, `cover_art` only) and `detail(id:)` on protocol; Alamofire against production host with app `User-Agent` and 429-aware errors.
4. **Search UI + VM** — submit-only query, skeleton first load, cover+title rows, pagination/load more, push Detail by id.
5. **Detail UI + VM** — title-page metadata only (skeleton then content); reserve layout ownership for a future chapters section on the **same** view.
6. **Tests + manual verification** against success criteria (incl. pagination cap / empty submit / mapper fixtures).



## Decisions (resolved)

| # | Question | Decision |
| - | -------- | -------- |
| 1 | Search trigger | **Submit only** (no typing debounce) |
| 2 | Pagination | **Yes** — `limit`/`offset` load more in slice 01 |
| 3 | Detail navigation | **Push inside Search’s `NavigationStack` only**; Detail stays reusable for later entry points |
| 4 | Follow endpoint stubs | **Delete** until auth exists |
| — | API host | **`https://api.mangadex.org`**; do not use `api.mangadex.dev` as default (ADR-001 §3 / §9) |
| — | Loading UX | **Skeleton** via `.redacted` for first load; footer spinner for load-more |
| — | API limits | **ADR-001 §9** is source of truth; this slice applies submit-only + pagination caps |
| — | Launch tab | **Home**; Preferences may choose default tab later |
| — | Search row | **Cover + title only** (`includes[]=cover_art`); list cover prefers `.256.jpg` |
| — | Detail payload | Navigate by **id**; Detail loads `GET /manga/{id}` |
| — | Chapters IA | **Same Detail screen** as title info; chapters **not** in slice 01 (phased option B) |
| — | Deployment | **iOS 18** |

## After this slice ships

Do **not** block coding on the items below. Finish optional slice-01 tasks if needed, **implement Search → Detail (title page)**, verify success criteria, then start the next vertical slice.

Later (after slice 01 works):

- Spec/tasks for **chapters on the same Detail screen** → Reader (do **not** introduce a separate Chapters route)
- SwiftData library/progress
- Thin Home browse using the same manga row component
- Preferences: optional default-tab choice (Home vs Search vs Library)
- Optional: sync draft Figma colors to catalog (catalog already wins)
- Optional: shared routing / deep links when Home or Library also open Detail

