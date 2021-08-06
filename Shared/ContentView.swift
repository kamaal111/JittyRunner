//
//  ContentView.swift
//  Shared
//
//  Created by Kamaal Farah on 06/08/2021.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello World")
        }
        .frame(minWidth: 305, minHeight: 305)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
