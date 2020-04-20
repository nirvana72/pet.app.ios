//
//  IndexTabMyViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
protocol IndexTabMyViewControllerDalagate {
    func updateCount(index:Int, num: Int)
}

class IndexTabMyViewController: UIViewController {
    @IBOutlet weak var vMenuSubscribe: UIView!
    @IBOutlet weak var vMenuLike: UIView!
    @IBOutlet weak var vMenuFans: UIView!
    @IBOutlet weak var vMenuMy: UIView!
    
    @IBOutlet weak var svBottomMenu: UIStackView!
    private var tabbar: UITabBarController?
    
    private var currentIndex: Int = 0
    private var tabMenuCount:[Int] = [0,0,0,0] // tab计数
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup tabbar
        self.tabbar = UITabBarController()
        view.addSubview(tabbar!.view)
        tabbar!.view.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.svBottomMenu.snp.top).offset(-1)
        }
        
        let tabView1 = IndexTabMyLikeViewController()
        let tabView2 = IndexTabMySubscribeViewController()
        let tabView3 = IndexTabMyMyViewController()
        let tabView4 = IndexTabMyFansViewController()
        tabView1.dalagate = self
        tabView2.dalagate = self
        tabView3.dalagate = self
        tabView4.dalagate = self
        self.tabbar!.viewControllers = [tabView1,tabView2,tabView3,tabView4]
        self.tabbar!.tabBar.isHidden = true

        let tgrLike = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrLike.myParameters = ["index": 0]
        self.vMenuLike.addGestureRecognizer(tgrLike)
        
        let tgrSubscribe = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrSubscribe.myParameters = ["index": 1]
        self.vMenuSubscribe.addGestureRecognizer(tgrSubscribe)

        let tgrMy = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrMy.myParameters = ["index": 2]
        self.vMenuMy.addGestureRecognizer(tgrMy)
        
        let tgrFans = MyTapGestureRecognizer(target: self, action: #selector(menuAction))
        tgrFans.myParameters = ["index": 3]
        self.vMenuFans.addGestureRecognizer(tgrFans)
    }
    
    @objc func menuAction(_ sender: MyTapGestureRecognizer) {
        let index = sender.myParameters?["index"] as! Int
        
        if (self.currentIndex != index) {
            self.tabbar!.selectedIndex = index
            
            var v = self.svBottomMenu.subviews[self.currentIndex]
            var icon = v.subviews[0] as! UIImageView
            var lbl =  v.subviews[1] as! UILabel
            v.subviews[2].isHidden = true
            icon.isHidden = true
            lbl.textColor = UIColor.myColorDark1
            
            v = self.svBottomMenu.subviews[index]
            icon = v.subviews[0] as! UIImageView
            lbl =  v.subviews[1] as! UILabel
            v.subviews[2].isHidden = false
            icon.isHidden = false
            icon.exSetClickAnimate()
            lbl.textColor = UIColor.red
            
            self.currentIndex = index
        }
    }
}

extension IndexTabMyViewController: IndexTabMyViewControllerDalagate {
    func updateCount(index:Int, num: Int) {
        let v = self.svBottomMenu.subviews[index]
        let lbl = v.subviews[2] as! UILabel
        
        if (num == -1) {
            self.tabMenuCount[index] -= 1
        } else {
            self.tabMenuCount[index] = num
        }
        lbl.text = "(\(self.tabMenuCount[index]))"
    }
}
