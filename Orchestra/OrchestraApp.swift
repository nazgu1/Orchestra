//
//  OrchestraApp.swift
//  Orchestra
//
//  Created by Dawid Dziurdzia on 18/01/2024.
//

import SwiftMPDClient
import SwiftUI

@MainActor
enum CompositionRoot {
    static let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    static let client = MPDClient(connection: MPDConnection(host: "10.10.1.6", port: 6600))
    static let playStatus = MPDPlayStatus(client: CompositionRoot.client)
    static let libraryManager = MPDLibraryManager(client: CompositionRoot.client)
    static let albumArtFetcher = MPDBinaryFetcher(connection: MPDConnection(host: "127.0.0.1", port: 6600))

    static func mainView() -> some View {
        MainView(
            client: CompositionRoot.client,
            playStatus: CompositionRoot.playStatus,
            libraryManger: CompositionRoot.libraryManager,
            fetcher: CompositionRoot.albumArtFetcher
        ).onReceive(timer, perform: { _ in
                Task {
                try? await client.refresh()
            }

        })
    }
}

@main
struct OrchestraApp: App {
    @State var pickerChoice: String = "dark"

    var body: some Scene {
        @State var currentNumber = "1"
        WindowGroup {
            CompositionRoot.mainView()
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            CommandGroup(after: .newItem, addition: {
                Button(action: {
                    print("Connect…")
                }, label: {
                    Text("Connect…")
                }).keyboardShortcut(.init("C"), modifiers: [.command, .option])
            })
            CommandMenu("Library") {
                Button(action: {
                    print("Menu Button selected")
                }, label: {
                    Text("Refresh library")
                }).keyboardShortcut(.init("L"), modifiers: [.command, .option])
            }
        }
        MenuBarExtra(currentNumber, systemImage: "play.circle", isInserted: .constant(true)) {
            SidebarView(vm: SidebarViewModel(
                client: CompositionRoot.client,
                playStatus: CompositionRoot.playStatus
            ), fetcher: CompositionRoot.albumArtFetcher)
        }
        // .menuBarExtraStyle(WindowMenuBarExtraStyle())
        .menuBarExtraStyle(.window)
    }
}
