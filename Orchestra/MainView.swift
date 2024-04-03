//
//  ContentView.swift
//  Orchestra
//
//  Created by Dawid Dziurdzia on 18/01/2024.
//

import Combine
import SwiftMPDClient
import SwiftUI

extension TimeInterval {
    var orchestraFormattedTime: String {
        let frmt = DateComponentsFormatter()
        frmt.zeroFormattingBehavior = .pad
        frmt.unitsStyle = .positional
        if self >= 3600 {
            frmt.allowedUnits = [.second, .minute, .hour]
        } else {
            frmt.allowedUnits = [.second, .minute]
        }

        return frmt.string(from: self)!
    }
}

struct MainView: View {
    var client: MPDClient
    var playStatus: MPDPlayStatus
    var libraryManger: MPDLibraryManager
    var fetcher: MPDBinaryFetcher

    var body: some View {
        NavigationSplitView {
            SidebarView(vm: SidebarViewModel(client: client, playStatus: playStatus), fetcher: fetcher)
        } detail: {
            LibraryView(vm: LibraryViewModel(libraryManager: libraryManger, client: client))
        }
        .inspector(isPresented: .constant(true)) {
            Text("Inspector View")
        }
        .toolbar {
            ToolbarView(vm: ToolbarViewModel(client: client, playStatus: playStatus))
        }
    }
}

// #Preview {
//    MainView(client: MPDClient())
// }
