<img src="assets/icon.svg" width="64" height="64" alt="">

# musik

Created in [T3 Code](https://t3.codes).

An Apple Music client. The desktop app is built with Electron, React and MusicKit JS. Everything except the views is platform-free, so a mobile app can reuse it.

## Features

By default, only the current song's artwork and playback controls are shown (shuffle, previous, play/pause, next, repeat, scrubber). Song search opens in a centered floating panel over the player.

- **⌘F** opens and focuses search; **↑/↓** pick a result, **Return** plays it (the results become the queue), **Esc** or a click outside the panel closes it. Search is also available from **File › Search Songs**.
- The Controls menu has play/pause (⌘P), next/previous (⌘→/⌘←), shuffle (⌥⌘S) and repeat (⌥⌘R).
- On macOS, closing the window keeps the music playing; the Dock icon brings it back.

## Setup

MusicKit JS needs a developer token. The app signs one at launch with a MusicKit key from your Apple Developer account:

1. In [Identifiers](https://developer.apple.com/account/resources/identifiers/list), register a **Media ID** (e.g. `media.zip.barth.musik`) with MusicKit enabled.
2. In [Keys](https://developer.apple.com/account/resources/authkeys/list), create a key with **Media Services (MusicKit, ShazamKit, Apple Music Feed)** for that Media ID. Download the `.p8` file (you only get one chance) and note the **Key ID**. Your **Team ID** is in the top right of the portal.
3. Copy `apps/desktop/.env.example` to `apps/desktop/.env.local` and fill it in. Keep the `.p8` outside the repo.
4. `bun install`, then `bun run dev`.

Click **Continue with Apple Music** and sign in with an Apple Account that has an Apple Music subscription. Without a subscription, MusicKit plays 30-second previews.

## Development

```sh
bun run dev        # the Electron app; the page hot-reloads, and main/preload changes restart it
bun test           # unit tests
bun run typecheck
```

The menu's **View** item (in development only) has Reload and Developer Tools.

## Project structure

A bun workspace. Workspace packages are consumed as TypeScript source, with no build step.

| Folder | What goes there |
| --- | --- |
| `packages/core` | Platform-free TypeScript: the `Song` and state types, the `MusicEngine` interface, `Player` (Music.app behavior, like previous restarting a song that's more than 3 s in, and which errors to show), and React hooks (`usePlayerState`, `usePlaybackTime`, `useSongSearch`) that work in React DOM and React Native alike. |
| `packages/musickit-web` | The `MusicEngine` for browsers and Electron, on MusicKit JS v3 (loaded from Apple's CDN, which Apple requires). |
| `apps/desktop/src/main` | Electron main process: the window, the app menu, Widevine setup, signing the developer token. |
| `apps/desktop/src/preload` | The `window.musik` bridge between the page and the main process. |
| `apps/desktop/src/renderer` | The React views, built from [shadcn/ui](https://ui.shadcn.com) components (`src/components/ui`, preset `bbVJxce` on Base UI) and Tailwind CSS. |

Views go through `Player` only, and only an engine talks to MusicKit.

**A mobile app** would be `apps/mobile` (Expo / React Native) with its own views, plus a `MusicEngine` on native MusicKit: on iOS an Expo module around `ApplicationMusicPlayer`, on Android Apple's MusicKit for Android SDK. `@musik/core` is reused as is.

**DRM:** in Chromium, Apple Music streams are Widevine-encrypted, and stock Electron has no Widevine. So the `electron` dependency is [castLabs' Electron for Content Security](https://github.com/castlabs/electron-releases), which downloads the Widevine CDM on first launch. Its builds are VMP-signed for development. A distributed build needs production VMP signing through castLabs' free EVS service, and must load the page from an http(s) origin rather than `file://` for MusicKit sign-in to work.

## Native macOS app

The earlier SwiftUI version is still in `Musik/` and `Musik.xcodeproj`. To run it, enable MusicKit for the App ID `zip.barth.musik` in the [Apple Developer portal](https://developer.apple.com/account/resources/identifiers/list), then open the project in Xcode, or run `./scripts/dev.sh` to rebuild and relaunch it on every change.
