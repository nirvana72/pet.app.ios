//
//  IndexMenuView.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/13.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import SnapKit

protocol IndexTabMenuDelegate {
    func onTabMenuSelected(index: Int, action: String)
}

class IndexTabMenuView: UIView {
    // 一些颜色设定
    static let BackgroundColor          = UIColor.myColorLight2
    static let MenuColor                = UIColor.myColorDark2
    static let MenuActiveColor          = UIColor.myColorDark0
    // instance
    static private var instance:IndexTabMenuView? = nil
    
    static func getInstance() -> IndexTabMenuView {
        if(instance == nil) {
            instance = IndexTabMenuView()
        }        
        return instance!
    }
    
    //---------------------------------------------------
    
    var menus:[IndexTabMenuItem] = []
    var selectedMemuIndex = 0
    var selectDelegate: IndexTabMenuDelegate? = nil
    
    let svMenu: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .fillEqually
        return sv
    }()
    
    let ivSideMenuIcon: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(named: "icon_more_vert")
        v.tintColor = IndexTabMenuView.MenuActiveColor
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = IndexTabMenuView.BackgroundColor
        //---------------------------------------------------
        // add menu
        self.menus.append(IndexTabMenuItem(txt: "主页", action: "home", icon: "icon_home"))
        self.menus.append(IndexTabMenuItem(txt: "发布", action: "publish", icon: "icon_library_add"))
        self.menus.append(IndexTabMenuItem(txt: "我的", action: "my", icon: "icon_account"))
        
        self.addSubview(svMenu)
        svMenu.snp.makeConstraints { (v) in
            v.height.equalTo(IndexTabMenuItem.Height)
            v.width.equalTo(menus.count * IndexTabMenuItem.Width)
            v.centerX.equalToSuperview()
        }
        
        for (index, menu) in self.menus.enumerated() {
            svMenu.addArrangedSubview(menu)
            menu.snp.makeConstraints { (v) in
                v.height.equalToSuperview()
            }
            let tgr = MyTapGestureRecognizer(target: self, action: #selector(menu_onclick))
            tgr.myParameters = ["index": index]
            menu.addGestureRecognizer(tgr)
        }
        // 默认第一个选中
        self.menus[self.selectedMemuIndex].setActive(active: true, adimate: false)
        
        //---------------------------------------------------
        // add more button
        self.addSubview(ivSideMenuIcon)
        ivSideMenuIcon.snp.makeConstraints { (v) in
            v.size.equalTo(30)
            v.top.equalToSuperview().offset(15)
            v.trailing.equalToSuperview().inset(15)
        }
        let tgr = MyTapGestureRecognizer(target: self, action: #selector(menu_onclick))
        tgr.myParameters = ["index": 99]
        ivSideMenuIcon.addGestureRecognizer(tgr)
        ivSideMenuIcon.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func menu_onclick(_ sender: MyTapGestureRecognizer) {
        let index = sender.myParameters!["index"] as! Int
        
        if (index == 99) {
            self.ivSideMenuIcon.pp.hiddenBadge()
            selectDelegate?.onTabMenuSelected(index: index, action: "sidemenu")
        } else {
            if (self.selectedMemuIndex != index) {
                self.menus[self.selectedMemuIndex].setActive(active: false)
                self.selectedMemuIndex = index
                self.menus[index].setActive(active: true)
                let action = self.menus[index].action
                selectDelegate?.onTabMenuSelected(index: index, action: action)
            }
        }
    }
}

//-------------------------------------------------------------------------------------

class IndexTabMenuItem: UIView {
    
    static let Height: Int = 50
    static let Width: Int = 90
    
    let ivImg: UIImageView = {
        let v = UIImageView()
        v.tintColor = IndexTabMenuView.MenuColor
        return v
    }()
    
    let lbTitle: UILabel = {
        let v = UILabel()
        v.textColor = IndexTabMenuView.MenuActiveColor
        v.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        v.isHidden = true
        return v
    }()
    
    var action = ""
    
    init(txt: String, action: String, icon: String) {
        super.init(frame: CGRect.null)
        
        self.action = action
        
        ivImg.image = UIImage(named: icon)
        self.addSubview(ivImg)
        ivImg.snp.makeConstraints { (v) in
            v.top.equalToSuperview().offset(15)
            v.centerX.equalToSuperview()
            v.size.equalTo(30)
        }
        
        lbTitle.text = txt
        self.addSubview(lbTitle)
        lbTitle.snp.makeConstraints { (v) in
            v.top.equalTo(ivImg.snp.bottom)
            v.centerX.equalToSuperview()
            v.height.equalTo(20)
        }
    }
    
    func setActive(active: Bool, adimate: Bool = true) {
        if (active) {
            ivImg.snp.updateConstraints { (v) in
                v.top.equalToSuperview()
            }
            ivImg.tintColor = IndexTabMenuView.MenuActiveColor
            lbTitle.isHidden = false
        } else {
            ivImg.snp.updateConstraints { (v) in
                v.top.equalToSuperview().offset(15)
            }
            ivImg.tintColor = IndexTabMenuView.MenuColor
            lbTitle.isHidden = true
        }
        if (adimate) {
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
