//
//  ToolbarView.swift
//  Orchestra
//
//  Created by Dawid Dziurdzia on 23/01/2024.
//

import SwiftUI
import SwiftMPDClient

@Observable
@MainActor
final class ToolbarViewModel {
    private let client: MPDClient
    let playStatus: MPDPlayStatus
    
    var currentSongTitle: String {
        "\(playStatus.currentSong?.artist ?? "") - \(playStatus.currentSong?.title ?? "")"
    }
    
    var elapsedTimeString: String {
        playStatus.elapsedTime.orchestraFormattedTime
    }
    
    var totalTimeString: String {
        playStatus.totalTime.orchestraFormattedTime
    }
    
    var elapsedTime: TimeInterval {
        playStatus.elapsedTime
    }
    
    var totalTime: TimeInterval {
        playStatus.totalTime
    }
    
    init(client: MPDClient, playStatus: MPDPlayStatus) {
        self.client = client
        self.playStatus = playStatus
    }
    
    func previous() {
        client.previous()
    }
    
    func next() {
        client.next()
    }
    
    func play() {
        client.play()
    }
    
    func pause() {
        client.pause()
    }
    
    func random() {
        client.random(!playStatus.shuffle)
    }
    
    func `repeat`() {
        client.repeat(!playStatus.repeat)
    }
    
    func seek(position: TimeInterval) {
        client.seek(position: position)
    }
    
    var repeatImageName: String {
        (playStatus.repeat) ? "repeat.circle.fill" : "repeat.circle"
    }

    var shuffleImageName: String {
        (playStatus.shuffle) ? "shuffle.circle.fill" : "shuffle.circle"
    }
}

struct ToolbarView: View {
    let vm: ToolbarViewModel
    @State var progress: TimeInterval = 0
    @State var moreIsVisible = false
    @State var seekingDown = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {}.toolbar {
            ToolbarItemGroup(placement: .status) {
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(vm.currentSongTitle)
                            .truncationMode(.middle)
                    }
                    HStack {
                        Text(vm.elapsedTimeString)
                        Slider(value: $progress, in: 0 ... vm.totalTime) { begins in
                            seekingDown = begins
                        }
                        .onChange(of: progress) { oldValue, newValue in
                            if seekingDown && abs(oldValue - newValue) > 3 {
                                vm.seek(position: progress)
                            }
                        }
//                        .accentColor(.blue)
//                        .foregroundColor(.green)
//                        .tint(.red)
                        .onChange(of: vm.elapsedTime) { _, newValue in
                            progress = newValue
                        }
                        Text(vm.totalTimeString)
                    }
                }
                .padding([.leading, .trailing], 8)
                .background(.white.opacity(colorScheme == .dark ? 0.1 : 0.75))
                .cornerRadius(6)
                .frame(minWidth: 300, maxWidth: 600)
            }
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { vm.previous() }, label: {
                    Image(systemName: "backward")
                })
                Button(action: { vm.play() }, label: {
                    Image(systemName: "play")
                })
                Button(action: { vm.pause() }, label: {
                    Image(systemName: "pause")
                })
                Button(action: { vm.next() }, label: {
                    Image(systemName: "forward")
                })
                Spacer()
                Button(action: { vm.repeat() }, label: {
                    Image(systemName: "repeat")
                        .foregroundColor((vm.playStatus.repeat) ? .cyan : .secondary)
                })
                Button(action: { vm.random() }, label: {
                    Image(systemName: "shuffle")
                        .foregroundColor((vm.playStatus.shuffle) ? .cyan : .secondary)
                })
                Button(action: { moreIsVisible.toggle() }, label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor((vm.playStatus.shuffle) ? .cyan : .secondary)
                })
                .popover(isPresented: $moreIsVisible, content: {
                    VStack {
                        HStack {
                            Text("Crossfade")
                        }
                        
                        Text("Test")
                        Text("Test")
                        Text("Test")
                        Text("Test")
                        Text("Test")
                    }
                    .padding()
                })
            }
        }
    }
}
