//
//  HomeScreen.swift
//  JittyRunner
//
//  Created by Kamaal M Farah on 08/08/2021.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject
    private var viewModel = ViewModel()

    var body: some View {
        #if os(macOS)
        view
            .frame(minWidth: 305, minHeight: 305)
        #else
        view
        #endif
    }

    private var view: some View  {
        VStack {
            TextEditor(text: $viewModel.javaScriptCode)
            Button(action: viewModel.runJavaSriptCode) {
                Text("Run")
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
