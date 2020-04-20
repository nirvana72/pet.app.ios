//
//  PublishImageArticleViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/18.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Photos
import PKHUD
import ImageSlideshow
import Alamofire
import AliyunOSSiOS

class PublishImageArticleViewController: BaseViewController {
    
    struct OssModule {
        var Id:Int = -1
        var writetime:String = ""
        var selectedImgs:[UIImage] = []
        var ossImgs:[String] = []
    }
    
    @IBOutlet weak var txtContent: UITextView!
    @IBOutlet weak var vImagesContent: UIView!
    @IBOutlet weak var vImagesContentHeightConstraint: NSLayoutConstraint!
    @IBOutlet var vAddImage: UIView!
    
    private let imgSpace: CGFloat = 5
    private var imgSize: CGFloat!
    private var module = OssModule()
    
    override func viewDidLoad() {
        self.title = "发布图文"
        super.viewDidLoad()
        
        self.imgSize = (UIScreen.main.bounds.width - 20 * 2 - self.imgSpace * 2) / 3
        // 输入框边框
        self.txtContent.layer.borderColor = UIColor.myColorLight2.cgColor
        // 虚线边框
        self.vAddImage.exAddDashBorder(color: UIColor.myColorLight2, frameSize: CGSize(width: self.imgSize, height: self.imgSize))
        // 点击事件
        let tgr = UITapGestureRecognizer(target: self, action: #selector(addImage_onclick))
        self.vAddImage.addGestureRecognizer(tgr)
        self.vAddImage.isUserInteractionEnabled = true
        
        self.setupImages()
    }
    
    private func setupImages() {
        vImagesContent.exRemoveAllSubview()
        
        for (index, img) in self.module.selectedImgs.enumerated() {
            let left = CGFloat(index % 3) * (self.imgSize + self.imgSpace)
            let top = floor(CGFloat(index) / 3) * (self.imgSize + self.imgSpace)
            let v = UIImageView()
            v.backgroundColor = UIColor.myColorDark3
            let tgr = MyTapGestureRecognizer(target: self, action: #selector(img_click))
            tgr.myParameters = ["index": index]
            v.addGestureRecognizer(tgr)
            v.isUserInteractionEnabled = true
            v.contentMode = .scaleAspectFill
            v.clipsToBounds = true
            v.image = img
            
            let btn = UIButton()
            btn.setImage(UIImage(named: "icon_cancel"), for: .normal)
            btn.tintColor = .red
            v.addSubview(btn)
            btn.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(2)
                make.right.equalToSuperview().inset(2)
                make.size.equalTo(25)
            }
            btn.tag = index
            btn.addTarget(self, action: #selector(btnImageCancel_onclick), for: .touchUpInside)
            
            self.vImagesContent.addSubview(v)
            v.snp.makeConstraints { (make) in
                make.top.equalTo(top)
                make.left.equalTo(left)
                make.size.equalTo(self.imgSize)
            }
        }
        // 如果图片不满9张，生成添加按钮
        if self.module.selectedImgs.count < 9 {
            let left = CGFloat(self.module.selectedImgs.count % 3) * (self.imgSize + self.imgSpace)
            let top = floor(CGFloat(self.module.selectedImgs.count) / 3) * (self.imgSize + self.imgSpace)
            self.vImagesContent.addSubview(self.vAddImage)
            self.vAddImage.snp.removeConstraints()
            self.vAddImage.snp.makeConstraints { (v) in
                v.top.equalTo(top)
                v.left.equalTo(left)
                v.size.equalTo(self.imgSize)
            }
            // 一张图都没选，添加说明文字
            if self.module.selectedImgs.count == 0 {
                let lbl = UILabel()
                lbl.textColor = UIColor.myColorDark2
                lbl.font = UIFont.systemFont(ofSize: 14)
                lbl.text = "图片文件最多支持5M以内"
                self.vImagesContent.addSubview(lbl)
                lbl.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.vAddImage.snp.trailing).offset(20)
                    make.centerY.equalTo(self.vAddImage)
                }
            }
        }
        
        // 计算出所需高度
        let cells = self.module.selectedImgs.count < 9 ? self.module.selectedImgs.count + 1 : 9
        let line = ceil(CGFloat(cells) / 3)
        let height = (line * self.imgSize) + (line - 1) * self.imgSpace
        self.vImagesContentHeightConstraint.constant = height
       
    }
    // 打开像册
    @objc func addImage_onclick(_ sender: UITapGestureRecognizer) {
        let max = 9 - self.module.selectedImgs.count
        if (max <= 0) { return }
        let picker = MyAlbumTabViewController(max: max) { (assets) in
            for _ in 1...assets.count {
                self.module.selectedImgs.append(UIImage.init()) // 先置空，后按排序下标赋值
            }
            self.setupImages() // 先生成UIImageView，延时加载图片
            
            let imageManager = PHCachingImageManager()
            imageManager.stopCachingImagesForAllAssets()
            
//            let targetSize = CGSize(width: self.imgSize * UIScreen.main.scale,
//                                    height: self.imgSize * UIScreen.main.scale)
            let opt = PHImageRequestOptions()
            opt.isSynchronous = false // 异步
            opt.deliveryMode = .highQualityFormat // 快速
            
            for (index, asset) in assets.enumerated() {
                imageManager.requestImage(
                    for: asset
                    , targetSize: PHImageManagerMaximumSize // targetSize
                    , contentMode: .aspectFill
                    , options: opt) {  (image, nfo) in
                        if let img = image {
                            let order = self.module.selectedImgs.count - assets.count + index
                            guard let size = img.jpegData(compressionQuality: 0)?.count else { return }
                            if size > (1024 * 1024 * 5) {
                                let s =  String(format:"%.2f", CGFloat(size) / 1024 / 1024)
                                PKHUD.toast(text: "size:[\(s)M],图片文件最多支持5M以内")
                            }else {
                                self.module.selectedImgs[order] = img
                                let imgV = self.vImagesContent.subviews[order] as! UIImageView
                                imgV.image = img
                            }
                        }
                    }
            }
        }
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }
    // 移除图片
    @objc func btnImageCancel_onclick(_ sender: UIButton) {
        let imageView = self.vImagesContent.subviews[sender.tag]
        UIView.animate(withDuration: 0.5, animations: {
            imageView.alpha = 0
        }) { (_) in
            self.module.selectedImgs.remove(at: sender.tag)
            self.setupImages()
        }
    }
    // 显示图集
    @objc func img_click(_ sender: MyTapGestureRecognizer) {
        let index = sender.myParameters!["index"] as! Int
        let imgV = self.vImagesContent.subviews[index] as! UIImageView
        let vc = FullScreenSlideshowViewController()
        vc.inputs = self.module.selectedImgs.map { (img) -> LocalImageSource in
            return LocalImageSource(img: img)
        }
        let animatedTransDelegate = ZoomAnimatedTransitioningDelegate(imageView: imgV, slideshowController: vc)
        vc.transitioningDelegate = animatedTransDelegate
        vc.initialPage = index
        vc.modalPresentationStyle = .fullScreen
        UIViewController.exGetTopViewController()?.present(vc, animated: true, completion: nil)
    }
    // 发布
    @IBAction func btnSubmit_onclick(_ sender: UIButton) {
        if self.module.selectedImgs.count < 1 {
            UIAlertController.alert(message: "请至少选择一张图片")
            return
        }
        
        if self.txtContent.text.trimmingCharacters(in: .whitespaces) == "" {
            UIAlertController.alert(message: "写点什么吧...")
            return
        }
        
        HUD.show(.label("正在发布。。。"))
        
        let parameters: Parameters = [
            "title": self.txtContent.text.trimmingCharacters(in: .whitespaces),
            "type": "image"
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
        let provider = OSSAuthCredentialProvider(authServerUrl: MyConfig.APP_oss_stsurl)
        let client = OSSClient(endpoint: MyConfig.APP_oss_endpoint, credentialProvider: provider)
        
        for (index, uiimage) in self.module.selectedImgs.enumerated() {
            let request = OSSPutObjectRequest()
            request.bucketName = MyConfig.APP_oss_bucket
            let fileId = index + 1
            let ossName = "\(fileId).jpeg"
            self.module.ossImgs.append(ossName)
            request.uploadingData = uiimage.jpegData(compressionQuality: 0)!
            request.objectKey = MyTools.ossPath(articleId: self.module.Id, writeTime: self.module.writetime, fileName: ossName, withHost: false)
            // print("request.objectKey=\(request.objectKey)")
            // print("上传图片 \(fileId) / \(self.module.selectedImgs.count)")
            // 这个提示会被线程阻塞？？？？？？
//            DispatchQueue.main.async {
//                HUD.show(.label("上传图片 \(fileId) / \(self.module.selectedImgs.count)"))
//            }
            
            let task = client.putObject(request)
            task.waitUntilFinished()
        }
        self._finish_post()
    }
    
    private func _finish_post() {
        HUD.show(.label("更新发布状态"))
        // print("_finish_post")
        var mediaAry:[String] = []
        for ossName in self.module.ossImgs {
            mediaAry.append("{\"type\":\"image\",\"name\":\"\(ossName)\"}")
        }
        var medias = mediaAry.joined(separator: ",")
        medias = "[\(medias)]"
        let parameters: Parameters = [
            "medias": medias // [{"type":"image","name":"1.jpeg"},...]
        ]
        // print(medias)
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
