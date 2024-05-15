//
//  ViewController.swift
//  WZWebViewController
//
//  Created by LiuSky on 10/19/2019.
//  Copyright (c) 2019 LiuSky. All rights reserved.
//

import UIKit
import WZWebViewController

class ViewController: UIViewController {

    /// 按钮
    private lazy var button: UIButton = {
        
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.setTitle("测试", for: UIControl.State.normal)
        temButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        temButton.addTarget(self, action: #selector(eventForPush), for: UIControl.Event.touchUpInside)
        temButton.translatesAutoresizingMaskIntoConstraints = false
        return temButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(button)
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    @objc private func eventForPush() {
        
        let vc = WZWebViewController(source: .remote("https://www.baidu.com/"))
        vc.toolbarItemTypes = []
        vc.rightNavigaionBarItemTypes = [.back]
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.pushViewController(vc, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

