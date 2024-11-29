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
    
    private lazy var webController: WZWebViewController = {
        $0.view.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(WZWebViewController(source: .remote("https://h5.jdtao.com/#/index")))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "测试"
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.isHidden = true
//        view.addSubview(button)
//        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
//        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        addChild(webController)
        view.addSubview(webController.view)
        NSLayoutConstraint.activate([
            webController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webController.view.topAnchor.constraint(equalTo: view.topAnchor),
            webController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func eventForPush() {
        
        let vc = WZWebViewController(source: .remote("https://h5.jdtao.com/#/index"))
        vc.toolbarItemTypes = []
        vc.rightNavigaionBarItemTypes = [.back]
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.pushViewController(vc, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

