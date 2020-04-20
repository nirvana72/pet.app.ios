//
//  UIAlertControllerExtension.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    static func confirm(message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: completion))
        alertController.addAction(UIAlertAction(title: "取消", style: .default, handler: nil))
        UIViewController.exGetTopViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    static func alert(message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: completion))
        UIViewController.exGetTopViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    static func error(message: String) {
        let alertController = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        UIViewController.exGetTopViewController()?.present(alertController, animated: true, completion: nil)
    }
}
