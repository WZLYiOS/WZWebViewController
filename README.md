# 我主良缘浏览器组件

## Requirements:
- **iOS** 9.0+
- Xcode 10.0+
- Swift 5.0+


## Installation Cocoapods
<pre><code class="ruby language-ruby">pod 'WZWebViewController', '~> 1.0.0'</code></pre>
<pre><code class="ruby language-ruby">pod 'WZWebViewController/Binary', '~> 1.0.0'</code></pre>

## Use
```swift
    let vc = WZWebViewController(url: URL(string: "https://www.baidu.com")!)
    vc.toolbarItemTypes = []
    vc.rightNavigaionBarItemTypes = [.activity, .reload, .forward, .back]
    navigationController?.pushViewController(vc, animated: true)
```

## License
WZWebViewController</code></pre>
 is released under an MIT license. See [LICENSE](LICENSE) for more information.
