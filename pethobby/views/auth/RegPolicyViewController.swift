//
//  RegPolicyViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/15.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import WebViewWarmUper

class RegPolicyViewController: BaseViewController {
    
    private var policy = ""
    
    init(policy: String, title: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.policy = policy
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView = WKWebViewWarmUper.shared.dequeue()
        var doc = "privacypolicy"
        if self.policy == "agree" {
            doc = "agree"
        }
        
        let url = URL(string: "https://www.mu78.com/\(doc).html")
        let request = URLRequest(url: url!)
        webView.load(request)
        
        view.addSubview(webView)
        webView.snp.makeConstraints { (v) in
            v.top.equalTo(self.myNavigationBar.snp.bottom).offset(1)
            v.left.right.bottom.equalTo(view)
        }
    }

}
