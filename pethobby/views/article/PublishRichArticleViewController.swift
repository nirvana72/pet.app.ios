//
//  PublishRichArticleViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/18.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import SnapKit
import WebKit
import PKHUD
import SwiftyJSON
import WebViewWarmUper

class PublishRichArticleViewController: BaseViewController, WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate {

    lazy var webView: WKWebView = {
        let v = WKWebViewWarmUper.shared.dequeue()
        v.configuration.preferences.javaScriptEnabled = true
        // 提供一个给js调用的方法名
        v.configuration.userContentController.add(WeakScriptMessageDelegate(self), name: "jsCallNative")
        // 让webview翻动有回弹效果
        v.scrollView.bounces = false
        // 只允许webview上下滚动
        v.scrollView.alwaysBounceVertical = false
        v.scrollView.isScrollEnabled = false
        // 如果需要监听网页加载事件，应用以下设置
        v.navigationDelegate = self
        // UIScrollViewDelegate 禁止弹出软键盘时，网页向上顶起
        v.scrollView.delegate = self
        return v
    }()
    
    private var webViewBottomConstraint: Constraint!
    
    override func viewDidLoad() {
        self.title = "发布长贴"
        super.viewDidLoad()
        
        let htmlPath = Bundle.main.path(forResource: "richeditor", ofType: "html")
        let url = URL(fileURLWithPath: htmlPath!)
        let request = URLRequest(url: url)
        self.webView.load(request)

//        let url = URL(string: "http://192.168.51.127:8080/richeditor")
//        let request = URLRequest(url: url!)
//        self.webView.load(request)
        
        view.addSubview(webView)
        webView.snp.makeConstraints { (v) in
            v.top.equalTo(self.myNavigationBar.snp.bottom).offset(1)
            v.left.right.equalToSuperview()
            self.webViewBottomConstraint = v.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
    
    @objc func handleKeyboardNotification(notification: Notification) {
        // 软键盘弹出时，调整输入框的高度，以防底部输入情况下页面看不见只能盲打
        let isShow = notification.name == UIResponder.keyboardWillShowNotification
        if (isShow) {
            let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let bottom = -keyboardFrame.height + self.view.safeAreaInsets.bottom
            self.webViewBottomConstraint.update(offset: bottom + 55)
        } else {
            self.webViewBottomConstraint.update(offset: 0)
        }
    }
    // UIScrollViewDelegate 禁止弹出软键盘时，网页向上顶起
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.bounds = self.webView.bounds
    }
    // WKScriptMessageHandler . 接收js调用方法
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // print("message.name=\(message.name), message.body=\(message.body)")
        let data = "\(message.body)".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let clientJson = JSON(data)
        switch clientJson["cmd"].stringValue {
        case "alert":
            UIAlertController.alert(message: clientJson["msg"].stringValue)
        case "error":
            HUD.hide()
            UIAlertController.error(message: clientJson["msg"].stringValue)
        case "token-expired":
            MyHttpClient.refreshToken {
                let jscall = "nativeCallJs({cmd:'refreshToken',token:'\(MySession.getInstance().token)'})"
                self.webView.evaluateJavaScript(jscall, completionHandler: nil)
                UIAlertController.alert(message: "登录信息过期，请重试")
            }
        case "progress":
            let message = clientJson["msg"].stringValue
            if message == "close" {
                HUD.hide()
            } else {
                HUD.show(.label(message))
            }
        case "success":
            UIAlertController.alert(message: "发布成功") { (_) in
                self.dismiss(animated: true, completion: nil)
            }
        default:
            break
        }
    }
    // WKNavigationDelegate . 网页加载完成回调
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        var jsonData = JSON()
        jsonData["cmd"].string = "init"
        jsonData["session"] = JSON()
        jsonData["session"]["uid"].int = MySession.getInstance().uid
        jsonData["session"]["token"].string = MySession.getInstance().token
        jsonData["session"]["time"].string = MySession.getInstance().time
        jsonData["config"] = JSON()
        jsonData["config"]["api_host"].string = MyConfig.APP_APIHOST
        jsonData["config"]["oss_accessKeyId"].string = MyConfig.APP_oss_accessKeyId
        jsonData["config"]["oss_accessKeySecret"].string = MyConfig.APP_oss_accessKeySecret
        jsonData["config"]["oss_bucket"].string = MyConfig.APP_oss_bucket
        jsonData["config"]["oss_region"].string = MyConfig.APP_oss_region
        jsonData["config"]["oss_host"].string = MyConfig.APP_oss_host
        jsonData["device"] = JSON()
        jsonData["device"]["env"].string = "ios"
        jsonData["device"]["version"].string = MyTools.getDeviceName()
        let jsonString = JSON(jsonData).description
        
        let jscall = "nativeCallJs(\(jsonString))"
        self.webView.evaluateJavaScript(jscall, completionHandler: nil)
    }
    // WKNavigationDelegate . 网页加载出错
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIAlertController.error(message: error.localizedDescription)
    }
    
    override func navBarBackBtnClick() {
        UIAlertController.confirm(message: "退出将不会保存你的编辑内容，确定要退出么") { (_) in
            super.navBarBackBtnClick()
        }
    }
}
