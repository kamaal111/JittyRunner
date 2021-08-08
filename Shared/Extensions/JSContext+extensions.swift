//
//  JSContext+extensions.swift
//  JittyRunner
//
//  Created by Kamaal M Farah on 08/08/2021.
//

import JavaScriptCore
import JSConsole
import JSTimer

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

    subscript(key: String) -> Any {
        get {
            self.objectForKeyedSubscript(key) as Any
        }
        set {
            self.setObject(newValue, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
        }
    }
}
