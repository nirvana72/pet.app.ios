//
//  UserInfoUpdateViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/17.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Foundation
import UIKit
import PKHUD
import Alamofire

class UserInfoUpdateViewController: BaseViewController {
    private var attrName: String = ""
    private var attrValue: String = ""
    private let profileMaxLength = 128
    
    var opener: UserInfoViewController? = nil
    
    init(attrName: String, attrNameCn: String, attrValue: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = attrNameCn
        self.attrName = attrName
        self.attrValue = attrValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //------------------------------------------------------------
    
    let txtField: UITextField = {
        let v = UITextField()
        v.borderStyle = .roundedRect
        return v
    }()
    
    let txtView: UITextView = {
        let v = UITextView()
        v.layer.cornerRadius = 5
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.myColorLight2.cgColor
        v.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.attrName == "profile" {
            txtView.text = self.attrValue
            view.addSubview(txtView)
            txtView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(20)
                make.top.equalToSuperview().offset(120)
                make.height.equalTo(100)
            }
        } else {
            txtField.text = self.attrValue
            view.addSubview(txtField)
            txtField.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(20)
                make.top.equalToSuperview().offset(120)
                make.height.equalTo(45)
            }
        }
        
        let btn = MyButton()
        btn.backgroundColor = UIColor.orange
        btn.tintColor = UIColor.white
        btn.setTitle("确定", for: .normal)
        btn.addTarget(nil, action: #selector(btn_tapped), for: .touchUpInside)
        view.addSubview(btn)
        btn.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(20)
            if self.attrName == "profile" {
                make.top.equalTo(txtView.snp.bottom).offset(15)
            } else {
                make.top.equalTo(txtField.snp.bottom).offset(15)
            }
            make.height.equalTo(45)
        }
    }
    
    @objc private func btn_tapped(_ sender: UIButton) {
        var val = ""
        if self.attrName == "profile" {
            val = txtView.text ?? ""
        } else {
            val = txtField.text ?? ""
        }
        
        // 未作修改
        if val == self.attrValue {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        let parameters: Parameters = [
            "key": self.attrName,
            "val": val
        ]
        PKHUD.progress()
        MyHttpClient.requestJSON("/users/", method: .put, parameters: parameters) { (success, json) in
            PKHUD.hide()
            if success  {                
                self.opener?.updateCallBack(attrName: self.attrName, attrValue: val)
                UIAlertController.alert(message: "修改成功", completion: { (_) in
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
}
