//
//  LibraryView.swift
//  Orchestra
//
//  Created by Dawid Dziurdzia on 23/01/2024.
//

import Foundation
import SwiftMPDClient
import SwiftUI

@Observable
@MainActor
final class LibraryViewModel {
    var libraryManager: MPDLibraryManager
    var client: MPDClient

    init(libraryManager: MPDLibraryManager, client: MPDClient) {
        self.libraryManager = libraryManager
        self.client = client
    }

    var songs: [MPDSong] {
        libraryManager.songs
    }

    func addToQueue(uri: String) {
        client.addToQueue(uri: uri)
    }

    func addToQueue(uris: [String]) {
        client.addToQueue(uris: uris)
    }

    func sort(using sc: KeyPathComparator<MPDSong>) {
        libraryManager.sort(using: sc)
    }
}

struct LibraryView: View {
    @State var order: [KeyPathComparator<MPDSong>] = [.init(\.artist, order: .forward)]
    @State var selectedSong = Set<MPDSong.ID>()
    let vm: LibraryViewModel
    @State private var columnCustomization: TableColumnCustomization<MPDSong> = .init()

    var body: some View {
        Table(vm.songs, selection: $selectedSong, sortOrder: $order, columnCustomization: $columnCustomization) {
            TableColumn("Artist", value: \.artist).customizationID("Artist")
            TableColumn("Album", value: \.album).customizationID("Album")
            TableColumn("Title", value: \.title).customizationID("Title")
        }
        .onChange(of: order) { _, newOrder in
            withAnimation {
                vm.sort(using: newOrder.first!)
            }
        }
        .contextMenu(forSelectionType: MPDSong.ID.self) { items in
            if items.isEmpty {
                Button("New Item") {}

            } else if items.count == 1 {
                Button("Copy") {}
                Button("Delete", role: .destructive) {}

            } else {
                Button("Copy") {}
                Button("New Folder With Selection") {}
                Button("Delete Selected", role: .destructive) {}
            }
        } primaryAction: { items in
            vm.addToQueue(uris: vm.songs.filter { items.contains($0.id) }.map { $0.uri })
        }
    }
}
