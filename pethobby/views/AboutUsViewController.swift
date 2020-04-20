//
//  AboutUsViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/15.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit

class AboutUsViewController: BaseViewController {
    @IBOutlet weak var lblNewVersion: UILabel!
    @IBOutlet weak var lblCurVersion: UILabel!
    
    override func viewDidLoad() {
        self.title = "关于我们"
        super.viewDidLoad()
        
        let curVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!
        self.lblCurVersion.text = "版本:\(curVersion)"
        
        lblNewVersion.isHidden = true
        
        if (AppDelegate.hasNewVersion) {
            lblNewVersion.pp.addDot()
            lblNewVersion.isHidden = false
            
            let tgr = UITapGestureRecognizer(target: self, action: #selector(lblNewVersion_click))
            lblNewVersion.addGestureRecognizer(tgr)
        }
    }
    
    @objc func lblNewVersion_click(_ sender: UITapGestureRecognizer) {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/\(MyConfig.Apple_ID)") else { return  }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
