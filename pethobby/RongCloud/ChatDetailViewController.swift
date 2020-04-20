//
//  ChatDetailViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/10/8.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Foundation

class ChatDetailViewController: RCConversationViewController, UINavigationBarDelegate {
    // 当前界面是否打开
    static var isActive:Bool = false
    // 当前会话用户ID
    static var currentUid:String = ""
    
     // 自定义导航栏
    var navBar: UINavigationBar!
    
    init(conversationType: RCConversationType, targetId: String, title: String) {
        super.init(nibName: nil, bundle: nil)
        
        self.conversationType = conversationType
        self.targetId = targetId
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加自定义导航栏
        self.navBar = BaseViewController.createNavBar(title: self.title ?? "", isPresentView: false, delegate: self)
        view.addSubview(navBar)        
        navBar.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 系统消息，不让回复
        if (self.targetId == "1000") {
            view.backgroundColor = UIColor.myColorLight1
            self.chatSessionInputBarControl.isHidden = true
        }
        
        ChatDetailViewController.isActive = true
        ChatDetailViewController.currentUid = self.targetId
    }
    
    // 点击返回事件
    @objc func navBarBackBtnClick() {
        navigationController?.popViewController(animated: true)
    }
    
    // 导航条通顶
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ChatDetailViewController.isActive = false
        ChatDetailViewController.currentUid = ""
    }
}
