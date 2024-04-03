//
//  SidebarView.swift
//  Orchestra
//
//  Created by Dawid Dziurdzia on 23/01/2024.
//

import Combine
import SwiftMPDClient
import SwiftUI

@Observable
@MainActor
final class SidebarViewModel {
    private let client: MPDClient
    private let playStatus: MPDPlayStatus
    
    var images = [NSImage]()
    
    var connectionStatus: MPDConnectionStatus {
        client.status
    }
    
    var queue: [MPDQueueItem] {
        playStatus.queue
    }
    
    var queueLength: Int {
        playStatus.queueLength
    }
    
    var playingSongIndex: Int {
        playStatus.playingSongIndex
    }
    
    var volume: Double {
        playStatus.volume
    }
    
    var currentSongTitle: String {
        "\(playStatus.currentSong?.artist ?? "") - \(playStatus.currentSong?.title ?? "")"
    }
    
    init(client: MPDClient, playStatus: MPDPlayStatus) {
        self.client = client
        self.playStatus = playStatus
    }
    
    func play(position: Int) {
        client.play(position: position)
    }
    
    func setVolume(_ volume: Int) {
        client.setVolume(volume: volume)
    }
    
    func connect() {
        client.connect()
    }
    
    func disconnect() {
        client.disconnect()
    }
    
    func clear() {
        client.clearQueue()
    }
    
    func removeItems(start: Int, end: Int? = nil) {
        client.removeFromQueue(start: start, end: end)
    }
    
    func refresh() {
        Task {
            try? await client.refresh()
        }
    }
}

struct SidebarView: View {
    let vm: SidebarViewModel
    let fetcher: MPDBinaryFetcher
    @State var selectedQueueItem = Set<MPDQueueItem.ID>()
    @State var volume = 0.0
    @State var volumeDown = false
    @State var albumArt: NSImage?
    
    var body: some View {
        VStack {
            switch vm.connectionStatus {
            case .connected:
                List(vm.queue, selection: $selectedQueueItem) { item in
                    HStack {
                        if vm.images.count > item.id {
                            Image(nsImage: vm.images[item.id])
                        }
                        if item.id == vm.playingSongIndex {
                            Image(systemName: "play")
                        }
                        Text(item.song.title)
                    }
                }
                .onDeleteCommand(perform: {
                    // TODO: ranges and move to VM
                    guard let firstSong = vm.queue.filter({ $0.id == selectedQueueItem.first }).first,
                          let firstSongIndex = vm.queue.firstIndex(of: firstSong)
                    else {
                        return
                    }
                    vm.removeItems(start: firstSongIndex)
                })
                .contextMenu(forSelectionType: MPDQueueItem.ID.self) { items in
                    Button("Delete") {
                        // TODO: ranges and move to VM
                        guard let first = items.first,
                              let firstSong = vm.queue.filter({ $0.id == first }).first,
                              let firstSongIndex = vm.queue.firstIndex(of: firstSong)
                        else {
                            return
                        }
                        vm.removeItems(start: firstSongIndex)
                    }.keyboardShortcut(.delete, modifiers: [])
                } primaryAction: { items in
                    if let pos = items.sorted().first {
                        vm.play(position: pos)
                    }
                }
                HStack {
                    Text("Volume")
                    Text(String(vm.volume))
                    Slider(value: $volume, in: 0 ... 100) { begins in
//                        if !begins {
//                            vm.setVolume(Int(volume))
//                        }
                        volumeDown = begins
                    }
                    .onChange(of: volume) { _, _ in
                        if volumeDown {
                            vm.setVolume(Int(volume))
                        }
                    }
                    .onChange(of: vm.volume) { _, newValue in
                        volume = newValue
                    }
                }
                HStack {
                    Text("Queue length")
                    Text(String(vm.queueLength))
                }
                Text(vm.currentSongTitle).truncationMode(.middle).lineLimit(1)
                Image(nsImage: albumArt ?? NSImage())
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .onChange(of: vm.queue) {
                        Task {
                            guard let q = vm.queue.first else {
                                albumArt = NSImage()
                                return
                            }
                            if
                                let data = try? await fetcher.fetchAlbumArt(path: q.song.uri),
                                let image = NSImage(data: data)
                            {
                                albumArt = image
                            }
                        }
                    }
                
            case .disconnected:
                HStack {}
            case .connecting:
                HStack {}
            }
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { vm.clear() }, label: {
                    Image(systemName: "clear")
                }).help("Clear playlist")
                
                switch vm.connectionStatus {
                case .connected:
                    Button(action: { vm.disconnect() }, label: {
                        Text("Disconnect")
                    })
                case .disconnected:
                    Button(action: { vm.connect() }, label: {
                        Text("Connect")
                    })
                case .connecting:
                    Button(action: {}, label: {
                        HStack {
                            ProgressView()
                            Text("Connecting...")
                        }
                    })
                }
            }
        }
    }
}
