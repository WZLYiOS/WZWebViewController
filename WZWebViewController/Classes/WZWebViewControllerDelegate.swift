//
//  WZWebViewControllerDelegate.swift
//  Created by ___ORGANIZATIONNAME___ on 2024/1/2
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2024. All rights reserved.
//  @author qiuqixiang(739140860@qq.com)   
//

import WebKit
import Foundation

/// MARK - 代理
@objc public protocol WZWebViewControllerDelegate {
    @objc optional func webViewController(_ controller: WZWebViewController, canDismiss url: URL?) -> Bool
    
    @objc optional func webViewController(_ controller: WZWebViewController, didStart url: URL?)
    @objc optional func webViewController(_ controller: WZWebViewController, didFinish url: URL?)
    @objc optional func webViewController(_ controller: WZWebViewController, didFail url: URL?, withError error: Error)
    @objc optional func webViewController(_ controller: WZWebViewController, decidePolicy url: URL?, navigationType: NavigationType) -> Bool
    @objc optional func webViewController(_ controller: WZWebViewController, didReceive message: WKScriptMessage)
    @objc optional func webViewController(_ controller: WZWebViewController, webView title: String)
}

/// MARK -  配置
open class WZWebViewDefault{

    /// 单利
    public static let appearance: WZWebViewDefault = {
        return $0
    }(WZWebViewDefault())

    /// 请求头
    public var headers: [String: String]?

    /// 单纯UserAgent
    public var pureUserAgent: String?

    /// 拼接token
    public var prefixToken: String?
}
