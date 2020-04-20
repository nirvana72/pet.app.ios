//
//  ChangePasswordViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/19.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import PKHUD
import Alamofire

class ChangePasswordViewController: BaseViewController {
    @IBOutlet weak var txtOldPassword: UITextField!
    @IBOutlet weak var txtNewPassword: UITextField!
    @IBOutlet weak var txtNewPasswordConfirm: UITextField!
   
    override func viewDidLoad() {
        self.title = "修改密码"
        super.viewDidLoad()
        
        txtOldPassword.exAddIcon(icon: "icon_lock")
        txtNewPassword.exAddIcon(icon: "icon_lock")
        txtNewPasswordConfirm.exAddIcon(icon: "icon_lock")
    }
    
    @IBAction func btnOK_click(_ sender: UIButton) {
        let pwdOld = txtOldPassword.text?.trimmingCharacters(in: .whitespaces)
        let pwdNew = txtOldPassword.text?.trimmingCharacters(in: .whitespaces)
        let pwdNew2 = txtNewPasswordConfirm.text?.trimmingCharacters(in: .whitespaces)
        
        if pwdOld == "" || pwdNew == "" {
            return
        }
        
        if !(pwdNew?.exMatches("^.{6,18}$") ?? false) {
            UIAlertController.error(message: "密码格式不正确, 长度在6~18之间,任意字符")
            return
        }
        
        if pwdNew != pwdNew2 {
            UIAlertController.alert(message: "两次密码输入不一致")
            return
        }
        
        PKHUD.progress()
        
        let parameters: Parameters = [
            "old": pwdOld!,
            "new": pwdNew!
        ]
        
        MyHttpClient.requestJSON("/users/changepassowrd", method: .put, parameters: parameters) { (success, json) in
            
            PKHUD.hide()
            
            if success {
                UIAlertController.alert(message: "修改成功", completion: { (_) in
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
}
