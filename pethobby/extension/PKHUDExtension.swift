//
//  PKHUDExtension.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/18.
//  Copyright © 2019 倪佳. All rights reserved.
//
import PKHUD

extension PKHUD {
    static func toast(text: String) {
//        let txtView = PKHUDTextView(text: text)
//        txtView.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
//        txtView.titleLabel.textColor = UIColor.myColorLight0
//        PKHUD.sharedHUD.contentView = txtView
//        PKHUD.sharedHUD.dimsBackground = false
//        PKHUD.sharedHUD.contentView.backgroundColor = UIColor.myColorDark1
//        PKHUD.sharedHUD.show()
//        PKHUD.sharedHUD.hide(afterDelay: 1.0)
        
        HUD.flash(.label(text), delay: 0.5)
    }
    
    static func progress(userInteractionOnUnderlyingViewsEnabled: Bool = false) {
        let view = PKHUDProgressView()
        view.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        view.imageView.image = view.imageView.image?.exResize(to: CGSize(width: 40, height: 40))
        PKHUD.sharedHUD.contentView = view
        PKHUD.sharedHUD.dimsBackground = false
        PKHUD.sharedHUD.userInteractionOnUnderlyingViewsEnabled = userInteractionOnUnderlyingViewsEnabled
        PKHUD.sharedHUD.contentView.backgroundColor = UIColor.myColorDark2
        PKHUD.sharedHUD.show()
    }
    
    static func hide(animated: Bool = true) {
        PKHUD.sharedHUD.hide(animated)
    }
}
