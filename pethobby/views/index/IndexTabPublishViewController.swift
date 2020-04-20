//
//  IndexTabPublishViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit

class IndexTabPublishViewController: UIViewController {
    
    @IBAction func btn_onclick(_ sender: UIButton) {
        var nextView: UIViewController?
        if (MySession.getInstance().isLogin() == false) {
            nextView = LoginViewController()
            UIViewController.exGetTopViewController()?.navigationController?.pushViewController(nextView!, animated: true)
            return
        }
        
        switch sender.tag {
        case 1:
            nextView = PublishImageArticleViewController()
            break
        case 2:
            nextView = PublishVideoArticleViewController()
            break
        case 3:
            nextView = PublishRichArticleViewController()
            break
        default:
            break
        }
        nextView?.modalPresentationStyle = .fullScreen
        UIViewController.exGetTopViewController()?.present(nextView!, animated: true)
    }
}
