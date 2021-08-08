//
//  ContentView.swift
//  Shared
//
//  Created by Kamaal Farah on 06/08/2021.
//

import SwiftUI
import JavaScriptCore
import ShrimpExtensions

struct ContentView: View {
    @StateObject
    private var viewModel = ViewModel()

    var body: some View {
        VStack {
            TextEditor(text: $viewModel.javaScriptCode)
            Button(action: viewModel.runJavaSriptCode) {
                Text("Run")
            }
        }
        .frame(minWidth: 305, minHeight: 305)
    }
}

extension ContentView {
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

extension JSContext {
    subscript(key: String) -> Any {
        get {
            self.objectForKeyedSubscript(key) as Any
        }
        set {
            self.setObject(newValue, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
        }
    }
}

@objc
protocol JSConsoleExports: JSExport {
    static func log(_ msg: String)
}

class JSConsole: NSObject, JSConsoleExports {
    static func log(_ msg: String) {
        print(msg)
    }
}

extension JSContext {
    static var plus: JSContext? {
        let jsMachine = JSVirtualMachine()
        guard let jsContext = JSContext(virtualMachine: jsMachine) else {
            return nil
        }

        jsContext.evaluateScript("""
            Error.prototype.isError = () => {return true}
        """)

        jsContext["console"] = JSConsole.self
        jsContext["timerJS"] = JSTimer.shared

        jsContext.evaluateScript(JSTimer.overrideScript)

        return jsContext
    }
}

@objc
protocol JSTimerExport: JSExport {
    func setTimeout(_ callback: JSValue, _ ms: Double) -> String

    func clearTimeout(_ identifier: String)

    func setInterval(_ callback: JSValue, _ ms: Double) -> String
}

// Custom class must inherit from `NSObject`
@objc
class JSTimer: NSObject, JSTimerExport {
    override private init() { }

    static let shared = JSTimer()
    static let overrideScript =
        "function setTimeout(callback, ms) {" +
        "    return timerJS.setTimeout(callback, ms)" +
        "}" +
        "function clearTimeout(indentifier) {" +
        "    timerJS.clearTimeout(indentifier)" +
        "}" +
        "function setInterval(callback, ms) {" +
        "    return timerJS.setInterval(callback, ms)" +
        "}"

    private var timers = [String: Timer]()

    func clearTimeout(_ identifier: String) {
        let timer = timers.removeValue(forKey: identifier)
        timer?.invalidate()
    }

    func setInterval(_ callback: JSValue, _ ms: Double) -> String {
        createTimer(callback: callback, ms: ms, repeats: true)
    }

    func setTimeout(_ callback: JSValue, _ ms: Double) -> String {
        createTimer(callback: callback, ms: ms, repeats: false)
    }

    private func createTimer(callback: JSValue, ms: Double, repeats: Bool) -> String {
        let timeInterval  = ms / 1000

        let uuid = UUID().uuidString

        // make sure that we are queueing it all in the same executable queue...
        // JS calls are getting lost if the queue is not specified... that's what we believe... ;)
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                             target: self,
                                             selector: #selector(self.callJsCallback),
                                             userInfo: callback,
                                             repeats: repeats)
            self.timers[uuid] = timer
        })

        return uuid
    }

    @objc
    private func callJsCallback(timer: Timer) {
        let callback = (timer.userInfo as? JSValue)
        callback?.call(withArguments: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
