//
//  RegViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import PKHUD
import Alamofire

class RegViewController: BaseViewController {
    
    @IBOutlet var btnRegTypes: [UIButton]!
    @IBOutlet weak var txtPasswordConfirm: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtMobile: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtAccount: UITextField!
    @IBOutlet weak var ivAgreeCheckBox: UIImageView!
    @IBOutlet weak var lblAgreeLink: UILabel!
    @IBOutlet weak var lblPolicyLink: UILabel!
    
    private var selectTypeIndex = 0
    private var agreeCheck = true
   
    override func viewDidLoad() {
        self.title = "注册"
        super.viewDidLoad()
        
        let tgrAgreeLink = MyTapGestureRecognizer(target: self, action: #selector(agreeLink_onclick))
        tgrAgreeLink.myParameters = ["link": "agree", "title": "《用户许可协议》"]
        self.lblAgreeLink.addGestureRecognizer(tgrAgreeLink)
        
        let tgrPolicyLink = MyTapGestureRecognizer(target: self, action: #selector(agreeLink_onclick))
        tgrPolicyLink.myParameters = ["link": "policy", "title": "《隐私政策》"]
        self.lblPolicyLink.addGestureRecognizer(tgrPolicyLink)
        
        self.txtAccount.exAddIcon(icon: "icon_account")
        self.txtEmail.exAddIcon(icon: "icon_email")
        self.txtMobile.exAddIcon(icon: "icon_phone")
        self.txtPassword.exAddIcon(icon: "icon_lock")
        self.txtPasswordConfirm.exAddIcon(icon: "icon_lock")
        
        self.setRegTypeStatus()
    }
    
    // 切换注册类型后改变状态
    private func setRegTypeStatus() {
        for btn in self.btnRegTypes {
            btn.backgroundColor = UIColor.myColorDark3
        }
        self.txtAccount.isHidden = self.selectTypeIndex != 0
        self.txtEmail.isHidden = self.selectTypeIndex != 1
        self.txtMobile.isHidden = self.selectTypeIndex != 2
        self.btnRegTypes[self.selectTypeIndex].backgroundColor = UIColor.myColorGreen
    }
    // 是否同意注册复选框
    @IBAction func ivAgree_click(_ sender: UITapGestureRecognizer) {
        self.agreeCheck = !self.agreeCheck
        let icon = self.agreeCheck ? "icon_checkbox_on" : "icon_checkbox_off"
        self.ivAgreeCheckBox.image = UIImage(named: icon)
    }
    // 切换注册类型
    @IBAction func btnRegType_onclick(_ sender: UIButton) {
        self.selectTypeIndex = sender.tag
        self.setRegTypeStatus()
    }
    
    @IBAction func btnSubmit_onclick(_ sender: UIButton) {
        if (self.agreeCheck == false) {
            UIAlertController.alert(message: "请您先仔细阅读用户服务许可协议和隐私政策。")
            return
        }
        let regType = ["account","email","mobile"][self.selectTypeIndex]
        if self.verify(elname: regType) == false {
            return
        }
        if self.verify(elname: "password") == false {
            return
        }
        
        var account = ""
        switch regType {
            case "account":
                account = txtAccount.text ?? ""
            case "email":
                account = txtEmail.text ?? ""
            case "mobile":
                account = txtMobile.text ?? ""
            default:
                break
        }
        
        let parameters: Parameters = [
            "account": account,
            "reg_type": regType,
            "pwd": txtPassword.text ?? ""
        ]
        
        HUD.show(.progress)
        
        MyHttpClient.requestJSON("/users/", method: .post, parameters: parameters) { (success, json) in
            
            HUD.hide()
            
            if success, let json = json {
                MySession.getInstance().uid       = json["uid"].intValue
                MySession.getInstance().nickname  = json["nickname"].stringValue
                MySession.getInstance().avatar    = json["avatar"].intValue
                MySession.getInstance().token     = json["token"].stringValue
                MySession.getInstance().refreshtoken     = json["refreshtoken"].stringValue
                MySession.getInstance().time      = String( Int(Date().timeIntervalSince1970) )
                MySession.getInstance().save()
                
                UserDefaults.standard.set(account, forKey: "lastloginname")
                
                UIAlertController.alert(message: "欢迎您 \(MySession.getInstance().nickname)", completion: { (_) in
                    self.navigationController?.popToRootViewController(animated: true)
                })
            }
        }
    }
    
    // 注册验证
    private func verify(elname: String) ->Bool {
        var flag = false
        switch elname {
            case "account":
                flag = txtAccount.text?.exMatches("^[a-zA-Z0-9_\u{4e00}-\u{9fa5}]{6,18}$") ?? false
                if !flag { UIAlertController.error(message: "账号格式不正确, 6~18位中英文数字下划线") }
                break
            case "email":
                flag = txtEmail.text?.exMatches("^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$") ?? false
                if !flag { UIAlertController.error(message: "邮箱格式不正确") }
                break
            case "mobile":
                flag = txtMobile.text?.exMatches("^(13[0-9]|14[0-9]|15[0-9]|166|17[0-9]|18[0-9]|19[8|9])\\d{8}$") ?? false
                if !flag { UIAlertController.error(message: "手机格式不正确") }
                break
            case "password":
                flag = txtPassword.text?.exMatches("^.{6,18}$") ?? false
                if !flag { UIAlertController.error(message: "密码格式不正确, 长度在6~18之间,任意字符") }
                if flag {
                    flag = txtPassword.text == txtPasswordConfirm.text
                    if !flag { UIAlertController.error(message: "两次密码输入不一至") }
                }
                break
            default:
                break
        }
        return flag
    }
    // 注册条款
    @IBAction func agreeLink_onclick(_ sender: MyTapGestureRecognizer) {
        let link = sender.myParameters?["link"] as! String
        let title = sender.myParameters?["title"] as! String
        let nextView = RegPolicyViewController(policy: link, title: title)
        self.present(nextView, animated: true, completion: nil)
    }
}
