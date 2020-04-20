//
//  ChatListViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/10/8.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Foundation

class ChatListViewController: RCConversationListViewController, UINavigationBarDelegate {
    
    var navBar: UINavigationBar! // 自定义导航栏
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加自定义导航栏
        self.navBar = BaseViewController.createNavBar(title: "会话列表", isPresentView: false, delegate: self)
        view.addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 调整会话列表位置
        self.conversationListTableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        self.setDisplayConversationTypes([
            RCConversationType.ConversationType_PRIVATE.rawValue,
            RCConversationType.ConversationType_SYSTEM.rawValue])
        
        self.conversationListTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    //点击cell  进行跳转到聊天室
    override func onSelectedTableRow(_ conversationModelType: RCConversationModelType, conversationModel model: RCConversationModel!, at indexPath: IndexPath!) {
        let rongVC = ChatDetailViewController(conversationType: model.conversationType, targetId: model.targetId, title: model.conversationTitle)
        // rongVC.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(rongVC, animated: true)
    }
    
    //点击头像的跳转
    override func didTapCellPortrait(_ model: RCConversationModel!) {
        if let uid = Int(model.targetId) {
            let nextView = UserInfoViewController(userId: uid)
            navigationController?.pushViewController(nextView, animated: true)
        }
    }
    
    // 点击返回事件
    @objc func navBarBackBtnClick() {
        navigationController?.popViewController(animated: true)
    }
    
    // 导航条通顶
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
}
