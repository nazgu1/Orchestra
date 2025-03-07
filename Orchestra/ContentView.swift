//
//  ContentView.swift
//  Orchestra
//
//  Created by Dawid Dziurdzia on 06/02/2025.
//
import SwiftUI

struct ContentView: View {
    @State var recentHeartRate: Double = 100
    let maxHeartRate: Double = 200
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.blue.mix(with: .red, by: recentHeartRate / maxHeartRate))
            .animation(.bouncy, value: recentHeartRate / maxHeartRate)
            .frame(height: 80)
            .padding(50)
            .overlay {
                            Slider(value: $recentHeartRate, in: 50...200)
                        }
    }
}

#Preview {
    ContentView()
}
