//
//  JittyRunnerApp.swift
//  Shared
//
//  Created by Kamaal Farah on 06/08/2021.
//

import SwiftUI

@main
struct JittyRunnerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
