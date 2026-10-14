import Combine
import Foundation
import MusicKit
import Observation

/// The single owner of `ApplicationMusicPlayer.shared`. Views read the
/// mirrored state below and call the methods; nothing else touches the player.
@MainActor
@Observable
final class PlayerModel {
    private(set) var currentEntry: ApplicationMusicPlayer.Queue.Entry?
    private(set) var playbackStatus: MusicPlayer.PlaybackStatus = .stopped
    private(set) var shuffleMode: MusicPlayer.ShuffleMode = .off
    private(set) var repeatMode: MusicPlayer.RepeatMode = .none

    /// The most recent playback error, shown by the root view in one alert.
    var errorMessage: String?

    @ObservationIgnored private let player = ApplicationMusicPlayer.shared
    @ObservationIgnored private var stateObserver: AnyCancellable?
    @ObservationIgnored private var queueObserver: AnyCancellable?

    init() {
        stateObserver = observe(player.state.objectWillChange)
        observeQueue()
        sync()
    }

    // MARK: - Derived state

    var isPlaying: Bool { playbackStatus == .playing }
    var hasQueue: Bool { currentEntry != nil }
    var isShuffled: Bool { shuffleMode == .songs }

    /// Duration of the current entry, when the underlying item provides one.
    var currentDuration: TimeInterval? {
        switch currentEntry?.item {
        case .song(let song): song.duration
        case .musicVideo(let video): video.duration
        case nil: nil
        @unknown default: nil
        }
    }

    /// Not observable (the player doesn't publish it); poll it while playing.
    var playbackTime: TimeInterval { player.playbackTime }

    /// Whether `item` is what's currently loaded in the player.
    func isCurrent(_ item: some MusicItem) -> Bool {
        currentEntry?.item?.id == item.id
    }

    /// Playlist entries have their own IDs; the queue holds the entry's song or
    /// video, so match on that (and on the entry ID in case they coincide).
    func isCurrent(_ entry: Playlist.Entry) -> Bool {
        guard let id = currentEntry?.item?.id else { return false }
        return id == entry.item?.id || id == entry.id
    }

    // MARK: - Starting playback
    //
    // Like Music.app: playing something from the top plays it in order
    // (shuffle off), starting at a chosen song keeps the current shuffle mode,
    // and `shuffle` turns shuffle on.

    /// Plays a list of items (e.g. songs) from the top, in order.
    func play<S: Sequence>(_ items: S) where S.Element: PlayableMusicItem {
        let items = Array(items.prefix(Self.maxQueueLength))
        guard !items.isEmpty else { return }
        start(ApplicationMusicPlayer.Queue(for: items), shuffle: .off)
    }

    /// Queues a list of items so next/previous move through it, starting at
    /// `first`, keeping the shuffle mode. Long lists are queued around `first`.
    func play<S: Sequence>(_ items: S, startingAt first: S.Element) where S.Element: PlayableMusicItem {
        let items = Self.queueWindow(Array(items), around: first)
        guard !items.isEmpty else { return }
        start(ApplicationMusicPlayer.Queue(for: items, startingAt: first), shuffle: nil)
    }

    /// Plays a single item (album, playlist, station, song) from the top, in order.
    func play(_ item: some PlayableMusicItem) {
        start(ApplicationMusicPlayer.Queue(for: [item]), shuffle: .off)
    }

    /// Plays an album starting at one of its tracks, keeping the shuffle mode.
    func play(_ album: Album, startingAt track: Track) {
        start(ApplicationMusicPlayer.Queue(album: album, startingAt: track), shuffle: nil)
    }

    /// Plays a playlist starting at one of its entries, keeping the shuffle mode.
    func play(_ playlist: Playlist, startingAt entry: Playlist.Entry) {
        start(ApplicationMusicPlayer.Queue(playlist: playlist, startingAt: entry), shuffle: nil)
    }

    /// Plays an album, playlist, etc. in shuffled order.
    func shuffle(_ item: some PlayableMusicItem) {
        start(ApplicationMusicPlayer.Queue(for: [item]), shuffle: .songs)
    }

    /// Plays a list of items in shuffled order; long lists are sampled at random.
    func shuffle<S: Sequence>(_ items: S) where S.Element: PlayableMusicItem {
        var items = Array(items)
        if items.count > Self.maxQueueLength {
            items = Array(items.shuffled().prefix(Self.maxQueueLength))
        }
        guard !items.isEmpty else { return }
        start(ApplicationMusicPlayer.Queue(for: items), shuffle: .songs)
    }

    // MARK: - Transport

    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else if hasQueue {
            perform { try await self.player.play() }
        }
    }

    /// Skipping past either end of the queue may throw; that's not worth an alert.
    func skipToNext() {
        let isLast = player.queue.entries.last?.id == player.queue.currentEntry?.id
        perform(alertOnError: !isLast) { try await self.player.skipToNextEntry() }
    }

    /// Like Music.app: restarts the current track if it's more than 3 s in.
    func skipToPrevious() {
        if player.playbackTime > 3 {
            player.restartCurrentEntry()
        } else {
            let isFirst = player.queue.entries.first?.id == player.queue.currentEntry?.id
            perform(alertOnError: !isFirst) { try await self.player.skipToPreviousEntry() }
        }
    }

    func seek(to time: TimeInterval) {
        player.playbackTime = max(0, time)
    }

    // MARK: - Modes

    func setShuffleMode(_ mode: MusicPlayer.ShuffleMode) {
        player.state.shuffleMode = mode
        sync()
    }

    func toggleShuffle() {
        setShuffleMode(isShuffled ? .off : .songs)
    }

    func setRepeatMode(_ mode: MusicPlayer.RepeatMode) {
        player.state.repeatMode = mode
        sync()
    }

    /// Cycles none → all → one → none.
    func cycleRepeatMode() {
        switch repeatMode {
        case .none: setRepeatMode(.all)
        case .all: setRepeatMode(.one)
        default: setRepeatMode(.none)
        }
    }

    // MARK: - Private

    /// Queueing a whole 25k-song library is slow and pointless, so lists are
    /// capped to a window of this many items.
    private static let maxQueueLength = 500

    /// Up to `maxQueueLength` items around `first`: up to 100 before it so
    /// "previous" works, the rest after it.
    private static func queueWindow<Item: MusicItem>(_ items: [Item], around first: Item) -> ArraySlice<Item> {
        guard items.count > maxQueueLength else { return items[...] }
        let index = items.firstIndex { $0.id == first.id } ?? 0
        let end = min(items.count, max(0, index - 100) + maxQueueLength)
        return items[(end - maxQueueLength)..<end]
    }

    private func start(_ queue: ApplicationMusicPlayer.Queue, shuffle: MusicPlayer.ShuffleMode?) {
        player.queue = queue
        // Setting the queue may replace the observed queue object.
        observeQueue()
        if let shuffle { setShuffleMode(shuffle) }
        perform { try await self.player.play() }
    }

    private func perform(alertOnError: Bool = true, _ operation: @escaping () async throws -> Void) {
        Task {
            do {
                try await operation()
            } catch {
                if alertOnError { errorMessage = error.localizedDescription }
            }
            sync()
        }
    }

    private func observeQueue() {
        queueObserver = observe(player.queue.objectWillChange)
    }

    /// `objectWillChange` fires before the new values are set, so read them
    /// on the next main-queue turn.
    private func observe(_ publisher: AnyPublisher<Void, Never>) -> AnyCancellable {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync() }
    }

    private func sync() {
        let state = player.state
        update(\.currentEntry, to: player.queue.currentEntry)
        update(\.playbackStatus, to: state.playbackStatus)
        update(\.shuffleMode, to: state.shuffleMode ?? .off)
        update(\.repeatMode, to: state.repeatMode ?? .none)
    }

    /// Only assigns on change, so observers aren't invalidated needlessly.
    private func update<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<PlayerModel, Value>, to value: Value) {
        if self[keyPath: keyPath] != value {
            self[keyPath: keyPath] = value
        }
    }
}
