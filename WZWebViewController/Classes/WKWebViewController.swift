//
//  WZWebViewController.swift
//  WZWebViewController
//
//  Created by xiaobin liu on 2019/10/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import WebKit


fileprivate let cookieKey = "Cookie"

fileprivate struct UrlsHandledByApp {
    public static var hosts = ["itunes.apple.com"]
    public static var schemes = ["tel", "mailto", "sms"]
    public static var blank = true
}

/// MARK - 代理
@objc public protocol WZWebViewControllerDelegate {
    @objc optional func webViewController(_ controller: WZWebViewController, canDismiss url: URL) -> Bool
    
    @objc optional func webViewController(_ controller: WZWebViewController, didStart url: URL)
    @objc optional func webViewController(_ controller: WZWebViewController, didFinish url: URL)
    @objc optional func webViewController(_ controller: WZWebViewController, didFail url: URL, withError error: Error)
    @objc optional func webViewController(_ controller: WZWebViewController, decidePolicy url: URL, navigationType: NavigationType) -> Bool
    @objc optional func webViewController(_ controller: WZWebViewController, didReceive message: WKScriptMessage)
    @objc optional func webViewController(_ controller: WZWebViewController, webView title: String)
}


/// MARK - 我主良缘浏览器控制器
open class WZWebViewController: UIViewController {
    
    /// 初始化
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    /// 初始化
    /// - Parameter source: 资源
    public init(source: WZWebSource?) {
        super.init(nibName: nil, bundle: nil)
        self.source = source
    }
    
    
    /// 初始化
    /// - Parameter url: url
    public init(url: URL) {
        super.init(nibName: nil, bundle: nil)
        self.source = .remote(url)
    }
    
    /// 资源
    open var source: WZWebSource?
    
    /// url
    open internal(set) var url: URL?
    
    /// tintColor
    open var tintColor: UIColor?
    
    /// 允许文件Url
    open var allowsFileURL = true
    
    /// 回调
    open var delegate: WZWebViewControllerDelegate?
    
    /// 绕过SSL主机
    open var bypassedSSLHosts: [String]?
    
    /// cookies
    open var cookies: [HTTPCookie]?
    
    /// 请求头
    open var headers: [String: String]?
    
    /// 单纯UserAgent
    open var pureUserAgent: String? {
        didSet {
            guard let agent = pureUserAgent else {
                return
            }
            webView.customUserAgent = agent
        }
    }
    
    /// 导航栏中的网站标题(默认为true)
    open var websiteTitleInNavigationBar = true
    
    /// 完成按钮位置(默认右边)
    open var doneBarButtonItemPosition: NavigationBarPosition = .right
    
    /// 左边导航类型
    open var leftNavigaionBarItemTypes: [BarButtonItemType] = []
    
    /// 右边导航类型
    open var rightNavigaionBarItemTypes: [BarButtonItemType] = []
    
    /// 工具栏项目类型
    open var toolbarItemTypes: [BarButtonItemType] = [.back, .forward, .reload, .activity]
    
    /// 后退按钮图标
    open var backBarButtonItemImage: UIImage?
    
    /// 向前按钮图标
    open var forwardBarButtonItemImage: UIImage?
    
    /// 加载按钮图标
    open var reloadBarButtonItemImage: UIImage?
    
    /// 停止按钮图标
    open var stopBarButtonItemImage: UIImage?
    
    /// 活动按钮图标
    open var activityBarButtonItemImage: UIImage?
    
    /// webview
    public lazy var webView: WKWebView = {
        
        let webConfiguration = WKWebViewConfiguration()
        let temWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        
        temWebView.uiDelegate = self
        temWebView.navigationDelegate = self
        temWebView.allowsBackForwardNavigationGestures = true
        temWebView.isMultipleTouchEnabled = true
        temWebView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11, *) {
            temWebView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        return temWebView
    }()
    
    /// 代理中间件
    private lazy var scriptMessageDelegate: WZWkScriptMessage = {
        return $0
    }(WZWkScriptMessage(scriptDelegate: self))
    
    /// 进度视图
    public lazy var progressView: UIProgressView = {
        let temProgressView = UIProgressView(progressViewStyle: .default)
        temProgressView.trackTintColor = UIColor(white: 1, alpha: 0)
        temProgressView.translatesAutoresizingMaskIntoConstraints = false
        return temProgressView
    }()
    
    /// 后退按钮
    fileprivate lazy var backBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: backBarButtonItemImage ?? UIImage(named: "WZWebViewController.bundle/Back"), style: .plain, target: self, action: #selector(backDidClick(sender:)))
    }()
    
    /// 向前按钮
    fileprivate lazy var forwardBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: forwardBarButtonItemImage ?? UIImage(named: "WZWebViewController.bundle/Forward"), style: .plain, target: self, action: #selector(forwardDidClick(sender:)))
    }()
    
    /// 加载按钮
    fileprivate lazy var reloadBarButtonItem: UIBarButtonItem = {
        if let image = reloadBarButtonItemImage {
            return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(reloadDidClick(sender:)))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadDidClick(sender:)))
        }
    }()
    
    /// 停止按钮
    fileprivate lazy var stopBarButtonItem: UIBarButtonItem = {
        if let image = stopBarButtonItemImage {
            return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(stopDidClick(sender:)))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(stopDidClick(sender:)))
        }
    }()
    
    /// 活动按钮
    fileprivate lazy var activityBarButtonItem: UIBarButtonItem = {
        if let image = activityBarButtonItemImage {
            return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(activityDidClick(sender:)))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(activityDidClick(sender:)))
        }
    }()
    
    /// 完成按钮
    fileprivate lazy var doneBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDidClick(sender:)))
    }()
    
    /// flexibleSpaceBarButtonItem
    fileprivate lazy var flexibleSpaceBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }()
    
    /// 进度观察
    private var estimatedProgressObservation: NSKeyValueObservation!
    
    /// 标题观察者
    public var titleObservation: NSKeyValueObservation!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        webView.configuration.suppressesIncrementalRendering = false
        configView()
        configLocation()
        addBarButtonItems()
        setupEstimatedProgressObservation()
        setupTitleObservation()
        if let s = self.source {
            self.load(source: s)
        }
        
        if let tintColor = tintColor {
            progressView.progressTintColor = tintColor
            navigationController?.navigationBar.tintColor = tintColor
            navigationController?.toolbar.tintColor = tintColor
        }
    }
    
    /// 配置视图
    func configView() {
        
        view.backgroundColor = UIColor.white
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.bottom]

        view.addSubview(webView)
        view.addSubview(progressView)
    }
    
     /// 配置位置
     open func configLocation() {
        
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 2).isActive = true
    }
    
  
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /// 注册js回调key
    open func addScriptMessageHandler(name: String){
        webView.configuration.userContentController.add(scriptMessageDelegate, name: name)
    }
    
    /// oc调用js
    open func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        webView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    /// 释放
    deinit {
        debugPrint("释放WZWebViewController")
    }
    
    /// 加载地址
    open func load(source s: WZWebSource) {
        switch s {
        case .remote(let url):
            self.load(remote: url)
        case .file(let url, access: let access):
            self.load(file: url, access: access)
        case .string(let str, base: let base):
            self.load(string: str, base: base)
        }
    }
}

/// MARK: - Public Methods
public extension WZWebViewController {
    
    private func load(remote: URL) {
        webView.load(createRequest(url: remote))
    }
    
    private func load(file: URL, access: URL) {
        webView.loadFileURL(file, allowingReadAccessTo: access)
    }
    
    private func load(string: String, base: URL? = nil) {
        webView.loadHTMLString(string, baseURL: base)
    }
    
    func goBackToFirstPage() {
        if let firstPageItem = webView.backForwardList.backList.first {
            webView.go(to: firstPageItem)
        }
    }
}

// MARK: - Fileprivate Methods
fileprivate extension WZWebViewController {
    
    /// 可用的cookies
    var availableCookies: [HTTPCookie]? {
        return cookies?.filter {
            cookie in
            var result = true
            let url = self.source?.remoteURL
            if let host = url?.host, !cookie.domain.hasSuffix(host) {
                result = false
            }
            if cookie.isSecure && url?.scheme != "https" {
                result = false
            }
            
            return result
        }
    }
    
    /// 创建Request
    func createRequest(url: URL) -> URLRequest {
        
        var request = URLRequest(url: url)
        
        // 设置头
        if let headers = headers {
            for (field, value) in headers {
                request.addValue(value, forHTTPHeaderField: field)
            }
        }
        
        // 设置cookies
        if let cookies = availableCookies, let value = HTTPCookie.requestHeaderFields(with: cookies)[cookieKey] {
            request.addValue(value, forHTTPHeaderField: cookieKey)
        }
        return request
    }
    
    /// 设置进度条观察者
    func setupEstimatedProgressObservation() {
        
        estimatedProgressObservation = webView.observe(\.estimatedProgress, options: [.new], changeHandler: { [weak self] (webview, change) in
            guard let self = self else { return }
            let estimatedProgress = webview.estimatedProgress
            self.progressView.alpha = 1
            self.progressView.setProgress(Float(webview.estimatedProgress), animated: true)
                       
            if estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                    self.progressView.alpha = 0
                }, completion: {
                    finished in
                    self.progressView.setProgress(0, animated: false)
                })
            }
        })
    }
    
    /// 设置标题观察者
    func setupTitleObservation() {
        
        if websiteTitleInNavigationBar {
            titleObservation = webView.observe(\.title, options: [.new], changeHandler: { [weak self] (webView, change) in
                guard let self = self else { return }
                if let title = webView.title, !title.isEmpty {
                    self.navigationItem.title = webView.title
                    self.delegate?.webViewController?(self, webView: title)
                }
            })
        }
    }
    
    func addBarButtonItems() {
        
        func barButtonItem(_ type: BarButtonItemType) -> UIBarButtonItem? {
            switch type {
            case .back:
                return backBarButtonItem
            case .forward:
                return forwardBarButtonItem
            case .reload:
                return reloadBarButtonItem
            case .stop:
                return stopBarButtonItem
            case .activity:
                return activityBarButtonItem
            case .done:
                return doneBarButtonItem
            case .flexibleSpace:
                return flexibleSpaceBarButtonItem
            case .custom(let icon, let title, let action):
                let item: BlockBarButtonItem
                if let icon = icon {
                    item = BlockBarButtonItem(image: icon, style: .plain, target: self, action: #selector(customDidClick(sender:)))
                } else {
                    item = BlockBarButtonItem(title: title, style: .plain, target: self, action: #selector(customDidClick(sender:)))
                }
                item.block = action
                return item
            }
        }
        
        if presentingViewController != nil {
            switch doneBarButtonItemPosition {
            case .left:
                if !leftNavigaionBarItemTypes.contains(where: { type in
                    switch type {
                    case .done:
                        return true
                    default:
                        return false
                    }
                }) {
                    leftNavigaionBarItemTypes.insert(.done, at: 0)
                }
            case .right:
                if !rightNavigaionBarItemTypes.contains(where: { type in
                    switch type {
                    case .done:
                        return true
                    default:
                        return false
                    }
                }) {
                    rightNavigaionBarItemTypes.insert(.done, at: 0)
                }
            case .none:
                break
            }
        }
        
        navigationItem.leftBarButtonItems = leftNavigaionBarItemTypes.map {
            barButtonItemType in
            if let barButtonItem = barButtonItem(barButtonItemType) {
                return barButtonItem
            }
            return UIBarButtonItem()
        }
        
        navigationItem.rightBarButtonItems = rightNavigaionBarItemTypes.map {
            barButtonItemType in
            if let barButtonItem = barButtonItem(barButtonItemType) {
                return barButtonItem
            }
            return UIBarButtonItem()
        }
        
        if toolbarItemTypes.count > 0 {
            for index in 0..<toolbarItemTypes.count - 1 {
                toolbarItemTypes.insert(.flexibleSpace, at: 2 * index + 1)
            }
        }
        
        setToolbarItems(toolbarItemTypes.map {
            barButtonItemType -> UIBarButtonItem in
            if let barButtonItem = barButtonItem(barButtonItemType) {
                return barButtonItem
            }
            return UIBarButtonItem()
        }, animated: true)
    }
    
    func updateBarButtonItems() {
        
        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward
        
        let updateReloadBarButtonItem: (UIBarButtonItem, Bool) -> UIBarButtonItem = {
            [unowned self] barButtonItem, isLoading in
            switch barButtonItem {
            case self.reloadBarButtonItem:
                fallthrough
            case self.stopBarButtonItem:
                return isLoading ? self.stopBarButtonItem : self.reloadBarButtonItem
            default:
                break
            }
            return barButtonItem
        }
        
        let isLoading = webView.isLoading
        toolbarItems = toolbarItems?.map {
            barButtonItem -> UIBarButtonItem in
            return updateReloadBarButtonItem(barButtonItem, isLoading)
        }
        
        navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems?.map {
            barButtonItem -> UIBarButtonItem in
            return updateReloadBarButtonItem(barButtonItem, isLoading)
        }
        
        navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems?.map {
            barButtonItem -> UIBarButtonItem in
            return updateReloadBarButtonItem(barButtonItem, isLoading)
        }
    }
    
    func checkRequestCookies(_ request: URLRequest, cookies: [HTTPCookie]) -> Bool {
        if cookies.count <= 0 {
            return true
        }
        guard let headerFields = request.allHTTPHeaderFields, let cookieString = headerFields[cookieKey] else {
            return false
        }
        
        let requestCookies = cookieString.components(separatedBy: ";").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "=", maxSplits: 1).map(String.init)
        }
        
        var valid = false
        for cookie in cookies {
            valid = requestCookies.filter {
                $0[0] == cookie.name && $0[1] == cookie.value
                }.count > 0
            if !valid {
                break
            }
        }
        return valid
    }
    
    func openURLWithApp(_ url: URL) -> Bool {
        let application = UIApplication.shared
        if application.canOpenURL(url) {
            return application.openURL(url)
        }
        
        return false
    }
    
    func handleURLWithApp(_ url: URL, targetFrame: WKFrameInfo?) -> Bool {
        
        let hosts = UrlsHandledByApp.hosts
        let schemes = UrlsHandledByApp.schemes
        let blank = UrlsHandledByApp.blank
        
        var tryToOpenURLWithApp = false
        if let host = url.host, hosts.contains(host) {
            tryToOpenURLWithApp = true
        }
        if let scheme = url.scheme, schemes.contains(scheme) {
            tryToOpenURLWithApp = true
        }
        if blank && targetFrame == nil {
            tryToOpenURLWithApp = true
        }
        
        return tryToOpenURLWithApp ? openURLWithApp(url) : false
    }
    
    @objc func backDidClick(sender: AnyObject) {
        webView.goBack()
    }
    
    @objc func forwardDidClick(sender: AnyObject) {
        webView.goForward()
    }
    
    @objc func reloadDidClick(sender: AnyObject) {
        webView.stopLoading()
        if webView.url != nil {
            webView.reload()
        } else if let s = self.source {
            self.load(source: s)
        }
    }
    
    @objc func stopDidClick(sender: AnyObject) {
        webView.stopLoading()
    }
    
    @objc func activityDidClick(sender: UIBarButtonItem) {
        guard let s = self.source else {
            return
        }
        
        let items: [Any]
        switch s {
        case .remote(let u):
            items = [u]
        case .file(let u, access: _):
            items = [u]
        case .string(let str, base: _):
            items = [str]
        }
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func doneDidClick(sender: AnyObject) {
        var canDismiss = true
        if let url = self.source?.url {
            canDismiss = delegate?.webViewController?(self, canDismiss: url) ?? true
        }
        if canDismiss {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func customDidClick(sender: BlockBarButtonItem) {
        sender.block?(self)
    }
}

// MARK: - WKUIDelegate
extension WZWebViewController: WKUIDelegate {
    
}

// MARK: - WKScriptMessageHandler
extension WZWebViewController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.webViewController?(self, didReceive: message)
    }
}

// MARK: - WKNavigationDelegate
extension WZWebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateBarButtonItems()
        self.progressView.progress = 0
        if let u = webView.url {
            self.url = u
            delegate?.webViewController?(self, didStart: u)
        }
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateBarButtonItems()
        self.progressView.progress = 0
        if let url = webView.url {
            self.url = url
            delegate?.webViewController?(self, didFinish: url)
        }
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateBarButtonItems()
        self.progressView.progress = 0
        if let url = webView.url {
            self.url = url
            delegate?.webViewController?(self, didFail: url, withError: error)
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateBarButtonItems()
        self.progressView.progress = 0
        if let url = webView.url {
            self.url = url
            delegate?.webViewController?(self, didFail: url, withError: error)
        }
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let bypassedSSLHosts = bypassedSSLHosts, bypassedSSLHosts.contains(challenge.protectionSpace.host) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var actionPolicy: WKNavigationActionPolicy = .allow
        defer {
            decisionHandler(actionPolicy)
        }
        guard let u = navigationAction.request.url else {
            debugPrint("Cannot handle empty URLs")
            return
        }
        
        if !self.allowsFileURL && u.isFileURL {
            debugPrint("Cannot handle file URLs")
            return
        }
        
        if handleURLWithApp(u, targetFrame: navigationAction.targetFrame) {
            actionPolicy = .cancel
            return
        }
        
        if u.host == self.source?.url?.host, let cookies = availableCookies, !checkRequestCookies(navigationAction.request, cookies: cookies) {
            self.load(remote: u)
            actionPolicy = .cancel
            return
        }
        
        if let navigationType = NavigationType(rawValue: navigationAction.navigationType.rawValue), let result = delegate?.webViewController?(self, decidePolicy: u, navigationType: navigationType) {
            actionPolicy = result ? .allow : .cancel
        }
    }
}

class BlockBarButtonItem: UIBarButtonItem {
    
    var block: ((WZWebViewController) -> Void)?
}


