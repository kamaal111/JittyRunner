//
//  JSConsole.swift
//  
//
//  Created by Kamaal M Farah on 08/08/2021.
//

import JavaScriptCore

@objc
public protocol JSConsoleExports: JSExport {
    static func log(_ msg: String)
}

public class JSConsole: NSObject, JSConsoleExports {
    public static func log(_ msg: String) {
        print(msg)
    }
}
