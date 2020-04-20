//
//  CommentsBottomSheetViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/18.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import SwiftEntryKit
import WebKit
import SwiftyJSON
import WebViewWarmUper

class CommentsBottomSheetViewController: UIViewController {
    // SwiftEntryKit 半屏view弹出方式配置
    static func getEKAttributes() -> EKAttributes{
        var attributes: EKAttributes
        attributes = .bottomFloat
        
        attributes.displayDuration = .infinity
        attributes.screenBackground = .color(color: EKColor(UIColor(white: 100.0/255.0, alpha: 0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .disabled //  .edgeCrossingDisabled(swipeable: false)
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.positionConstraints.size = .init(width: .fill, height: .ratio(value: 0.75))
        attributes.positionConstraints.verticalOffset = 0
        attributes.positionConstraints.safeArea = .overridden
        
        // attributes.statusBar = .dark
        return attributes
    }
    
    // -----------------------------------------------------------------------------
    
    var articleId: Int = -1
    var authorId: Int = -1
    
    init(articleId: Int, authorId: Int) {
        super.init(nibName: nil, bundle: nil)
        
        self.articleId = articleId
        self.authorId = authorId
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ----------------------------------------------------------
    @IBOutlet weak var lblReplyTo: UILabel!
    @IBOutlet weak var txtReply: UITextView!
    @IBOutlet weak var lblReplyToHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBgBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBgHeightConstraint: NSLayoutConstraint!
    
    lazy var webView: WKWebView = {
        let v = WKWebViewWarmUper.shared.dequeue()
        v.configuration.preferences.javaScriptEnabled = true
        // 提供一个给js调用的方法名
        v.configuration.userContentController.add(WeakScriptMessageDelegate(self), name: "jsCallNative")
        // 让webview翻动有回弹效果
        // v.scrollView.bounces = false
        // 只允许webview上下滚动
        // v.scrollView.alwaysBounceVertical = false
        // 如果需要监听网页加载事件，应用以下设置
        v.navigationDelegate = self
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let htmlPath = Bundle.main.path(forResource: "comment", ofType: "html")
        let url = URL(fileURLWithPath: htmlPath!)
        let request = URLRequest(url: url)
        self.webView.load(request)
        
//        let url = URL(string: "http://192.168.2.103:8080/comment")
//        let request = URLRequest(url: url!)
//        self.webView.load(request)
        
        // webview
        view.insertSubview(webView, at: 0)
        webView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-55)
        }
        
        txtReply.delegate = self
        txtReply.returnKeyType = UIReturnKeyType.send
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 软键盘事件监听
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // print("view 消失时，去除事件")
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // 是否回复主题y变量， 如果是直接点击回复框，则回复主题， 如果是客户端触发，则是回复评论
    var isReplySubject = true
    // 软键盘事件
    @objc func handleKeyboardNotification(notification: Notification) {
        let isShow = notification.name == UIResponder.keyboardWillShowNotification
        if (isShow) {
            if (MySession.getInstance().isLogin() == false) {
                self.txtReply.endEditing(false)
                UIAlertController.alert(message: "登录后回复")
                return
            }
            let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let bottom = -keyboardFrame.height + self.view.safeAreaInsets.bottom
            let height = self.getInputTextHeight(self.txtReply)
            self.inputBgBottomConstraint.constant = bottom
            self.inputBgHeightConstraint.constant = height
            self.lblReplyToHeightConstraint.constant = 20
            // 通知web打开遮罩
            self.webView.evaluateJavaScript("nativeCallJs({cmd:'setOverlay',display:true})")
        } else {
            self.inputBgBottomConstraint.constant = 0
            self.inputBgHeightConstraint.constant = 55
            self.lblReplyToHeightConstraint.constant = 0
            self.isReplySubject = true
            self.lblReplyTo.text = "回复:主题"
        }
        UIView.animate(withDuration: 0) {
            self.view.layoutIfNeeded()
        }
    }
}

extension CommentsBottomSheetViewController: WKScriptMessageHandler, WKNavigationDelegate {
    // WKScriptMessageHandler . 接收js 调用
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let data = "\(message.body)".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let clientJson = JSON(data)
        switch clientJson["cmd"].stringValue {
        case "didLoad":break;
        case "reply":
            if (MySession.getInstance().isLogin()) {
                self.isReplySubject = false
                self.lblReplyTo.text = "回复: \(clientJson["replyTo"].stringValue)"
                self.txtReply.becomeFirstResponder()
            } else {
                UIAlertController.alert(message: "登录后回复")
            }
        case "posted":
            self.txtReply.text = ""
            self.txtReply.endEditing(false)
            UIAlertController.alert(message: "提交成功")
        case "alert":
            UIAlertController.alert(message: clientJson["msg"].stringValue)
        case "error":
            UIAlertController.error(message: clientJson["msg"].stringValue)
        case "token-expired":
            MyHttpClient.refreshToken {
                let jscall = "nativeCallJs({cmd:'refreshToken',token:'\(MySession.getInstance().token)'})"
                self.webView.evaluateJavaScript(jscall, completionHandler: nil)
                UIAlertController.alert(message: "登录信息过期，请重试")
            }
//        case "goLogin":
//            SwiftEntryKit.dismiss()
//            let topVC = exGetCurrentVCBS2()
//            topVC.navigationController?.pushViewController(AuthLoginView(), animated: true)
        default:
            break
        }
    }
    // WKNavigationDelegate . 网页加载完成回调
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        var jsonData = JSON()
        jsonData["cmd"].string = "init"
        jsonData["params"] = JSON()
        jsonData["params"]["articleId"].int = self.articleId
        jsonData["params"]["authorId"].int = self.authorId
        jsonData["session"] = JSON()
        jsonData["session"]["uid"].int = MySession.getInstance().uid
        jsonData["session"]["token"].string = MySession.getInstance().token
        jsonData["session"]["time"].string = MySession.getInstance().time
        jsonData["config"] = JSON()
        jsonData["config"]["api_host"].string = MyConfig.APP_APIHOST
        jsonData["config"]["oss_host"].string = MyConfig.APP_oss_host
        jsonData["device"] = JSON()
        jsonData["device"]["env"].string = "ios"
        jsonData["device"]["version"].string = MyTools.getDeviceName()
        let jsonString = JSON(jsonData).description
        let jscall = "nativeCallJs(\(jsonString))"
        self.webView.evaluateJavaScript(jscall, completionHandler: nil)
    }
    // WKNavigationDelegate . webview出错
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIAlertController.error(message: error.localizedDescription)
    }
}

extension CommentsBottomSheetViewController: UITextViewDelegate {
    // 键盘点击发送
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") { // 发送按钮点击
            let content = textView.text.trimmingCharacters(in: .whitespaces)
            if content != "" {
                let jscall = "nativeCallJs({cmd:'postComment',content:'\(content)', isReplySubject: \(self.isReplySubject ? "true" : "false")})"
                self.webView.evaluateJavaScript(jscall)
            }
            return false
        }
        if (textView.text.count > 255){
            return false
        }
        return true
    }
    
    // 根据内容调整输入框高度
    func textViewDidChange(_ textView: UITextView) {
        self.inputBgHeightConstraint.constant = self.getInputTextHeight(textView)
    }
    
    // 登录后回复
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        // TODO
        return true
    }
    
    // 计算输入框的高度
    private func getInputTextHeight(_ textView: UITextView) -> CGFloat {
        let constrainSize = CGSize(width: textView.bounds.size.width, height: 999)
        let size = textView.sizeThatFits(constrainSize)
        var height = size.height
        if (size.height >= 130) {
            height = 130
        }
        if (size.height < 100) {
            height = 100
        }
        return height
    }
}
