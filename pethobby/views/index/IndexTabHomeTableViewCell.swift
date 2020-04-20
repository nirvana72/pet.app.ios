//
//  IndexTabHomeCollectionViewCell.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//


/*
 tableview cell 高度自适应
 可变高度view 的上下约束一定要确定，
 可变高度的优先级 在XIB中降级
 代码中动态改变约束的值， 即可完成高度自适应
 **/

import UIKit
import PKHUD
import SwiftEntryKit
import ImageSlideshow
import AVKit
import PopMenu

protocol IndexTabHomeCellDelegate {
    func onCellCmd(cmd: String, index: Int)
}

class IndexTabHomeTableViewCell: UITableViewCell {

    @IBOutlet weak var ivSubscribe: UIImageView!
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var lblPostAddr: UILabel!
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var ivLaud: UIImageView!
    @IBOutlet weak var ivComment: UIImageView!
    @IBOutlet weak var ivLike: UIImageView!
    @IBOutlet weak var lblLaud: UILabel!
    @IBOutlet weak var lblComment: UILabel!
    @IBOutlet weak var lblLike: UILabel!
    @IBOutlet weak var btnCommandOption: UIButton!
    @IBOutlet weak var constraintsTitleHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintsSubTitleHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintsContentViewTop: NSLayoutConstraint!
    @IBOutlet weak var constraintsContentViewHeight: NSLayoutConstraint!
    
    var delegate: IndexTabHomeCellDelegate? = nil // 提交到父组件处理cell事件
    var indexOfArray: Int = -1
    private var article: Article!
    private var viewWidth: CGFloat = UIScreen.main.bounds.width - 20 * 2
    private var labelWidth: CGFloat = UIScreen.main.bounds.width - 20 * 2 - 50 - 5
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tgrAvatar = MyTapGestureRecognizer(target: self, action: #selector(viewAction))
        tgrAvatar.myParameters = ["action": "avatar"]
        self.ivAvatar.addGestureRecognizer(tgrAvatar)
        
        let tgrTitle = MyTapGestureRecognizer(target: self, action: #selector(viewAction))
        tgrTitle.myParameters = ["action": "title"]
        self.lblTitle.addGestureRecognizer(tgrTitle)
        // self.lblSubTitle.addGestureRecognizer(tgrTitle)
        
        let tgrLaud = MyTapGestureRecognizer(target: self, action: #selector(viewAction))
        tgrLaud.myParameters = ["action": "laud"]
        self.ivLaud.superview?.addGestureRecognizer(tgrLaud)
        
        let tgrComment = MyTapGestureRecognizer(target: self, action: #selector(viewAction))
        tgrComment.myParameters = ["action": "comment"]
        self.ivComment.superview?.addGestureRecognizer(tgrComment)
        
        let tgrLike = MyTapGestureRecognizer(target: self, action: #selector(viewAction))
        tgrLike.myParameters = ["action": "like"]
        self.ivLike.superview?.addGestureRecognizer(tgrLike)
    }
    // cell 显示时由父组件调用
    func updateView(article: Article, index: Int) {
        self.article = article
        self.indexOfArray = index
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        self.ivSubscribe.isHidden = !article.subscribe
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        self.lblPostAddr.isHidden = article.postAddr == ""
        if (!self.lblPostAddr.isHidden) {
            let attch = NSTextAttachment()
            attch.image = UIImage(named: "icon_location")?.exWithTintColor(color: UIColor.myColorDark2)
            attch.bounds = CGRect(x: 0, y: -5, width: 20, height: 20)
            let str = NSAttributedString(attachment: attch)
            let attri = NSMutableAttributedString(string: article.postAddr)
            attri.insert(str, at: 0)
            self.lblPostAddr.attributedText = attri
        }
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        let avatarUrl = MyTools.avatarPath(avatar: article.avatar, thumb: true)
        self.ivAvatar.exSetImageSrc(avatarUrl)
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        self.lblTitle.text = article.title
        let lblTitleSize = self.lblTitle.sizeThatFits(CGSize(width: self.labelWidth, height: 200))
        self.constraintsTitleHeight.constant = lblTitleSize.height
        // ~~~~~~~~~~~~~~~~~~~~~~~~~
        self.lblSubTitle.text = "\(article.writeTime) | \(article.authorName)"
        let lblSubTitleSize = self.lblSubTitle.sizeThatFits(CGSize(width: self.labelWidth, height: 200))
        self.constraintsSubTitleHeight.constant = lblSubTitleSize.height
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        let allTitleHeight = lblTitleSize.height + 5 + lblSubTitleSize.height
        if (allTitleHeight > 50) { // > avatar.height
            self.constraintsContentViewTop.constant = allTitleHeight + 10
        } else {
            self.constraintsContentViewTop.constant = 50 + 10 // default ivAvatar.height + 10
        }
        // ~~~~~~~~~~~~~~~~~~~~~~~~~
        self.vContent.exRemoveAllSubview()
        if (article.type == "image") {
            self.constraintsContentViewHeight.constant = self.createImageContent()
        }
        if (article.type == "video") {
            self.constraintsContentViewHeight.constant = self.createVideoContent()
        }
        if (article.type == "rich") {
            self.constraintsContentViewHeight.constant = self.createRichContent()
        }
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        self.ivLaud.tintColor = article.lauded ? UIColor.red : UIColor.myColorDark2
        if (article.liked) {
            self.ivLike.image = UIImage(named: "icon_favorite")
            self.ivLike.tintColor = UIColor.red
        } else {
            self.ivLike.image = UIImage(named: "icon_favorite_border")
            self.ivLike.tintColor = UIColor.myColorDark2
        }
        self.lblLaud.text = String(article.lauds)
        self.lblComment.text = String(article.comments)
        self.lblLike.text = String(article.likes)
    }
    // 事件中心
    @objc func viewAction(_ sender: MyTapGestureRecognizer) {
        let action = sender.myParameters!["action"] as! String
        switch action {
        case "laud":
            if (!MySession.getInstance().isLogin()){
                PKHUD.toast(text: "请先登录")
                break
            }
            if (article.lauded) { break }
            MyHttpClient.requestJSON("/articles/\(self.article!.Id)/laud", method: .put) { (success, json) in
                if success  {
                    self.article.lauded = true
                    self.article.lauds += 1
                    self.ivLaud.tintColor = UIColor.red
                    self.ivLaud.exSetClickAnimate()
                    self.lblLaud.text = String(self.article.lauds)
                }
            }
            break
        case "like":
            if (!MySession.getInstance().isLogin()){
                PKHUD.toast(text: "请先登录")
                break
            }
            if (article.liked) { break }
            MyHttpClient.requestJSON("/articles/\(self.article.Id)/like", method: .put) { (success, json) in
                if success  {
                    self.article.liked = true
                    self.article.likes += 1
                    self.ivLike.image = UIImage(named: "icon_favorite")
                    self.ivLike.tintColor = UIColor.red
                    self.ivLike.exSetClickAnimate()
                    self.lblLike.text = String(self.article.likes)
                    PKHUD.toast(text: "收藏成功")
                }
            }
            break
        case "avatar":
            let nextView = UserInfoViewController(userId: article.authorId)
            UIViewController.exGetTopViewController()?.navigationController?.pushViewController(nextView, animated: true)
            break
        case "title":
            let nextView = ArticleShowViewController(articleId: article.Id)
            UIViewController.exGetTopViewController()?.navigationController?.pushViewController(nextView, animated: true)
            break
        case "comment":
            let commentsView = CommentsBottomSheetViewController(articleId: self.article.Id, authorId: self.article.authorId)
            SwiftEntryKit.display(entry: commentsView, using: CommentsBottomSheetViewController.getEKAttributes())
            break
        default:
            print(action)
            break
        }
    }
    
    private func createImageContent() -> CGFloat {
        var heightConstant: CGFloat = 100
        let space: CGFloat = 5
        var imgSize:CGSize!
        var thumb = ""
        if (self.article.images.count == 1) {
            let w = self.viewWidth
            let h = w * 18 / 30
            imgSize = CGSize(width: w, height: h)
            heightConstant = h
            thumb = MyTools.AliOssThumb.img1.toString()
        }
        if (self.article.images.count == 2) {
            let w = (self.viewWidth - space) / 2
            let h = w * 12 / 15
            imgSize = CGSize(width: w, height: h)
            heightConstant = h
            thumb = MyTools.AliOssThumb.img2.toString()
        }
        if (self.article.images.count >= 3) {
            let size = (self.viewWidth - space * 2) / 3
            imgSize = CGSize(width: size, height: size)
            let line = ceil(CGFloat(self.article.images.count) / 3)
            heightConstant = (line * size) + (line - 1) * space
            thumb = MyTools.AliOssThumb.img3.toString()
        }
        for (index, fileName) in self.article.images.enumerated() {
            let left = CGFloat(index % 3) * (imgSize.width + space)
            let top = floor(CGFloat(index) / 3) * (imgSize.width + space)
            let url = MyTools.ossPath(articleId: self.article.Id, writeTime: self.article.writeTime, fileName: fileName)
            let v = UIImageView()
            v.exSetImageSrc(url + thumb)
            let tabgr = MyTapGestureRecognizer(target: self, action: #selector(imageArticle_image_onclick))
            tabgr.myParameters = ["index": index, "url": url]
            tabgr.myElement = v
            v.addGestureRecognizer(tabgr)
            v.isUserInteractionEnabled = true
            
            self.vContent.addSubview(v)
            v.snp.makeConstraints { (make) in
                make.top.equalTo(top)
                make.left.equalTo(left)
                make.height.equalTo(imgSize.height)
                make.width.equalTo(imgSize.width)
            }
        }
        return heightConstant
    }
    
    @objc func imageArticle_image_onclick(_ sender: MyTapGestureRecognizer) {
        let index = sender.myParameters!["index"] as! Int
        let url = sender.myParameters!["url"] as! String
        
        let imageView = sender.myElement as! UIImageView
        imageView.exSetImageSrc(url)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        let vc = FullScreenSlideshowViewController()
        vc.inputs = self.article.images.map { (fileName) -> AlamofireSource in
            let path = MyTools.ossPath(articleId: self.article.Id, writeTime: self.article.writeTime, fileName: fileName)
            return AlamofireSource(urlString: path)!
        }
        let animatedTransDelegate = ZoomAnimatedTransitioningDelegate(imageView: imageView, slideshowController: vc)
        vc.transitioningDelegate = animatedTransDelegate
        vc.initialPage = index
        vc.modalPresentationStyle = .fullScreen
        UIViewController.exGetTopViewController()?.present(vc, animated: true, completion: nil)
    }
    
    private func createVideoContent() -> CGFloat {
        let url = MyTools.ossPath(articleId: self.article.Id, writeTime: self.article.writeTime, fileName: self.article.videos[0].fname)
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.backgroundColor = .black
        v.exSetImageSrc(url + MyTools.AliOssThumb.video.toString())
        let tabgr = MyTapGestureRecognizer(target: self, action: #selector(videoArticle_video_onclick))
        tabgr.myParameters = ["video": url]
        v.addGestureRecognizer(tabgr)
        v.isUserInteractionEnabled = true
        
        self.vContent.addSubview(v)
        v.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let playIcon = UIImageView()
        playIcon.image = UIImage(named: "icon_play_circle")
        playIcon.tintColor = UIColor.white
        playIcon.alpha = 0.8
        self.vContent.addSubview(playIcon)
        playIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(50)
        }
        let durationLabel = UILabel()
        durationLabel.font = UIFont.systemFont(ofSize: 15)
        durationLabel.textColor = UIColor.white
        durationLabel.text = MyTools.durationString(duration: self.article.videos[0].duration)
        self.vContent.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(5)
        }
        return self.viewWidth * 9 / 16
    }
    
    @objc func videoArticle_video_onclick(_ sender: MyTapGestureRecognizer) {
        let video = sender.myParameters!["video"] as! String
        
        let videoURL = URL(string: video)
        let player = AVPlayer(url: videoURL!)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        UIViewController.exGetTopViewController()?.present(playerViewController, animated: true, completion: {
            playerViewController.player!.play()
        })
    }
    
    private func createRichContent() -> CGFloat {        
        let tgr = MyTapGestureRecognizer(target: self, action: #selector(viewAction))
        tgr.myParameters = ["action": "title"]
        self.vContent.addGestureRecognizer(tgr)
        
        var heightConstant: CGFloat = self.viewWidth * 9 / 16
        
        let img = UIImageView()
        self.vContent.addSubview(img)
        img.snp.makeConstraints { (v) in
            v.top.equalTo(0)
            v.left.equalTo(0)
            v.height.equalTo(heightConstant)
            v.width.equalTo(self.viewWidth)
        }
        let url = MyTools.ossPath(articleId: self.article.Id, writeTime: self.article.writeTime, fileName: self.article.images[0]) + MyTools.AliOssThumb.img1.toString()
        img.exSetImageSrc(url)
        
        let txtAbstract = UILabel()
        txtAbstract.numberOfLines = 0
        txtAbstract.textColor = UIColor.myColorDark1
        let attrStrAbstract = NSMutableAttributedString(string: self.article.abstract)
        attrStrAbstract.addAttribute(.foregroundColor, value: UIColor.myColorDark1, range: NSMakeRange(0, attrStrAbstract.length))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5 // 行间距
        attrStrAbstract.addAttribute(.paragraphStyle, value:paragraphStyle, range: NSMakeRange(0, attrStrAbstract.length))
        attrStrAbstract.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: NSMakeRange(0, attrStrAbstract.length))
        txtAbstract.attributedText = attrStrAbstract
        let txtSize = txtAbstract.sizeThatFits(CGSize(width: self.viewWidth, height: 200))
        self.vContent.addSubview(txtAbstract)
        txtAbstract.snp.makeConstraints { (make) in
            make.top.equalTo(img.snp.bottom).offset(10)
            make.left.equalTo(0)
            make.height.equalTo(txtSize.height)
            make.width.equalTo(self.viewWidth)
        }
        
        heightConstant += 10 + txtSize.height
        
        return heightConstant
    }
    
    // 命令按钮点击 显示 举报 屏蔽
    @IBAction func btnCommand_click(_ sender: UIButton) {
        var actions:[PopMenuDefaultAction] = []
        
        actions.append(PopMenuDefaultAction(title: "举报", image: nil, didSelect: { (action) in
            self.delegate?.onCellCmd(cmd: action.title!, index: self.indexOfArray)
        }))
        
        actions.append(PopMenuDefaultAction(title: "屏蔽", image: nil, didSelect: { (action) in
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0
            }) { (_) in
                self.delegate?.onCellCmd(cmd: action.title!, index: self.indexOfArray)
            }
        }))
        
        let menu = PopMenuViewController(sourceView: self.btnCommandOption, actions: actions)
        menu.shouldEnablePanGesture = false
        menu.appearance.popMenuCornerRadius = 10
        
        UIViewController.exGetTopViewController()?.present(menu, animated: true, completion: nil)
    }
}
