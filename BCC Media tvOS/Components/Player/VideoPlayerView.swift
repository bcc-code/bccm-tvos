//
//  VideoPlayer.swift
//  BCC Live
//
//  Created by Fredrik Vedvik on 19/12/2023.
//

import SwiftUI
import AVKit
import NpawPlugin

struct PlaybackState {
    var time: Double
}

extension NpawPluginProvider {
    static func setup() {
        let options = AnalyticsOptions()
        options.appName = "bccm-tvos"
        options.userAnonymousId = AppOptions.user.anonymousId
        options.contentCustomDimension1 = Events.sessionId?.stringValue
        options.contentCustomDimension2 = AppOptions.user.ageGroup
        self.initialize(accountCode: AppOptions.npaw.accountCode ?? "", analyticsOptions: options, logLevel: .info)
    }
}

class PlayerControls: ObservableObject {
    var player = AVPlayer()
    var currentUrl: URL?
    
    var adapter: NpawPlugin.VideoAdapter?
    
    var loading = false
    
    var playing = false
    
    private var listener: PlayerListener?
    
    var observers: [NSKeyValueObservation] = []
    
    var expiresAt: Date?

    var timer: Timer?
    
    init(player: AVPlayer = AVPlayer()) {
        self.player = player
        
        observers = [
            player.observe(\.status, options: [.new]) { item, change in
                self.loading = item.status != .readyToPlay
            },
            player.observe(\.timeControlStatus, options: [.new]) { item, change in
                self.playing = item.timeControlStatus != .playing
            },
        ]
    }
    
    func setUrl(url: URL) {
        if url != currentUrl {
            currentUrl = url
            if NpawPluginProvider.shared?.accountCode != "" {
                adapter?.destroy()

                let videoOptions = VideoOptions()
                
                videoOptions.contentResource = url.absoluteString
                videoOptions.contentTitle = "Live"
                videoOptions.live = true
                
                adapter = NpawPluginProvider.shared!.videoBuilder()
                    .setPlayerAdapter(playerAdapter: AVPlayerAdapter(player: player))
                    .setOptions(options: videoOptions)
                    .setIdentifier(identifier: "bccm-tvos")
                    .build()
            }
            
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            player.isMuted = true
        }
    }
    
    static func setItem(_ videoURL: URL, _ options: PlayerOptions = .init(), _ listener: PlayerListener = PlayerListener { _ in }) {
        current.player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
        current.player.currentItem?.externalMetadata = createMetadataItems(options)
        if NpawPluginProvider.shared?.accountCode != "" {
            current.adapter?.destroy()

            let videoOptions = VideoOptions()

            let c = options.content
            videoOptions.contentId = c.id
            videoOptions.live = options.isLive
            videoOptions.contentTitle = options.title
            videoOptions.contentTvShow = c.showId
            videoOptions.contentSeason = c.seasonId != nil && c.seasonTitle != nil ? "\(c.seasonId!) - \(c.seasonTitle!)" : nil
            videoOptions.program = c.showTitle ?? options.title
            videoOptions.contentEpisodeTitle = c.episodeTitle
            
            videoOptions.contentResource = videoURL.absoluteString
            
            current.adapter = NpawPluginProvider.shared!.videoBuilder()
                .setPlayerAdapter(playerAdapter: AVPlayerAdapter(player: player))
                .setOptions(options: videoOptions)
                .build()
        }
        
        if options.startFrom != 0 {
            current.player.seek(to: CMTimeMakeWithSeconds(Double(options.startFrom), preferredTimescale: 100))
        }
        
        NotificationCenter.default.addObserver(
            listener,
            selector: #selector(listener.playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: current.player.currentItem
        )

        DispatchQueue.main.async {
            self.current.timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
                listener.stateCallback(PlaybackState(time: player.currentTime().seconds))
                if expired() {
                    listener.onExpire()
                }
            }
        }
        
        Task {
            let l = options.audioLanguage ?? "no"
            if await current.player.currentItem!.setAudioLanguage(l) {
                print("Successfully set initial audio language")
            }
        }
        Task {
            let l = options.subtitleLanguage ?? "no"
            if await current.player.currentItem!.setSubtitleLanguage(l) {
                print("Successfully set initial subtitle language")
            }
        }
        
        current.expiresAt = Calendar.current.date(byAdding: .hour, value: 5, to: .now)

        current.listener = listener
    }
    
    private static func createMetadataItem(for identifier: AVMetadataIdentifier,
                                    value: Any) -> AVMetadataItem
    {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        // Specify "und" to indicate an undefined language.
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
    
    private static func createMetadataItems(_ options: PlayerOptions) -> [AVMetadataItem] {
        let mapping: [AVMetadataIdentifier: Any] = [
            .commonIdentifierTitle: options.title as Any,
        ]

        return mapping.compactMap { createMetadataItem(for: $0, value: $1) }
    }
    
    static var current = PlayerControls()
    
    static var player: AVPlayer {
        current.player
    }
    
    static var adapter: NpawPlugin.VideoAdapter? {
        current.adapter
    }
    
    static func mute() {
        player.isMuted = true
    }
    
    static func unmute() {
        player.isMuted = false
    }
    
    static func setUrl(url: URL) {
        current.setUrl(url: url)
    }
    
    static func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        adapter?.destroy()
        current.timer?.invalidate()
    }
    
    static func expired() -> Bool {
        current.expiresAt != nil && current.expiresAt! < .now
    }
}

struct VideoPlayerControllerView: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        controller.player = PlayerControls.current.player
        
        return controller
    }
    
    func updateUIViewController(_ _: AVPlayerViewController, context _: Context) {}
}

struct VideoPlayerView : View {
    @Binding var fullscreen: Bool
    
    var body: some View {
        VideoPlayerControllerView().ignoresSafeArea()
//            .fullScreenCover(isPresented: $fullscreen) {
//                VideoPlayerControllerView().ignoresSafeArea(.all)
//            }
        .onChange(of: fullscreen) { v in
            if v {
                PlayerControls.unmute()
            } else {
                PlayerControls.mute()
            }
        }.onAppear() {
            PlayerControls.player.play()
        }.onDisappear() {
            PlayerControls.stop()
        }
    }
}
