//
//  Enums.swift
//  WZWebViewController
//
//  Created by xiaobin liu on 2019/10/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Foundation


/// MARK - WZWebSource
public enum WZWebSource: Equatable {
    
    case remote(URL)
    case file(URL, access: URL)
    case string(String, base: URL?)
    
    public var url: URL? {
        switch self {
        case .remote(let u): return u
        case .file(let u, access: _): return u
        default: return nil
        }
    }
    
    public var remoteURL: URL? {
        switch self {
        case .remote(let u): return u
        default: return nil
        }
    }
    
    public var absoluteString: String? {
        switch self {
        case .remote(let u): return u.absoluteString
        case .file(let u, access: _): return u.absoluteString
        default: return nil
        }
    }
}


/// MARK - BarButtonItemType 类型
public enum BarButtonItemType {
    
    /// 后退
    case back
    
    /// 向前
    case forward
    
    /// 加载
    case reload
    
    /// 停止
    case stop
    
    /// 活动
    case activity
    
    /// 完成
    case done
    
    /// flexibleSpace
    case flexibleSpace
    
    /// 自定义
    case custom(icon: UIImage?, title: String?, action: (WZWebViewController) -> Void)
}


/// MARK - 导航Bar位置
public enum NavigationBarPosition: String, Equatable, Codable {
    
    case none
    case left
    case right
}

/// MARK - 导航类型
@objc public enum NavigationType: Int, Equatable, Codable {
    case linkActivated
    case formSubmitted
    case backForward
    case reload
    case formResubmitted
    case other
}
