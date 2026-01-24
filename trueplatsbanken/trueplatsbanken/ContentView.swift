//
//  ContentView.swift
//  trueplatsbanken
//
//  Created by Tilo Delau on 2026-01-11.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppStateViewModel

    var body: some View {
        RootView(appState: appState)
    }
}

#Preview {
    ContentView(appState: AppStateViewModel())
        .environmentObject(AppLanguageStore())
}
