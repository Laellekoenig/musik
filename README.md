<img src="assets/icon.svg" width="64" height="64" alt="">

# musik

Created in [T3 Code](https://t3.codes).

A native macOS Apple Music client built with SwiftUI and MusicKit.

## Features

- **Recently Played**: your recent songs, updated live as songs play in the app.
- **Search** the Apple Music catalog for songs, albums and playlists.
- **Library**: your songs (filterable table), albums and artists, with refresh (⌘R).
- **Playlists** from your library in the sidebar, each with its full track list.
- **Playback**: a now playing bar and a Controls menu with play/pause (⌘P), next/previous (⌘→/⌘←), shuffle and repeat.

## Setup

1. In the [Apple Developer portal](https://developer.apple.com/account/resources/identifiers/list), open the App ID `zip.barth.musik` (register it if missing), go to **App Services**, and enable **MusicKit**. MusicKit can't issue a developer token until you do.
2. Open `Musik.xcodeproj` in Xcode and run (⌘R).

Playback needs an active Apple Music subscription on the Apple Account that's signed in to the Music app.

## Project structure

`Musik/` is a file-system-synchronized group: new `.swift` files in it are compiled automatically, no project file edits needed.

| Folder | What goes there |
| --- | --- |
| `App/` | App entry point, authorization gate, root layout, sidebar (`SidebarItem`) and the navigation destinations shared by every screen (`MusicDestinations`). |
| `Player/` | `PlayerModel`, the only code that talks to `ApplicationMusicPlayer`, plus the now playing bar and the Controls menu. |
| `Features/<Name>/` | One folder per sidebar section (`RecentlyPlayed`, `Search`, `Library`, `Playlists`) with its screens and loaders. |
| `Views/Components/` | Reusable views: track rows, artwork, album cards and grids, shelves, collection headers, load states, the refresh button. |

Conventions: views start playback only through `PlayerModel`; anything pushable is navigated to with `NavigationLink(value:)` and registered once in `musicDestinations()`; async loads use `LoadState` / `LoadStateView`, and long library lists use `LibraryItems`.
