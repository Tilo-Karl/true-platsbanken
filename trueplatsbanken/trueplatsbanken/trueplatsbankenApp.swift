//
//  trueplatsbankenApp.swift
//  trueplatsbanken
//
//  Created by Tilo Delau on 2026-01-11.
//

import SwiftUI

@main
struct trueplatsbankenApp: App {
    @StateObject private var languageStore = AppLanguageStore()
    @StateObject private var appState = AppStateViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .environmentObject(languageStore)
                .environment(\.locale, languageStore.locale)
        }
    }
}
