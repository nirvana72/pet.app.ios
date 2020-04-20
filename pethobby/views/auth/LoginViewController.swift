//
//  LoginViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/13.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import PKHUD
import Alamofire

class LoginViewController: BaseViewController {
    @IBOutlet weak var txtAccount: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    override func viewDidLoad() {
        self.title = "登录"
        super.viewDidLoad()
        self.myNavigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(title: "注册", style: .plain, target: nil, action: #selector(btnReg_tapped))
        
        self.txtAccount.exAddIcon(icon: "icon_account")
        self.txtPassword.exAddIcon(icon: "icon_lock")
        self.txtAccount.text = UserDefaults.standard.string(forKey: "lastloginname")
    }

    @IBAction func btnSubmit_onclick(_ sender: UIButton) {
        let account = (txtAccount.text ?? "").trimmingCharacters(in: .whitespaces)
        let password = txtPassword.text ?? ""
        if account == "" {
            UIAlertController.error(message: "账号不能为空")
            return
        }
        if password.count < 6 {
            UIAlertController.error(message: "密码格式不正确, 长度在6~18位任意字符")
            return
        }
        let parameters: Parameters = [
            "account": account,
            "pwd": password
        ]
        
        PKHUD.progress()
        
        MyHttpClient.requestJSON("/users/login", method: .post, parameters: parameters) { (success, json) in
            
            PKHUD.hide()
            
            if success, let json = json {
                MySession.getInstance().uid       = json["uid"].intValue
                MySession.getInstance().nickname  = json["nickname"].stringValue
                MySession.getInstance().avatar    = json["avatar"].intValue
                MySession.getInstance().token     = json["token"].stringValue
                MySession.getInstance().role      = json["role"].stringValue
                MySession.getInstance().refreshtoken     = json["refreshtoken"].stringValue
                MySession.getInstance().time      = String( Int(Date().timeIntervalSince1970) )
                MySession.getInstance().save()
                
                UserDefaults.standard.set(account, forKey: "lastloginname")
                
                // 同时登录融云服务器
                RCIM.shared()?.ex_init()
                
                UIAlertController.alert(message: "登录成功", completion: { (_) in
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
    
    @objc func btnReg_tapped () {
        let nextView = RegViewController()
        navigationController?.pushViewController(nextView, animated: true)
    }

}
