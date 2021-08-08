//
//  HomeScreen+ViewModel.swift
//  JittyRunner
//
//  Created by Kamaal M Farah on 08/08/2021.
//

import Foundation
import JavaScriptCore
import ShrimpExtensions

extension HomeScreen {
    final class ViewModel: ObservableObject {

        @Published var javaScriptCode: String = ""

        func runJavaSriptCode() {
            guard let context = JSContext.plus else { return }
            context.exceptionHandler = { (_: JSContext?, exception: JSValue?) in
                guard let exception = exception else { return }
                print("JS Error: \(String(describing: exception))")
            }
            let strippedCode = javaScriptCode.replaceMultipleOccurrences(of: ["“", "”"], with: "\"")
            guard let script = context.evaluateScript(strippedCode) else { return }
            if let result = script.toString() {
                print(result)
            }
        }

    }
}
