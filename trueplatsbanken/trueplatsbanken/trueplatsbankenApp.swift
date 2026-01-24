//
//  trueplatsbankenApp.swift
//  trueplatsbanken
//
//  Created by Tilo Delau on 2026-01-11.
//

import SwiftUI
import Firebase

@main
struct trueplatsbankenApp: App {
    @StateObject private var appState = AppStateViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
        }
    }
}
