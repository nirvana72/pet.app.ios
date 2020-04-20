//
//  ArticleReviewRejectDialogViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/10/10.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import SwiftEntryKit

class ArticleReviewRejectDialogViewController: UIViewController {

    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var lbl3: UILabel!
    @IBOutlet weak var txtView: UITextView!
    
    var indexPath: IndexPath!
    var opener: ArticleReviewViewController?
    
    convenience init(indexPath: IndexPath) {
        self.init()
        self.indexPath = indexPath
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.cornerRadius = 10
        txtView.layer.borderColor = UIColor.myColorLight2.cgColor
        
        let tgr1 = MyTapGestureRecognizer(target: self, action: #selector(lbl_click))
        tgr1.myParameters = ["val": lbl1.text!]
        lbl1.addGestureRecognizer(tgr1)
        
        let tgr2 = MyTapGestureRecognizer(target: self, action: #selector(lbl_click))
        tgr2.myParameters = ["val": lbl2.text!]
        lbl2.addGestureRecognizer(tgr2)
        
        let tgr3 = MyTapGestureRecognizer(target: self, action: #selector(lbl_click))
        tgr3.myParameters = ["val": lbl3.text!]
        lbl3.addGestureRecognizer(tgr3)
    }
    
    @objc func lbl_click(_ sender: MyTapGestureRecognizer) {
        let txt = sender.myParameters?["val"] as! String
        txtView.text = txt
    }
    
    @IBAction func btnReject_click(_ sender: UIButton) {
        let txt = txtView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if (txt != "") {
            self.opener?.rejectCallBack(indexPath: self.indexPath, reason: txt)
        }
    }
    
    // SwiftEntryKit 弹出方式配置
    static func getEKAttributes() -> EKAttributes{
        var attributes: EKAttributes
        attributes = .float
        attributes.windowLevel = .normal
        attributes.position = .center
        attributes.displayDuration = .infinity
        
        attributes.entranceAnimation = .init(translate: .init(duration: 0.65, anchorPosition: .bottom,  spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.65, anchorPosition: .top, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.65, spring: .init(damping: 1, initialVelocity: 0))))
        
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .dismiss
        
        attributes.entryBackground = .color(color: .white)
        attributes.screenBackground = .color(color: EKColor(UIColor(white: 100.0/255.0, alpha: 0.3)))

        attributes.border = .value(color: UIColor(white: 0.6, alpha: 1), width: 1)
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 3))
        attributes.scroll = .enabled(swipeable: false, pullbackAnimation: .jolt)
        attributes.statusBar = .light
        
        attributes.positionConstraints.keyboardRelation = .bind(offset: .init(bottom: 15, screenEdgeResistance: 0))
        attributes.positionConstraints.size = .init(width: .constant(value: 300), height: .constant(value: 300))

        // attributes.statusBar = .dark
        return attributes
    }
}
