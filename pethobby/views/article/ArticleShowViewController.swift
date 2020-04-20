//
//  ArticleShowViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/15.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import PKHUD
import WebKit
import SwiftyJSON
import WebViewWarmUper
import ImageSlideshow
import AVKit
import Alamofire

class ArticleShowViewController: BaseViewController {

    private var articleId = -1
    private var isLiked: Bool? = nil
    
    convenience init(articleId: Int) {
        self.init()
        self.articleId = articleId
    }
    
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
        // v.scrollView.bounces = true
        // 只允许webview上下滚动
        // v.scrollView.alwaysBounceVertical = true
        // 如果需要监听网页加载事件，应用以下设置
        v.navigationDelegate = self
        return v
    }()
    
    var btnIsLiked: UIButton! // 导航条收藏按钮
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // right btn
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        self.btnIsLiked = UIButton(frame: rightView.frame)
        self.btnIsLiked.setImage(UIImage(named: "icon_favorite_border"), for: .normal)
        self.btnIsLiked.tintColor = UIColor.myColorDark1
        self.btnIsLiked.addTarget(self, action: #selector(setLike_click), for: .touchUpInside)
        rightView.addSubview(self.btnIsLiked)
        self.myNavigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(customView: rightView)
        
        let htmlPath = Bundle.main.path(forResource: "article", ofType: "html")
        let url = URL(fileURLWithPath: htmlPath!)
        let request = URLRequest(url: url)
        self.webView.load(request)
                
//        let url = URL(string: "http://192.168.51.127:8080/article")
//        let request = URLRequest(url: url!)
//        self.webView.load(request)
        
        view.insertSubview(webView, at: 0)
        webView.snp.makeConstraints { (make) in
            make.top.equalTo(self.myNavigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-55)
        }
        
        txtReply.delegate = self
        txtReply.returnKeyType = UIReturnKeyType.send
        
        PKHUD.progress(userInteractionOnUnderlyingViewsEnabled: true)
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
    
    @objc func setLike_click(_ sender: UIButton) {
        if (MySession.getInstance().isLogin() == false) {
            PKHUD.toast(text: "登录后才能收藏")
            return
        }
        if (self.isLiked == nil || self.isLiked == true) {
            return
        }
        let params: Parameters = [ "aid": self.articleId, "uid": MySession.getInstance().uid ]
        MyHttpClient.requestJSON("/articles/\(self.articleId)/like", method: .put, parameters: params) { (success, json) in
            if (success) {
                DispatchQueue.main.async {
                    self.btnIsLiked.setImage(UIImage(named: "icon_favorite"), for: .normal)
                    self.btnIsLiked.tintColor = UIColor.red
                    self.btnIsLiked.imageView?.exSetClickAnimate()
                    PKHUD.toast(text: "收藏成功")
                }
            }
        }
    }
    
    override func navBarBackBtnClick() {
        PKHUD.hide(animated: false)
        super.navBarBackBtnClick()
    }
}

extension ArticleShowViewController: WKScriptMessageHandler, WKNavigationDelegate {
    // WKScriptMessageHandler . 接收js 调用
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let data = "\(message.body)".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let clientJson = JSON(data)
        // print(clientJson)
        switch clientJson["cmd"].stringValue {
            case "didLoad":
                PKHUD.hide()
            case "setLike":
                self.isLiked = clientJson["msg"].boolValue
                if (self.isLiked == true) {
                    self.btnIsLiked.setImage(UIImage(named: "icon_favorite"), for: .normal)
                    self.btnIsLiked.tintColor = UIColor.red
                }
            case "authorClick":
                let nextView = UserInfoViewController(userId: clientJson["authorId"].intValue)
                navigationController?.pushViewController(nextView, animated: true)
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
                HUD.hide()
                UIAlertController.error(message: clientJson["msg"].stringValue)
            case "token-expired":
                MyHttpClient.refreshToken {
                    let jscall = "nativeCallJs({cmd:'refreshToken',token:'\(MySession.getInstance().token)'})"
                    self.webView.evaluateJavaScript(jscall, completionHandler: nil)
                    UIAlertController.alert(message: "登录信息过期，请重试")
                }
            case "imgClick": // 图文内容图片点击
                let list = clientJson["list"].arrayValue
                let writetime = clientJson["writetime"].stringValue
                let startIndex = clientJson["startIndex"].intValue
                let vc = FullScreenSlideshowViewController()
                vc.inputs = list.map { (fileName) -> AlamofireSource in
                    let path = MyTools.ossPath(articleId: self.articleId, writeTime: writetime, fileName: fileName.stringValue)
                    return AlamofireSource(urlString: path)!
                }
                let animatedTransDelegate = ZoomAnimatedTransitioningDelegate(imageView: UIImageView(), slideshowController: vc)
                vc.transitioningDelegate = animatedTransDelegate
                vc.initialPage = startIndex
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            case "videoClick" : // 视频点击，调用原生视频播放
                let video = clientJson["videoUrl"].stringValue
                let videoURL = URL(string: video)
                let player = AVPlayer(url: videoURL!)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                playerViewController.modalPresentationStyle = .fullScreen
                self.present(playerViewController, animated: true, completion: {
                    playerViewController.player!.play()
                })
            case "richImageClick": // 富文本内容图片点击
                let list = clientJson["list"].arrayValue
                let startIndex = clientJson["startIndex"].intValue
                let vc = FullScreenSlideshowViewController()
                vc.inputs = list.map { (url) -> AlamofireSource in
                    return AlamofireSource(urlString: url.stringValue)!
                }
                let animatedTransDelegate = ZoomAnimatedTransitioningDelegate(imageView: UIImageView(), slideshowController: vc)
                vc.transitioningDelegate = animatedTransDelegate
                vc.initialPage = startIndex
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
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
        jsonData["session"] = JSON()
        jsonData["session"]["uid"].int = MySession.getInstance().uid
        jsonData["session"]["token"].string = MySession.getInstance().token
        jsonData["session"]["time"].string = MySession.getInstance().time
        jsonData["config"] = JSON()
        jsonData["config"]["api_host"].string = MyConfig.APP_APIHOST
        jsonData["config"]["oss_host"].string = MyConfig.APP_oss_host
        jsonData["device"] = JSON()
        jsonData["device"]["env"].string = "ios"
        jsonData["device"]["width"].int = Int(UIScreen.main.bounds.width)
        jsonData["device"]["version"].string = MyTools.getDeviceName()
        let jsonString = JSON(jsonData).description
        let jscall = "nativeCallJs(\(jsonString))"
        // print(jscall)
        self.webView.evaluateJavaScript(jscall, completionHandler: nil)
    }
    // WKNavigationDelegate . webview出错
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIAlertController.error(message: error.localizedDescription)
    }
}

extension ArticleShowViewController: UITextViewDelegate {
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
