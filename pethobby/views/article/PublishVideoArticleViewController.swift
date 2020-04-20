//
//  PublishVideoArticleViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/18.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Photos
import PKHUD
import AVKit
import Alamofire
import AliyunOSSiOS

class PublishVideoArticleViewController: BaseViewController {

    struct OssModule {
        var Id:Int = -1
        var writetime:String = ""
        var avAsset:AVAsset? = nil
        var thumbnail:UIImage? = nil
        var duration:Int = 0
        var size:Int = 0
        var ossName:String = ""
    }
    
    @IBOutlet weak var txtContent: UITextView! // 正文输入框
    @IBOutlet weak var vImagesContent: UIView! // 中间可变高度uiview
    @IBOutlet weak var vImagesContentHeightConstraint: NSLayoutConstraint!
    @IBOutlet var vAddImage: UIView! // 添加视频按钮
    
    private let imgSize: CGSize = { // 添加视频按钮尺寸
        let margin: CGFloat = 20
        let space: CGFloat = 10
        var size = (UIScreen.main.bounds.width - margin * 2 - space * 2) / 3
        if (size > 100) { size = 100 }
        return CGSize(width: size, height: size)
    }()
    
    private let thumbnailSize: CGSize = {  // 视频缩略图尺寸
        let width = UIScreen.main.bounds.width - 20 * 2
        let height = width * 9 / 16
        return CGSize(width: width, height: height)
    }()
    
    private var module = OssModule()
    
    override func viewDidLoad() {
        self.title = "发布视频"
        super.viewDidLoad()
        // 输入框边框
        self.txtContent.layer.borderColor = UIColor.myColorLight2.cgColor
        // 虚线边框
        self.vAddImage.exAddDashBorder(color: UIColor.myColorLight2, frameSize: self.imgSize)
        // 添加视频点击事件
        let tgr = UITapGestureRecognizer(target: self, action: #selector(addVideo_onclick))
        self.vAddImage.addGestureRecognizer(tgr)
        self.vAddImage.isUserInteractionEnabled = true
        
        self.setupImages()
    }
    
    private func setupImages() {
        vImagesContent.exRemoveAllSubview()
        
        if let _ = self.module.avAsset { // 显示视频缩略图
            let thumbnail = UIImageView()
            thumbnail.contentMode = .scaleAspectFit
            thumbnail.backgroundColor = .black
            thumbnail.image = self.module.thumbnail
            let imgHeight = self.vImagesContent.frame.width * 9 / 16
            self.vImagesContent.addSubview(thumbnail)
            thumbnail.snp.makeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(imgHeight)
            }
            
            // 播放按钮
            let playIcon = UIImageView()
            playIcon.image = UIImage(named: "icon_play_circle")
            playIcon.alpha = 0.8
            playIcon.tintColor = UIColor.myColorLight0
            let tgr = UITapGestureRecognizer(target: self, action: #selector(videoPlay_click))
            playIcon.addGestureRecognizer(tgr)
            playIcon.isUserInteractionEnabled = true
            self.vImagesContent.addSubview(playIcon)
            playIcon.snp.makeConstraints { (make) in
                make.center.equalTo(thumbnail)
                make.size.equalTo(50)
            }
            
            // 时长标签
            let lblSize = UILabel()
            lblSize.textColor = UIColor.myColorDark1
            lblSize.font = UIFont.systemFont(ofSize: 13)
            let size = String(format:"%.2f", CGFloat(module.size) / 1024 / 1024)
            let duration = MyTools.durationString(duration: self.module.duration)
            lblSize.text = "时长:\(duration) / 大小:\(size)M"
            self.vImagesContent.addSubview(lblSize)
            lblSize.snp.makeConstraints { (make) in
                make.top.equalTo(thumbnail.snp.bottom).offset(5)
                make.centerX.equalTo(thumbnail)
                make.height.equalTo(30)
            }
            
            // 删除按钮
            let btnRemove = UIButton()
            btnRemove.setImage(UIImage(named: "icon_cancel"), for: .normal)
            btnRemove.tintColor = .red
            btnRemove.addTarget(nil, action: #selector(removeVideo_click), for: .touchUpInside)
            self.vImagesContent.addSubview(btnRemove)
            btnRemove.snp.makeConstraints { (make) in
                make.trailing.equalToSuperview()
                make.bottom.equalToSuperview().inset(5)
                make.size.equalTo(25)
            }
            
            self.vImagesContentHeightConstraint.constant = imgHeight + 35
            
        } else { // 显示添加按钮
            self.vImagesContent.addSubview(self.vAddImage)
            self.vAddImage.snp.removeConstraints()
            self.vAddImage.snp.makeConstraints { (v) in
                v.top.leading.equalTo(0)
                v.size.equalTo(self.imgSize)
            }
            // 说明文字
            let lbl = UILabel()
            lbl.textColor = UIColor.myColorDark2
            lbl.font = UIFont.systemFont(ofSize: 14)
            lbl.text = "视频文件最大支持100M"
            self.vImagesContent.addSubview(lbl)
            lbl.snp.makeConstraints { (make) in
                make.leading.equalTo(self.vAddImage.snp.trailing).offset(20)
                make.centerY.equalTo(self.vAddImage)
            }
            
            self.vImagesContentHeightConstraint.constant = self.imgSize.height
        }
    }
    // 删除已选视频
    @objc func removeVideo_click() {
        self.module.avAsset = nil
        self.setupImages()
    }
    // 播放视频
    @objc func videoPlay_click(_ sender:UITapGestureRecognizer) {
        if let _ = self.module.avAsset {
            let playerItem = AVPlayerItem(asset: self.module.avAsset!)
            let player = AVPlayer(playerItem: playerItem)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            UIViewController.exGetTopViewController()?.present(playerViewController, animated: true, completion: {
                playerViewController.player!.play()
            })
        }
    }
    // 添加视频，使用的是系统自带的 UIImagePickerController
    @objc func addVideo_onclick(_ sender: UITapGestureRecognizer) {
        if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .photoLibrary
            vc.mediaTypes = ["public.movie"]
            vc.allowsEditing = false
            vc.modalPresentationStyle = .fullScreen
            UIViewController.exGetTopViewController()?.present(vc, animated: true, completion: nil)
        }
    }
    // 上传
    @IBAction func btnSubmit_onclick(_ sender: UIButton) {
        if self.module.avAsset == nil {
            UIAlertController.alert(message: "未添加视频")
            return
        }
        
        if self.txtContent.text.trimmingCharacters(in: .whitespaces) == "" {
            UIAlertController.alert(message: "写点什么吧...")
            return
        }
        HUD.show(.progress)
        let parameters: Parameters = [
            "title": self.txtContent.text.trimmingCharacters(in: .whitespaces),
            "type": "video"
        ]
        MyHttpClient.requestJSON("/articles/create", method: .post, parameters: parameters) { (success, json) in
            if success, let json = json {
                self.module.Id = json["Id"].intValue
                self.module.writetime = json["writetime"].stringValue
                // print("self.module.writetime=\(self.module.writetime)")
                self._oss_upload()
            } else {
                HUD.hide()
            }
        }
    }
    private func _oss_upload() {
        if let avassetURL = self.module.avAsset as? AVURLAsset {
            guard let videoData = try? Data(contentsOf: avassetURL.url) else {
                UIAlertController.alert(message: "获取视频源数据出错")
                return
            }
            
            let provider = OSSAuthCredentialProvider(authServerUrl: MyConfig.APP_oss_stsurl)
            let client = OSSClient(endpoint: MyConfig.APP_oss_endpoint, credentialProvider: provider)
    
            let request = OSSPutObjectRequest()
            request.bucketName = MyConfig.APP_oss_bucket
    
            request.uploadingData = videoData
            request.objectKey = MyTools.ossPath(articleId: self.module.Id, writeTime: self.module.writetime, fileName: self.module.ossName, withHost: false)
            // print("request.objectKey=\(request.objectKey)")
            let task = client.putObject(request)
            task.waitUntilFinished()
            
            self._finish_post()
        }
    }
    
    private func _finish_post() {
        HUD.show(.label("更新发布状态"))
        // print("_finish_post")
        let parameters: Parameters = [
            "medias": "[{\"type\":\"video\",\"name\":\"\(self.module.ossName)\",\"duration\":\"\(self.module.duration)\"}]"
        ]
        MyHttpClient.requestJSON("/articles/\(self.module.Id)/created", method: .put, parameters: parameters) { (success, json) in
            
            HUD.hide()
            
            if success {
                UIAlertController.alert(message: "发布成功", completion: { (_) in
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
    }
}

extension PublishVideoArticleViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
//        UIImagePickerControllerMediaURL
//        UIImagePickerControllerReferenceURL
//        UIImagePickerControllerPHAsset
//        UIImagePickerControllerMediaType
        
        picker.dismiss(animated: true) {
            let url = info[UIImagePickerController.InfoKey.mediaURL] as! URL
            let avasset = AVAsset(url: url)
          
            if (avasset.isKind(of: AVURLAsset.self)) {
                let avurlasset = avasset as! AVURLAsset
                var keys = Set<URLResourceKey>()
                // keys.insert(URLResourceKey.totalFileSizeKey)
                keys.insert(URLResourceKey.fileSizeKey)
                do {
                    let URLResourceValues = try avurlasset.url.resourceValues(forKeys: keys)
//                    print("fileSize = \(URLResourceValues.fileSize)")
//                    print("totalFileSize = \(URLResourceValues.totalFileSize)")
                    let fileSize = URLResourceValues.fileSize!
                    if fileSize > (1024 * 1024 * 100) {
                        UIAlertController.alert(message: "视频文件最大支持100M")
                    } else {
                        //生成视频截图
                        let generator = AVAssetImageGenerator(asset: avasset)
                        generator.appliesPreferredTrackTransform = true
                        let time = CMTimeMakeWithSeconds(0.0,preferredTimescale: 600)
                        var actualTime:CMTime = CMTimeMake(value: 0,timescale: 0)
                        let imageRef:CGImage = try! generator.copyCGImage(at: time, actualTime: &actualTime)
                        let frameImg = UIImage(cgImage: imageRef)
                        
                        self.module.avAsset = avasset
                        self.module.thumbnail = frameImg
                        self.module.duration = lroundf(Float(avasset.duration.seconds))
                        self.module.size = fileSize
                        let ary = url.absoluteString.split(separator: ".")
                        self.module.ossName = "1.\(ary.last!.lowercased())"
                        self.setupImages()
                    }
                } catch let err {
                    UIAlertController.alert(message: "出错了：\(err.localizedDescription)")
                }
            } else {
                UIAlertController.alert(message: "出错了")
            }
        }
    }
}


