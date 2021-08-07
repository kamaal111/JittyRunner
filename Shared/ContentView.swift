//
//  ContentView.swift
//  Shared
//
//  Created by Kamaal Farah on 06/08/2021.
//

import SwiftUI
import CoreData
import JavaScriptCore

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
            TimerJS.registerInto(jsContext: context)
            context.exceptionHandler = { (_, exception: JSValue?) in
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

extension String {
    func replaceMultipleOccurrences(of targets: [Character], with replacement: Character) -> String {
        let characters = self.map { character -> Character in
            if targets.contains(character) {
                return replacement
            }
            return character
        }
        return String(characters)
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

@objc protocol JSConsoleExports: JSExport {
    static func log(_ msg: String)
}

class JSConsole: NSObject, JSConsoleExports {
    class func log(_ msg: String) {
        print(msg)
    }
}

@objc protocol JSPromiseExports: JSExport {
    func then(_ resolve: JSValue) -> JSPromise?
    func `catch`(_ reject: JSValue) -> JSPromise?
}

class JSPromise: NSObject, JSPromiseExports {
    var resolve: JSValue?
    var reject: JSValue?
    var next: JSPromise?
    var timer: Timer?

    func then(_ resolve: JSValue) -> JSPromise? {
        self.resolve = resolve

        self.next = JSPromise()

        self.timer?.fireDate = Date(timeInterval: 1, since: Date())
        self.next?.timer = self.timer
        self.timer = nil

        return self.next
    }

    func `catch`(_ reject: JSValue) -> JSPromise? {
        self.reject = reject

        self.next = JSPromise()

        self.timer?.fireDate = Date(timeInterval: 1, since: Date())
        self.next?.timer = self.timer
        self.timer = nil

        return self.next
    }

    func fail(error: String) {
        if let reject = reject {
            reject.call(withArguments: [error])
        } else if let next = next {
            next.fail(error: error)
        }
    }

    func success(value: Any?) {
        guard let resolve = resolve else { return }
        var result: JSValue?
        if let value = value {
            result = resolve.call(withArguments: [value])
        } else {
            result = resolve.call(withArguments: [])
        }

        guard let next = next else { return }
        if let result = result {
            if result.isUndefined {
                next.success(value: nil)
                return
            }
            if result.hasProperty("isError") {
                next.fail(error: result.toString())
                return
            }
        }

        next.success(value: result)
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
        jsContext["Promise"] = JSPromise.self

        let fetch: @convention(block) (String) -> JSPromise? = { link in
            let promise = JSPromise()
            promise.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {timer in
                timer.invalidate()

                if let url = URL(string: link) {
                    URLSession.shared.dataTask(with: url) { data, _, error in
                        if let error = error {
                            promise.fail(error: error.localizedDescription)
                        } else if
                            let data = data,
                            let string = String(data: data, encoding: String.Encoding.utf8) {
                            promise.success(value: string)
                        } else {
                            promise.fail(error: "\(url) is empty")
                        }
                    }
                    .resume()
                } else {
                    promise.fail(error: "\(link) is not url")
                }
            }

            return promise
        }
        jsContext["fetch"] = unsafeBitCast(fetch, to: JSValue.self)

        return jsContext
    }
}

let timerJSSharedInstance = TimerJS()

@objc
protocol TimerJSExport: JSExport {
    func setTimeout(_ callback: JSValue, _ ms: Double) -> String

    func clearTimeout(_ identifier: String)

    func setInterval(_ callback: JSValue, _ ms: Double) -> String

}

// Custom class must inherit from `NSObject`
@objc class TimerJS: NSObject, TimerJSExport {
    var timers = [String: Timer]()

    static func registerInto(jsContext: JSContext, forKeyedSubscript: String = "timerJS") {
        jsContext.setObject(timerJSSharedInstance,
                            forKeyedSubscript: forKeyedSubscript as (NSCopying & NSObjectProtocol))
        jsContext.evaluateScript(
            "function setTimeout(callback, ms) {" +
            "    return timerJS.setTimeout(callback, ms)" +
            "}" +
            "function clearTimeout(indentifier) {" +
            "    timerJS.clearTimeout(indentifier)" +
            "}" +
            "function setInterval(callback, ms) {" +
            "    return timerJS.setInterval(callback, ms)" +
            "}"
        )
    }

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

    func createTimer(callback: JSValue, ms: Double, repeats: Bool) -> String {
        let timeInterval  = ms/1000.0

        let uuid = NSUUID().uuidString

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
    func callJsCallback(timer: Timer) {
        let callback = (timer.userInfo as? JSValue)
        callback?.call(withArguments: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
