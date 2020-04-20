//
//  AuthUserInfoViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/15.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import PKHUD
import Alamofire

class UserInfoViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct User {
        var id: Int
        var avatar: Int = 0
        var account: String = ""
        var nickname: String = ""
        var email: String = ""
        var mobile: String = ""
        var profile: String = ""
        var articles: Int = 0
        var fans: Int = 0
        var subscribed: Bool = false
    }
    
    var user: User!
    
    init(userId: Int) {
        super.init(nibName: nil, bundle: nil)
        self.user = User(id: userId)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ---------------------------------------------------------------
    
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var lblProfile: UILabel!
    @IBOutlet weak var constraiontLblProfileHeight: NSLayoutConstraint!
    @IBOutlet weak var btnChangeAvatar: UIButton!
    @IBOutlet weak var btnSubscribe: UIButton!
    @IBOutlet weak var btnChart: UIButton!
    
    var tableView: UITableView!
    @IBOutlet var cellHeader: UITableViewCell!
    @IBOutlet var cellUserID: UITableViewCell!
    @IBOutlet var cellAccount: UITableViewCell!
    @IBOutlet var cellNickName: UITableViewCell!
    @IBOutlet var cellEmail: UITableViewCell!
    @IBOutlet var cellMobile: UITableViewCell!
    @IBOutlet var cellChangePassword: UITableViewCell!
    @IBOutlet var cellProfile: UITableViewCell!
    @IBOutlet var cellArticles: UITableViewCell!
    @IBOutlet var cellFans: UITableViewCell!
    
    private var cells: [UITableViewCell] = []
    private var cellHeaderHeight: CGFloat = 20 + 150 + 15 + 40 //  margin top + avatar + lbl margin + margin bottom
    
    override func viewDidLoad() {
        let isMe = self.user.id == MySession.getInstance().uid
        self.title = isMe ? "个人中心" : "用户信息"
        super.viewDidLoad()
        
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView.init(frame: .zero)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (v) in
            v.leading.trailing.bottom.equalToSuperview()
            v.top.equalTo(self.myNavigationBar.snp.bottom)
        }
        
        // 取消header cell 下划线
        cellHeader.separatorInset = UIEdgeInsets(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
        
        btnChangeAvatar.isHidden = !isMe
        btnSubscribe.isHidden = isMe
        btnChart.isHidden = isMe
        
        cells.append(cellUserID)
        cells.append(cellAccount)
        cells.append(cellNickName)
        cells.append(cellEmail)
        cells.append(cellMobile)
        if (isMe) {
            cells.append(cellChangePassword)
            cells.append(cellProfile)
        }
        cells.append(cellArticles)
        cells.append(cellFans)
        
        if (!isMe) {
            cellNickName.accessoryType = .none
            cellEmail.accessoryType = .none
            cellMobile.accessoryType = .none
            cellNickName.accessoryType = .none
        }
        
        MyHttpClient.requestJSON("/users/\(self.user.id)", method: .get) { (success, json) in

            if success {
                guard let json = json else {
                    UIAlertController.alert(message: "json 格式不正确")
                    return
                }
                
                guard json["user"].exists() else {
                    UIAlertController.alert(message: "json 格式不正确")
                    return
                }
                
                self.user.avatar        = json["user"]["avatar"].intValue
                self.user.account       = json["user"]["account"].stringValue
                self.user.nickname      = json["user"]["nickname"].stringValue
                self.user.email         = json["user"]["email"].stringValue
                self.user.mobile        = json["user"]["mobile"].stringValue
                self.user.articles      = json["user"]["articles"].intValue
                self.user.fans          = json["user"]["fans"].intValue
                self.user.subscribed    = json["user"]["subscribed"].boolValue
                self.user.profile       = json["user"]["profile"].stringValue
                
                DispatchQueue.main.async {
                    self.setupView()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func setupView() {
        let avatarUrl = MyTools.avatarPath(avatar: self.user.avatar)
        self.ivAvatar.exSetImageSrc(avatarUrl)
        
        self.lblProfile.text = self.user.profile
        let lblProfileSize = self.lblProfile.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 20 * 2, height: 200))
        self.constraiontLblProfileHeight.constant = lblProfileSize.height
        
        self.cellUserID.detailTextLabel?.text = String( self.user.id )
        self.cellAccount.detailTextLabel?.text = self.user.account
        self.cellNickName.detailTextLabel?.text = self.user.nickname
        self.cellEmail.detailTextLabel?.text = self.user.email
        self.cellMobile.detailTextLabel?.text = self.user.mobile
        self.cellArticles.detailTextLabel?.text = String( self.user.articles )
        self.cellFans.detailTextLabel?.text = String( self.user.fans )
        
        if (self.user.subscribed) {
            self.btnSubscribe.setImage(UIImage(named: "icon_star"), for: .normal)
            self.btnSubscribe.tintColor = UIColor.red
        }
    }
    
    @IBAction func btnChangeAvatar_click(_ sender: UIButton) {
        let nextView = ChangeAvatarViewController(avatar: self.user.avatar)
        nextView.opener = self
        navigationController?.pushViewController(nextView, animated: true)
    }
    
    @IBAction func btnSubscribe_click(_ sender: UIButton) {
        if (MySession.getInstance().isLogin() == false) {
            PKHUD.toast(text: "请先登录")
            return
        }
        let method: Alamofire.HTTPMethod = self.user.subscribed ? .delete : .put
        MyHttpClient.requestJSON("/subscribes/\(self.user.id)", method: method) { (success, json) in
            if success  {
                self.user.subscribed = !self.user.subscribed
                let icon = self.user.subscribed ? "icon_star" : "icon_star_border"
                sender.setImage(UIImage(named: icon), for: .normal)
                sender.tintColor = self.user.subscribed ? UIColor.red : UIColor.myColorDark2
                if (self.user.subscribed) {
                    sender.imageView?.exSetClickAnimate()
                    PKHUD.toast(text: "关注成功")
                }
            }
        }
    }
    
    @IBAction func btnChart_click(_ sender: UIButton) {
        if (MySession.getInstance().isLogin() == false) {
            PKHUD.toast(text: "请先登录")
        } else {
            let targetId = String(self.user.id)
            let chatView = ChatDetailViewController(conversationType: .ConversationType_PRIVATE, targetId: targetId, title: self.user.nickname)
            self.navigationController?.pushViewController(chatView, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count + 1 // header + cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return indexPath.row == 0 ? self.cellHeader : self.cells[indexPath.row - 1]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? (self.cellHeaderHeight + constraiontLblProfileHeight.constant): 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row > 0) {
            let cell = self.cells[indexPath.row - 1]
            if (cell.accessoryType == .disclosureIndicator) {
                let cellName = cell.textLabel?.text ?? ""
                switch cellName {
                case "昵称":
                    let nextView = UserInfoUpdateViewController(attrName: "nickname", attrNameCn: cellName, attrValue: self.user.nickname)
                    nextView.opener = self
                    navigationController?.pushViewController(nextView, animated: true)
                    break
                case "电子邮箱":
                    let nextView = UserInfoUpdateViewController(attrName: "email", attrNameCn: cellName, attrValue: self.user.email)
                    nextView.opener = self
                    navigationController?.pushViewController(nextView, animated: true)
                    break
                case "手机号码":
                    let nextView = UserInfoUpdateViewController(attrName: "mobile", attrNameCn: cellName, attrValue: self.user.mobile)
                    nextView.opener = self
                    navigationController?.pushViewController(nextView, animated: true)
                    break
                case "修改密码":
                    let nextView = ChangePasswordViewController()
                    navigationController?.pushViewController(nextView, animated: true)
                    break
                case "简介":
                    let nextView = UserInfoUpdateViewController(attrName: "profile", attrNameCn: cellName, attrValue: self.user.profile)
                    nextView.opener = self
                    navigationController?.pushViewController(nextView, animated: true)
                    break
                case "发布动态":
                    let nextView = UserPubsViewController(userId: self.user.id, nickName: self.user.nickname)
                    navigationController?.pushViewController(nextView, animated: true)
                    break
                default:
                    break
                }
            }
        }
    }
    
    func updateCallBack (attrName: String, attrValue: String) {
        switch attrName {
        case "nickname":
            // 同步更新融云服务器上的个人信息
            RCIM.shared()?.ex_refresh(uid: MySession.getInstance().uid)
            
            self.user.nickname = attrValue
            cellNickName.detailTextLabel?.text = attrValue
            MySession.getInstance().nickname = attrValue
            MySession.getInstance().time = String( Int(Date().timeIntervalSince1970) )
            MySession.getInstance().save()
            break
        case "email":
            self.user.email = attrValue
            cellEmail.detailTextLabel?.text = attrValue
            break
        case "mobile":
            self.user.mobile = attrValue
            cellMobile.detailTextLabel?.text = attrValue
            break
        case "profile":
            self.user.profile = attrValue
            lblProfile.text = attrValue
            let lblProfileSize = lblProfile.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 20 * 2, height: 200))
            constraiontLblProfileHeight.constant = lblProfileSize.height
            tableView.reloadData()
            break
        case "avatar":
            // 同步更新融云服务器上的个人信息
            RCIM.shared()?.ex_refresh(uid: MySession.getInstance().uid)
            
            self.user.avatar = Int(attrValue)!
            let avatarUrl = MyTools.avatarPath(avatar: self.user.avatar)
            ivAvatar.exSetImageSrc(avatarUrl)
            break
        default:
            break
        }
    }
}
