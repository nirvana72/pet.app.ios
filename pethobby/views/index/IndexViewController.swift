//
//  IndexViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/13.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import SnapKit
import SideMenu
import Alamofire
import SwiftyJSON

class IndexViewController: UIViewController {
    
    private var sideMenuControllr: SideMenuNavigationController?
    private var tabbar: UITabBarController?
    private let tabbarDelegate = SwipeTabBarControllerDelegate() // 必须全局变量才起作用？
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 状态栏背景
        let statusbarBGView = UIView()
        statusbarBGView.backgroundColor = IndexTabMenuView.BackgroundColor
        view.addSubview(statusbarBGView)
        statusbarBGView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        // setup menubar
        let menu = IndexTabMenuView.getInstance()
        view.addSubview(menu)
        menu.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.height.equalTo(IndexTabMenuItem.Height)
        }
        menu.selectDelegate = self
        
        // setup tabbar
        self.tabbar = UITabBarController()
        view.addSubview(tabbar!.view)
        tabbar!.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(IndexTabMenuItem.Height)
            make.bottom.leading.trailing.equalToSuperview()
        }
        self.tabbar!.viewControllers = [
            IndexTabHomeViewController(),
            IndexTabPublishViewController(),
            IndexTabMyViewController()
        ]
        
        self.tabbar!.delegate = tabbarDelegate
        self.tabbar!.tabBar.isHidden = true
        
        self.checkVersion()
    }
    
    // 检查是否有新版本
    func checkVersion(){
        Alamofire.request("https://itunes.apple.com/cn/lookup?id=\(MyConfig.Apple_ID)", method: .get, parameters: [:])
            .responseJSON { (response) in
                if let value = response.result.value {
                    let json = JSON(value)
                    let newVersion = json["results"][0]["version"].stringValue
                    let curVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!
                    if (newVersion != curVersion) {
                        DispatchQueue.main.async {
                            AppDelegate.hasNewVersion = true
                            // 主菜单加红点
                            IndexTabMenuView.getInstance().ivSideMenuIcon.pp.addDot()
                        }
                    }
                }
        }
    }
}

extension IndexViewController: IndexTabMenuDelegate {    
    // tab 菜单点击事件
    func onTabMenuSelected(index: Int, action: String) {
        if (index < IndexTabMenuView.getInstance().menus.count) {
            self.tabbar!.selectedIndex = index
        }
        
        if (action == "sidemenu") {
            if (self.sideMenuControllr == nil) {
                let sidemenu = IndexSideMneuViewController.getInstance()
                sidemenu.hostViewController = self
                self.sideMenuControllr = SideMenuNavigationController(rootViewController: sidemenu)
                self.sideMenuControllr!.leftSide = true
                self.sideMenuControllr!.isNavigationBarHidden = true
                self.sideMenuControllr!.settings.presentationStyle = .menuSlideIn
                self.sideMenuControllr!.settings.presentationStyle.presentingEndAlpha = 0.6
                self.sideMenuControllr!.settings.statusBarEndAlpha = 0
            }
            IndexSideMneuViewController.getInstance().updateView() // 打开时，更新视图通知
            present(self.sideMenuControllr!, animated: true, completion: nil)
        }
    }
}
