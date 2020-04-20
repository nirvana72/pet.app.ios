//
//  BaseViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/13.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import SnapKit

class BaseViewController: UIViewController {
    
    private var isPresentView:Bool = false
    // 自定义导航栏
    var myNavigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.myColorLight1
        // 判断当前viewcontroller是push还是present的方式显示的
        if (navigationController?.viewControllers.last != self) {
            self.isPresentView = true
        }
        
        self.myNavigationBar = BaseViewController.createNavBar(title: self.title ?? "", isPresentView: self.isPresentView, delegate: self)
        view.addSubview(myNavigationBar)
        myNavigationBar.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    @objc func navBarBackBtnClick() {
        if self.isPresentView {
            self.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // 点击空白处收起键盘
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    static func createNavBar(title: String, isPresentView: Bool, delegate: UINavigationBarDelegate) -> UINavigationBar{
        let bar = UINavigationBar()
        bar.barTintColor = UIColor.myColorLight0
        bar.isTranslucent = false
        bar.delegate = delegate
        let navItem = UINavigationItem(title: title)
        if isPresentView {
            navItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: nil, action: #selector(navBarBackBtnClick))
        } else {
            let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            let btn = UIButton(frame: leftView.frame)
            let img = UIImage(named: "icon_arrow_left")
            btn.setImage(img, for: .normal)
            btn.tintColor = UIColor.myColorBlue
            btn.addTarget(nil, action: #selector(navBarBackBtnClick), for: .touchUpInside)
            leftView.addSubview(btn)
            navItem.leftBarButtonItem = UIBarButtonItem(customView: leftView)
        }
        bar.pushItem(navItem, animated: false)
        return bar
    }
}

// 导航条通顶
extension BaseViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
}
