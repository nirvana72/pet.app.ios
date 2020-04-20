//
//  WeakScriptMessageDelegate.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/18.
//  Copyright © 2019 倪佳. All rights reserved.
//

import WebKit

///内存管理,使用delegate类防止不释放
class WeakScriptMessageDelegate: NSObject, WKScriptMessageHandler {
    weak var scriptDelegate: WKScriptMessageHandler?
    init(_ scriptDelegate: WKScriptMessageHandler) {
        self.scriptDelegate = scriptDelegate
        super.init()
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        scriptDelegate?.userContentController(userContentController, didReceive: message)
    }
    deinit {
        print("WeakScriptMessageDelegate is deinit")
    }
}
