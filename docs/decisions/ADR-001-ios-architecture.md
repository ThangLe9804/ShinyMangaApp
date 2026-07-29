# ADR-001: iOS Architecture for MVP

## Status

Accepted

## Date

2026-07-27

## Context

ShinyMangaApp is a solo learning project: an iOS manga reader with SwiftUI, to learn SwiftUI fluency. Product scope is defined in `docs/mvp-product-scope.md`.

MVP outcome:

> A user can find a manga, open a chapter, read it, leave, and resume later.

Constraints from product scope:

- iOS only
- MangaDex as the only catalog/chapter source ([API docs](https://api.mangadex.org/docs/swagger.html))
- Online-first, anonymous (no MangaDex login in MVP)
- Local library and reading progress
- Prefer delivering a thin vertical slice (Search → Details first) over completeness

Current codebase draft:

- UIKit `AppDelegate` / `SceneDelegate` + coordinator pattern (`MainCoordinator`, tab coordinators)
- SwiftUI screens are placeholders hosted in `UIHostingController`
- Alamofire 5.10 behind `NetworkServiceProtocol` + endpoint enums
- Swinject is present in Package.resolved but unused in app code
- Semantic color assets exist under `Assets.xcassets/AppColors/`
- Deployment target: iOS 17 (app target)

We need a single architecture decision so slice-01 and later work do not mix competing patterns (UIKit coordinators vs SwiftUI navigation, Swinject vs manual wiring, SwiftData vs ad-hoc persistence).

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

Rationale: iOS 17+ is the floor; Observation is the current recommended path and simpler for new learners than dual Combine/Observation mental models.

### 3. Networking: keep Alamofire behind a protocol

- Keep `NetworkServiceProtocol` + `AlamofireNetworkService`.
- Keep typed endpoint enums (`APIEndpoint`, `MangaEndpoints`).
- Map MangaDex JSON into app domain models in a repository layer; views do not decode raw API DTOs.

Rationale: Alamofire is already integrated and useful for request building/validation. Hiding it behind a protocol keeps tests injectable and leaves room to swap later without rewriting features.

### 4. Dependency wiring: manual composition, not Swinject (MVP)

- Construct network/repository/view-model dependencies at the app/root or feature entry.
- Depend on protocols at boundaries (`NetworkServiceProtocol`, repositories) so tests can inject fakes/mocks.
- Do not adopt Swinject for MVP feature work.

Rationale: a DI container adds indirection before the object graph is understood. Manual composition is enough for a solo MVP, teaches ownership clearly, and still supports testing (see Testing below). Swinject remains in the workspace only until deliberately removed or revisited in a later ADR.

### 5. Persistence: SwiftData for local library and progress

- When implementing library/resume (delivery order step 3), use SwiftData for saved titles and reading progress.
- Slice 01 (Search → Details) may ship with no persistence beyond optional lightweight preferences if needed.

Rationale: product scope requires local library/progress without accounts. SwiftData is Apple’s current persistence path on iOS 17+ and is a high-value learning target. UserDefaults alone will not scale cleanly once chapter progress exists.

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

1. Home (browse — can stay thin until after Search → Details → Reader)
2. Search
3. Library (local favorites / continue reading)

Do not build Explore, notifications, or profile/auth for MVP.

### 8. Testing without Swinject

Skipping Swinject does **not** block tests. Both layers remain viable:


| Layer                                                 | What it covers                                               | How without Swinject                                                     |
| ----------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------ |
| **Unit tests** (`ShinyMangaAppTests`)                 | Repositories, view models, mappers, sorting/pagination logic | Inject fake `NetworkServiceProtocol` / repository stubs via initializers |
| **UI automation** (`ShinyMangaAppUITests` / XCUITest) | Tap search, see results, open details                        | Drive the running app by accessibility labels; no DI container required  |


Interview-relevant habit: keep business logic out of SwiftUI views so unit tests stay easy; use UI tests sparingly for critical flows (e.g. Search → Details).

### 9. Non-goals (architecture)

- MangaDex OAuth / account sync
- Multi-source providers
- Offline download pipeline
- Full design system / custom component kit before real screens exist
- VIPER / TCA / full coordinator frameworks for MVP



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
- Later ADRs can supersede pieces (e.g. introduce Swinject, replace Alamofire) without rewriting product scope.



### Negative / tradeoffs

- Existing UIKit coordinator bootstrap becomes throwaway or migration work.
- Swinject in Package.resolved is unused debt until removed.
- SwiftData has a learning curve and migration story once models evolve.
- Native SwiftUI screens will not match the incomplete Figma draft initially (accepted: UI contract + later design pass).



### Follow-ups

1. Write `docs/ui-contract.md` (tokens, spacing, native-first components).
2. Write `docs/specs/01-search-to-manga-details.md` against MangaDex Swagger + this architecture.
3. Plan bootstrap task: SwiftUI app entry replacing coordinator shell (before or as part of slice 01).
4. Optionally remove unused Swinject package when cleaning dependencies.



## References

- Product scope: `docs/mvp-product-scope.md`
- MangaDex API: [https://api.mangadex.org/docs/swagger.html](https://api.mangadex.org/docs/swagger.html)
- Existing draft: `AppDelegate.swift`, `MainCoordinator.swift`, `Services/Network/*`

