//
//  WZWkScriptMessageDelegate.swift
//  WZWebViewController
//
//  Created by qiuqixiang on 2021/2/23.
//

import Foundation
import WebKit

// MARK - wkwebView 中间代理
public class WZWkScriptMessage: NSObject, WKScriptMessageHandler {
    
    /// 代理
    public weak var scriptDelegate: WKScriptMessageHandler?
    
    /// init
    public init(scriptDelegate: WKScriptMessageHandler) {
        super.init()
        self.scriptDelegate = scriptDelegate
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        scriptDelegate?.userContentController(userContentController, didReceive: message)
    }
}

/// MARK - 单例
public class WZWkProcessPool: WKProcessPool {
    
    /// 单例
    static let `default`: WZWkProcessPool = WZWkProcessPool()
}
