//
//  RongCloudManager.swift
//  pethobby
//
//  Created by 倪佳 on 2019/10/8.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Foundation
import UserNotifications
import PPBadgeViewSwift

///实现三个代理方法,选择自己需要的使用
extension RCIM: RCIMReceiveMessageDelegate, RCIMUserInfoDataSource { // },RCIMGroupInfoDataSource,RCIMGroupUserInfoDataSource{
    
    // 融云即时聊天云服务
    func ex_init() {
        // 在官网上申请的App Key. 同时获取的App Secret我们并不需要,是后台需要的.
        RCIM.shared()?.initWithAppKey("mgb7ka1nmdugg")
        // 是否将用户信息和群组信息在本地持久化存储
        // RCIM.shared()?.enablePersistentUserInfoCache = true
        // 是否在发送的所有消息中携带当前登录的用户信息
        // RCIM.shared()?.enableMessageAttachUserInfo = true
        // 收到信息的代理
        RCIM.shared()?.receiveMessageDelegate = self
        // 关闭消息提示音
        // RCIM.shared()?.disableMessageAlertSound = true
        // 用户信息提供代理
        RCIM.shared().userInfoDataSource = self
        //        RCIM.shared().groupInfoDataSource = RCIMDataSource
        //        RCIM.shared().groupUserInfoDataSource = RCIMDataSource
        
        // 设置当前用户
        let portrait = MyTools.avatarPath(avatar: MySession.getInstance().avatar)
        let userinfo = RCUserInfo(userId: "\(MySession.getInstance().uid)", name: MySession.getInstance().nickname, portrait: portrait)
        RCIM.shared()?.currentUserInfo = userinfo
        
        // 获取token
        var token = UserDefaults.standard.string(forKey: "RCIMToken")
        if (token == nil) {
            MyHttpClient.requestJSON("/RongCloudApi/register?uid=\(MySession.getInstance().uid)") { (success, json) in
                if success, let _json = json {
                    token = _json["token"].stringValue
                    UserDefaults.standard.set(token, forKey: "RCIMToken")
                    self.ex_connect(token: token!)
                }
            }
        } else {
            self.ex_connect(token: token!)
        }
    }
    
    // 连接融云服务器
    private func ex_connect(token: String) {
        RCIM.shared()?.connect(withToken: token, success: { (_) in
            print("rongcloud 连接成功")
            // 获取未读消息数量
            var unreadCount = RCIMClient.shared()?.getTotalUnreadCount()
            if (unreadCount == nil) {
                unreadCount = 0
            }
            RCIM.shared()?.ex_setMessageCount(count: Int(unreadCount!))
            // 设置未读消息状态
            if (RCIM.shared().ex_getMessageCount() > 0) {
                DispatchQueue.main.async {
                    // 主菜单加红点
                    IndexTabMenuView.getInstance().ivSideMenuIcon.pp.addDot()
                    // 侧滑菜单加数字提示
                    IndexSideMneuViewController.getInstance().addBadge(menu: "message", badge: RCIM.shared()!.ex_getMessageCount())
                }
            }
            
        }, error: { (_) in
            UIAlertController.error(message: "消息服务器连接失败:1")
            // print("连接失败")
        }, tokenIncorrect: {
            UIAlertController.error(message: "消息服务器连接失败:2")
            // print("token不正确或超时")
        })
    }
    
    // 用户退出时，断开连接
    func ex_disconnect() {
        UserDefaults.standard.removeObject(forKey: "RCIMToken")
        RCIM.shared()?.disconnect()
    }
    
    // 刷新用户信息
    func ex_refresh(uid: Int) {
        MyHttpClient.requestJSON("/RongCloudApi/update?uid=\(uid)") { (_, _) in
            
        }
    }
    
    func ex_storeKeyName() -> String {
        return "RCIMMessageCount"
    }
    // 消息记数
    func ex_addMessageCount() {
        var messageCount = UserDefaults.standard.integer(forKey: self.ex_storeKeyName())
        messageCount = messageCount + 1
        UserDefaults.standard.set(messageCount, forKey: self.ex_storeKeyName())
    }
    // 消息记数
    func ex_getMessageCount() -> Int {
        let messageCount = UserDefaults.standard.integer(forKey: self.ex_storeKeyName())
        return messageCount
    }
    // 消息清0
    func ex_setMessageCount(count: Int = 0) {
        UserDefaults.standard.set(count, forKey: self.ex_storeKeyName())
    }
    
    
    // 在前台和后台活动状态时收到任何消息都会执行
    public func onRCIMReceive(_ message: RCMessage!, left: Int32) {
        if (ChatDetailViewController.isActive && ChatDetailViewController.currentUid == message.senderUserId) {
            //print("当前用户正在会话中，不需要提示")
            return
        }
        //print("onRCIMReceive")
        DispatchQueue.main.async {
            if (UIApplication.shared.applicationState == .active) { //应用在前台
                //print("onRCIMReceive .active")
                self.ex_addMessageCount()
                // 主菜单加红点
                IndexTabMenuView.getInstance().ivSideMenuIcon.pp.addDot()
                // 侧滑菜单加数字提示
                IndexSideMneuViewController.getInstance().addBadge(menu: "message", badge: RCIM.shared()!.ex_getMessageCount())
            }
        }
    }
    // 在后台活动状态时接收到消息弹出本地通知前触发，可自定义本地通知。
    public func onRCIMCustomLocalNotification(_ message: RCMessage!, withSenderName senderName: String!) -> Bool {
        //print("onRCIMCustomLocalNotification")
        self.ex_addMessageCount()
        //设置推送内容
        let content = UNMutableNotificationContent()
        content.title = senderName
        // content.subtitle = "This is subtitle"
        content.body = message.content.conversationDigest()
        content.sound = UNNotificationSound.default
        content.badge = self.ex_getMessageCount() as NSNumber
        //设置通知触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        //设置请求标识符
        let requestIdentifier = "com.mu78.testNotification"
        //设置一个通知请求
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        //将通知请求添加到发送中心
        UNUserNotificationCenter.current().add(request) { error in
            if error == nil {
                // print("Time Interval Notification scheduled: \(requestIdentifier)")
                
                DispatchQueue.main.async {
                    // 主菜单加红点
                    IndexTabMenuView.getInstance().ivSideMenuIcon.pp.addDot()
                    // 侧滑菜单加数字提示
                    let msgCount = RCIM.shared()?.ex_getMessageCount() ?? 0
                    if (msgCount > 0) {
                        // 侧滑菜单加数字提示
                        IndexSideMneuViewController.getInstance().addBadge(menu: "message", badge: msgCount)
                    }
                }
            }
        }
        
        return true
    }
    
    public func getUserInfo(withUserId userId: String!, completion: ((RCUserInfo?) -> Void)!) {
        guard userId != nil else { return }
        
        MyHttpClient.requestJSON("/users/\(userId!)", method: .get) { (success, json) in
            if success, let json = json {
                let nickname = json["user"]["nickname"].stringValue
                let portrait = MyTools.avatarPath(avatar: json["user"]["avatar"].intValue, thumb: false)
                let userinfo = RCUserInfo(userId: userId, name: nickname, portrait: portrait)
                completion(userinfo)
            }
        }
    }
}

