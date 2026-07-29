# Product Scope: Solo-Developer Manga Reader

## Executive Summary

The MVP should prove one outcome:

> A user can find a manga, open a chapter, read it, leave, and resume later.

Neko is useful as workflow inspiration, especially for its library, reading, downloads, synchronization, recommendations, and tracking. It should not define the scope of this product. The priority is a reliable end-to-end reading experience, not feature parity.

## 1. Current Design Compared With Core Reader Workflows

### Discover Manga

The current design includes:

- A Home screen with Most Popular, Recent Releases, and Coming Soon
- A search icon
- An Explore tab

Status: **Partially covered**

Missing:

- Search screen and results
- Pagination
- Genre, language, and content filters
- Functional "See more" destinations
- Loading, empty, and error states

### Evaluate a Title

The current design includes:

- Cover art
- Title, rating, views, and synopsis
- Favorite and share actions
- Chapter list

Status: **Mostly represented visually**

Missing:

- Author, artist, genres, publication status, and language
- Defined synopsis expansion behavior
- Chapter sorting and language selection
- Data-source attribution

Ratings and view counts may require separate MangaDex statistics data and are not represented in the current repository contract.

### Select a Chapter

The current design includes chapter rows with a chapter number, title, and thumbnail.

Status: **Visually represented but not implemented**

Missing:

- Chapter feed API
- Scanlation group and language
- Publication date
- Read/unread state
- Sort order
- Pagination
- Empty-chapter handling

### Read a Chapter

Status: **Missing**

Required:

- Fetch the chapter image manifest
- Load pages in the correct order
- Record reading progress
- Navigate to the previous or next chapter
- Handle loading and retries
- Provide basic reader controls

Without this workflow, the product is a manga browser rather than a manga reader.

### Save and Resume

The current design includes a heart action and a heart/library tab.

Status: **Entry points only**

Missing:

- Local library
- Continue Reading
- Per-title and per-chapter progress
- Mark read/unread
- Removal from library

### Account and Synchronization

The avatar and personalized greeting imply an account, but no account workflow exists.

Status: **Implied but unsupported**

Missing:

- Authentication
- Account/profile screen
- MangaDex synchronization
- Cross-device state

Account functionality should not block the MVP.

### Current Implementation State

The codebase is earlier than the Figma draft:

- MangaDex is configured as the source in `APIConstants.swift`.
- Manga list, detail, follow, and unfollow routes have been drafted.
- The repository is unfinished and currently exposes only an unimplemented seasonal-manga operation.
- Home, Search, and Library are placeholder screens.
- No chapter-feed, image-server, reader, or progress implementation exists.
- Code navigation currently says Home, Search, and About, while Figma implies Home, Favorites, and Explore.

## 2. Recommended Product Strategy

Use Neko as feature inspiration, but deliberately exclude most of its mature-reader breadth. Neko currently supports MangaDex login, offline reading, tracker integrations, recommendations, synchronization, and multi-source chapter merging. These are valuable capabilities, but they are not appropriate baseline scope for a solo-developed MVP.

Source: [Neko GitHub repository](https://github.com/nekomangaorg/Neko)

## 3. MVP

### Single MangaDex Source

Use only MangaDex plus the existing seasonal-list source.

Why:

- Already aligned with the codebase
- Avoids source adapters and inconsistent metadata
- Keeps legal, networking, and maintenance scope manageable

### Anonymous, Online-First Experience

Do not require registration or MangaDex login.

Why:

- Removes authentication and token-management work
- Lets users reach the reader immediately
- Local persistence is sufficient to validate the product

The personalized username in the design should be treated as placeholder content.

### Basic Home/Browse

Include:

- Seasonal or featured titles
- Latest updates
- A limited number of reusable title cards
- A working "See more" action only when it opens a real paginated list

Why:

- Gives users a starting point
- Can use the existing MangaDex and seasonal endpoints
- Avoids bespoke recommendation logic

"Most Popular" should remain only if its ranking is backed by real data.

### Search

Include:

- Title query
- Paginated results
- Loading, no-results, failure, and retry states

Why:

- Search is the fastest path from intent to reading
- More valuable than extensive curated Home sections
- Existing query types already support title filtering

Advanced filters are not required for the MVP.

### Manga Details

Include:

- Cover and title
- Synopsis
- Author and artist when available
- Tags
- Publication status
- Add/remove from local library
- Chapter list

Why:

- Provides enough information to choose whether to read
- Bridges discovery and reading
- Reuses the strongest part of the current Figma draft

### Chapter List

Include:

- Chapter number and title
- Language
- Publication date
- Read/unread indicator
- Newest/oldest sorting
- Pagination

Why:

- Users must be able to identify the correct chapter
- MangaDex can contain duplicate translations and multiple languages
- Read state makes long series usable

Chapter thumbnails are optional because they add network and layout cost without materially improving chapter selection.

### Basic Reader

Include:

- One reading mode: vertical scrolling
- Ordered chapter images
- Page-position indicator
- Tap to show or hide controls
- Previous/next chapter
- Retry failed pages
- Keep the screen awake while reading

Why:

- This is the core product value
- One reading mode limits complexity
- Vertical scrolling supports both manga pages and long images adequately for an MVP

Paged, right-to-left, dual-page, and webtoon-specific modes can follow later.

### Local Library

Include:

- Add/remove manga
- Saved-title list
- Last-read chapter
- Continue Reading action

Why:

- Creates repeat usage without requiring an account
- Makes the existing heart interaction meaningful
- Local persistence is much cheaper than server synchronization

### Local Reading Progress

Persist:

- Read chapters
- Current chapter
- Approximate page or scroll position
- Last-read timestamp

Why:

- Resume is essential for a reading product
- Delivers high user value with contained implementation scope

### Essential Product States

Every network screen needs:

- Loading
- Empty
- Error
- Retry
- Offline or unavailable messaging

Why:

- Manga reading depends heavily on remote images and APIs
- A functional failure state is more important than additional discovery features

## 4. Version 1.1

### Offline Chapter Downloads

Include individual chapter download, storage use, deletion, and failure recovery.

Why not MVP:

- Provides high reader value
- Requires storage management, background behavior, partial-download recovery, and cache policy
- Online reading should be proven first

### Multiple Reader Modes

Add:

- Horizontal paging
- Right-to-left paging
- Improved vertical/webtoon mode
- Image-quality preference

Why not MVP:

- Important for reading comfort
- Multiplies gesture, progress, transition, and testing complexity

### Better Discovery and Filtering

Add:

- Genres and tags
- Language
- Publication status
- Content rating
- Sort order
- Recent searches

Why not MVP:

- Helps users navigate a large catalog
- Title search and simple browsing are enough to validate initial value

### Library Management

Add:

- Sort and filter
- Manual mark read/unread
- Reading history
- Remove history
- Unread counts

Why not MVP:

- Valuable after users accumulate enough titles
- Premature for new users with a small local library

### Update Feed

Show new chapters for locally saved titles.

Why not MVP:

- Improves retention
- Can initially refresh on app open without push infrastructure

### Share and External Links

Add functional sharing and links to the source title.

Why not MVP:

- Useful but not required to discover, read, or resume
- The current share control is visually premature

### Basic Preferences

Add:

- Preferred content language
- Content-rating controls
- Reader defaults
- Data-saving image quality

Why not MVP:

- Useful after baseline defaults have been validated
- Safety-related content defaults should still be conservative in the MVP

## 5. Future

### MangaDex Account and Synchronization

Includes login, followed titles, read status, and cross-device synchronization.

Why later:

- Authentication and conflict resolution add substantial complexity
- Local state proves the workflow first

### Third-Party Tracking

Examples include MyAnimeList, AniList, Kitsu, and MangaUpdates.

Why later:

- Requires multiple OAuth integrations and data mappings
- Primarily valuable to advanced readers
- Neko parity would create unnecessary scope

### Multi-Source Chapter Merging

Why later:

- Source reliability, attribution, duplicate resolution, and maintenance become major product responsibilities
- This is a Neko power-user feature, not an MVP requirement

### Personalized Recommendations

Why later:

- Requires sufficient behavior data or external recommendation sources
- Simple seasonal/latest discovery is initially adequate

### Push Notifications

Why later:

- Requires notification infrastructure, permissions, scheduling, and preference controls
- An in-app update feed offers most of the early value

### Social and Community Features

Examples include comments, reviews, lists, profiles, follows, and sharing activity.

Why later:

- Introduces moderation, abuse prevention, privacy, and backend requirements
- Not part of the core reading proposition

### Advanced Downloads

Examples include bulk downloads, automatic next chapters, download queues, Wi-Fi rules, and storage quotas.

Why later:

- Primarily a power-user workflow
- Should be considered only after basic downloads are reliable

### Cloud Backup and Multi-Device Support

Why later:

- Requires identity and backend infrastructure
- Local persistence is enough for initial validation

### Tablet and Dual-Page Layouts

Why later:

- Requires additional responsive layouts and reader behavior
- The first release should focus on iPhone-sized devices

## 6. Explicit MVP Non-Goals

- Neko feature parity
- Multiple manga providers
- MangaDex login
- Social or community features
- Third-party trackers
- Offline downloads
- Push notifications
- Personalized recommendations
- Multiple reader modes
- Tablet-specific layouts
- Subscriptions or monetization

## 7. Delivery Order

### 1. Search to Manga Details

Validate MangaDex metadata and navigation.

### 2. Manga Details to Chapter List to Reader

Establish the first complete reading session.

### 3. Progress to Local Library to Resume

Establish repeat-use value.

### 4. Home Discovery

Reuse working title and list components.

### 5. Failure States and Release Polish

Test slow networks, missing covers, missing chapters, failed images, and API limits.

This order prioritizes a functioning reader before investment in an elaborate Home screen.

## 8. MVP Success Criteria

The MVP is successful when a new user can:

- Find a title without an account
- Open an available chapter
- Complete a reading session
- Return to the same title and resume
- Save at least one manga locally
- Understand and recover from ordinary network failures

### Primary Product Metric

Percentage of users who open a manga detail and begin a chapter.

### Supporting Metrics

- Reader completion rate
- Continue Reading usage
- Titles saved per active user
- Reader and API failure rate

## 9. Key Assumptions

- iOS is the only initial platform.
- MangaDex is the only catalog and chapter provider.
- The app is online-first.
- Library and progress are stored locally.
- Vertical scrolling is acceptable as the first reader mode.
- One preferred language is selected by default.
- The app does not host or redistribute manga content.
- The product prioritizes reading reliability over visual or feature completeness.
