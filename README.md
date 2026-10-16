<img src="assets/icon.svg" width="64" height="64" alt="">

# musik

Created in [T3 Code](https://t3.codes).

A native macOS Apple Music client built with SwiftUI and MusicKit.

## Features

One page: the current song's artwork with playback controls (shuffle, previous, play/pause, next, repeat, scrubber), and a song search below it.

- **⌘N** focuses the search; **↑/↓** pick a result, **Return** plays it (the results become the queue), **Esc** closes the search.
- The Controls menu has play/pause (⌘P), next/previous (⌘→/⌘←), shuffle and repeat.

## Setup

1. In the [Apple Developer portal](https://developer.apple.com/account/resources/identifiers/list), open the App ID `zip.barth.musik` (register it if missing), go to **App Services**, and enable **MusicKit**. MusicKit can't issue a developer token until you do.
2. Open `Musik.xcodeproj` in Xcode and run (⌘R).

Playback needs an active Apple Music subscription on the Apple Account that's signed in to the Music app.

### Live reloading

```sh
./scripts/dev.sh
```

Builds and launches the app, then rebuilds and relaunches it whenever a file in `Musik/` changes (incremental builds take a second or two). If a build fails, the error prints and the previous build keeps running. The app's `print` output shows in the terminal. Ctrl-C quits the script and the app.

For single views, the `#Preview` canvas in Xcode (⌥⌘↩) updates as you type.

## Project structure

`Musik/` is a file-system-synchronized group: new `.swift` files in it are compiled automatically, no project file edits needed.

| Folder | What goes there |
| --- | --- |
| `App/` | App entry point, authorization gate and menu commands. |
| `Home/` | `HomeView`, the app's page. |
| `Player/` | `PlayerModel`, the only code that talks to `ApplicationMusicPlayer`, plus the now playing view and the Controls menu. |
| `Search/` | The song search field and results. |
| `Views/Components/` | Small reusable views: artwork, track rows. |

Views start playback only through `PlayerModel`.
