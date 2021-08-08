//
//  JSTimer.swift
//  
//
//  Created by Kamaal M Farah on 08/08/2021.
//

import JavaScriptCore

@objc
public protocol JSTimerExport: JSExport {
    func setTimeout(_ callback: JSValue, _ ms: Double) -> String

    func clearTimeout(_ identifier: String)

    func setInterval(_ callback: JSValue, _ ms: Double) -> String
}

@objc
public  class JSTimer: NSObject, JSTimerExport {
    override private init() { }

    public static let shared = JSTimer()
    public static let overrideScript =
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

    public func clearTimeout(_ identifier: String) {
        let timer = timers.removeValue(forKey: identifier)
        timer?.invalidate()
    }

    public func setInterval(_ callback: JSValue, _ ms: Double) -> String {
        createTimer(callback: callback, ms: ms, repeats: true)
    }

    public func setTimeout(_ callback: JSValue, _ ms: Double) -> String {
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
