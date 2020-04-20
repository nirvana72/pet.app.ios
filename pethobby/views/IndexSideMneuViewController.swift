//
//  IndexSideMneuViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/15.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import PKHUD

class IndexSideMneuViewController: UIViewController {

    @IBOutlet weak var vAvatar: UIView!
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var lblNickName: UILabel!
    @IBOutlet weak var lblRole: UILabel!
    @IBOutlet weak var vMenuUserInfo: UIView!
    @IBOutlet weak var vMenuMessage: UIView!
    @IBOutlet weak var vMenuAboutUS: UIView!
    @IBOutlet weak var lblAboutUs: UILabel!
    @IBOutlet weak var vMenuReview: UIView!
    @IBOutlet weak var vMenuLogin: UIView!
    @IBOutlet weak var vMenuLogout: UIView!
    
    private var sessionCode = "null"
    private var forceReflash = false // 强制刷新
    var hostViewController: UIViewController? = nil // 宿主 ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tgrUserInfo = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrUserInfo.myParameters = ["action": "userinfo"]
        self.vMenuUserInfo.addGestureRecognizer(tgrUserInfo)
        
        let tgrMessage = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrMessage.myParameters = ["action": "message"]
        self.vMenuMessage.addGestureRecognizer(tgrMessage)
        
        let tgrAboutUS = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrAboutUS.myParameters = ["action": "aboutus"]
        self.vMenuAboutUS.addGestureRecognizer(tgrAboutUS)
        
        let tgrReview = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrReview.myParameters = ["action": "review"]
        self.vMenuReview.addGestureRecognizer(tgrReview)
        
        let tgrLogin = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrLogin.myParameters = ["action": "login"]
        self.vMenuLogin.addGestureRecognizer(tgrLogin)
        
        let tgrLogout = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrLogout.myParameters = ["action": "logout"]
        self.vMenuLogout.addGestureRecognizer(tgrLogout)
        
        self.updateView()
    }
    
    func updateView() {
        if (!self.isViewLoaded) { return }
        
        if (!self.forceReflash) {
            if (self.sessionCode == MySession.getInstance().time) { return }
        }
        
        self.sessionCode = MySession.getInstance().time
        self.forceReflash = false
        
        // 有新版本提醒
        if (AppDelegate.hasNewVersion) {
            lblAboutUs.pp.addDot()
        }
        
        if (MySession.getInstance().isLogin()) {
            self.vAvatar.isHidden = false // stackview 中只要 Hidden 就不占位隐藏
            self.vMenuLogin.isHidden = true
            self.vMenuLogout.isHidden = false
            self.vMenuReview.isHidden = !(MySession.getInstance().role == "admin")
            let avatarUrl = MyTools.avatarPath(avatar: MySession.getInstance().avatar)
            self.ivAvatar.exSetImageSrc(avatarUrl)
            self.lblNickName.text = MySession.getInstance().nickname
            self.lblRole.text = MySession.getInstance().role
            self.lblRole.isHidden = MySession.getInstance().role == "custom"
            
            // 未读消息提醒
            let lblMessage = self.vMenuMessage.subviews[1]
            if (RCIM.shared().ex_getMessageCount() > 0) {
                lblMessage.pp.addBadge(number: RCIM.shared().ex_getMessageCount())
                lblMessage.pp.moveBadge(x: 15, y: 12)
            }
            else {
                lblMessage.pp.hiddenBadge()
            }
        } else {
            self.vAvatar.isHidden = true
            self.vMenuReview.isHidden = true
            self.vMenuLogin.isHidden = false
            self.vMenuLogout.isHidden = true
        }
    }
    // 自己的逻辑自己处理
    @objc func menuAction(_ sender: MyTapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
        
        let action = sender.myParameters!["action"] as! String
        switch action {
            case "userinfo":
                if (MySession.getInstance().isLogin() == false) {
                    self.hostViewController?.navigationController?.pushViewController(LoginViewController(), animated: true)
                } else {
                    let nextView = UserInfoViewController(userId: MySession.getInstance().uid)
                    self.hostViewController?.navigationController?.pushViewController(nextView, animated: true)
                }
                break
            case "message":
                if MySession.getInstance().isLogin() {
                    self.hostViewController?.navigationController?.pushViewController(ChatListViewController(), animated: true)
                    // 清空消息数量
                    RCIM.shared()?.ex_setMessageCount(count: 0)
                    self.addBadge(menu: "message", badge: 0)
                } else {
                    self.hostViewController?.navigationController?.pushViewController(LoginViewController(), animated: true)
                }
                break
            case "aboutus":
                self.hostViewController?.navigationController?.pushViewController(AboutUsViewController(), animated: true)
                break
            case "review":
                self.hostViewController?.navigationController?.pushViewController(ArticleReviewViewController(), animated: true)
                break
            case "login":
                self.hostViewController?.navigationController?.pushViewController(LoginViewController(), animated: true)
                break
            case "logout":
                MySession.getInstance().clean()
                // 融云服务器断开连接
                RCIM.shared()?.ex_disconnect()
                HUD.flash(.label("账号已退出"), delay: 0.5)
                break
            default:
                break
        }
    }
    
    func addBadge(menu:String, badge: Int) {
        if (menu == "message") {
            self.forceReflash = true
        }
    }
    // -----------------------------------------------------------------------
    
    // instance
    static private var instance:IndexSideMneuViewController? = nil
    
    static func getInstance() -> IndexSideMneuViewController {
        if(instance == nil) {
            instance = IndexSideMneuViewController()
        }
        return instance!
    }
}
