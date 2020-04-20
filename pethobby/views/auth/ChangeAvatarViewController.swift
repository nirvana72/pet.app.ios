//
//  ChangeAvatarViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/16.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Photos
import PKHUD
import Alamofire
import AliyunOSSiOS

class ChangeAvatarViewController: BaseViewController {
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var avatar: Int = -1
    var hasChange: Bool = false
    var opener: UserInfoViewController? = nil
    
    init(avatar: Int) {
        super.init(nibName: nil, bundle: nil)
        self.avatar = avatar
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ---------------------------------------------------------------
    
    override func viewDidLoad() {
        self.title = "修改头像"
        super.viewDidLoad()
        
        self.myNavigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .plain, target: nil, action: #selector(save_onclick))
        
        let url = MyTools.avatarPath(avatar: self.avatar, thumb: false)
        ivAvatar.exSetImageSrc(url)
        
        let cellSize = (UIScreen.main.bounds.width - 10 * 2 - 10 * 3) / 4 // 4列，左右加3个间隔
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellSize, height: cellSize)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.footerReferenceSize = CGSize(width: UIScreen.main.bounds.width - 20, height: 100)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ChangeAvatarCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer")
    }
    
    @objc func save_onclick() {
        if self.avatar < 100 {
            if self.avatar == self.opener?.user.avatar {
                navigationController?.popViewController(animated: true)
                return
            } else {
                // print("修改了系统头像")
                self.apiSubmit()
            }
        } else {
            if !self.hasChange {
                navigationController?.popViewController(animated: true)
                return
            } else {
                // print("修改了自定义头像")
                PKHUD.progress()
                self._oss_upload(img: self.ivAvatar.image!)
            }
        }
    }
    
    private func _oss_upload(img: UIImage) {
        let provider = OSSAuthCredentialProvider(authServerUrl: MyConfig.APP_oss_stsurl)
        let client = OSSClient(endpoint: MyConfig.APP_oss_endpoint, credentialProvider: provider)

        let request = OSSPutObjectRequest()
        request.bucketName = MyConfig.APP_oss_bucket
        request.uploadingData = img.jpegData(compressionQuality: 0)!
        let groupId = Int( floor(Double(avatar) / 1000) * 1000 )
        request.objectKey = "avatar/\(groupId)/\(self.avatar).png"
        // print("request.objectKey=\(request.objectKey)")
        let task = client.putObject(request)
        task.waitUntilFinished()
        
        if (task.error != nil) {
            PKHUD.hide()
            let error: NSError = (task.error)! as NSError
            UIAlertController.error(message: error.description)
        } else {
            self.apiSubmit()
        }
    }
    
    private func apiSubmit() {
        let parameters: Parameters = [
            "key": "avatar",
            "val": self.avatar
        ]
        MyHttpClient.requestJSON("/users/", method: .put, parameters: parameters) { (success, json) in
            
            PKHUD.hide()
            
            if success  {
                // 修改session标识, 以便其它视图获取头像地刷新图片
                MySession.getInstance().time = String( Int(Date().timeIntervalSince1970) )
                MySession.getInstance().avatar = self.avatar
                MySession.getInstance().save()
                
                DispatchQueue.main.async {
                    self.opener?.updateCallBack(attrName: "avatar", attrValue: String(self.avatar))
                    UIAlertController.alert(message: "修改成功", completion: { (_) in
                        self.navigationController?.popViewController(animated: true)
                    })
                }
            }
        }
    }
    
    @objc func openAlbum() {
        if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .photoLibrary
            vc.mediaTypes = ["public.image"]
            vc.allowsEditing = false
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        }
    }
}

extension ChangeAvatarViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 34
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChangeAvatarCollectionViewCell
        cell.setupView(avatar: indexPath.row + 1)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (self.avatar != indexPath.row + 1) {
            self.avatar = indexPath.row + 1
            let url = MyTools.avatarPath(avatar: self.avatar, thumb: false)
            self.ivAvatar.exSetImageSrc(url)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath)
            let btn = MyButton(flat: true)
            btn.setTitle("打开像册", for: .normal)
            btn.backgroundColor = UIColor.myColorGreen
            btn.tintColor = UIColor.white
            btn.addTarget(self, action: #selector(openAlbum), for: .touchUpInside)
            footer.addSubview(btn)
            btn.snp.makeConstraints { (v) in
                v.center.equalToSuperview()
                v.width.equalTo(120)
                v.height.equalTo(40)
            }
            return footer
        }

        return UICollectionReusableView()
    }
}

extension ChangeAvatarViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        picker.dismiss(animated: true) {
            let img = info[UIImagePickerController.InfoKey.originalImage] as! UIImage  
            guard let size = img.jpegData(compressionQuality: 0)?.count else { return }
            if size > (1024 * 1024 * 5) {
                let s =  String(format:"%.2f", CGFloat(size) / 1024 / 1024)
                UIAlertController.alert(message: "size:[\(s)M],图片文件最多支持5M以内")
            }else {
                self.ivAvatar.image = img
                self.avatar = MySession.getInstance().uid
                self.hasChange = true
            }
            
//            let phasset = info[UIImagePickerController.InfoKey.phAsset] as! PHAsset
//
//            let imageManager = PHCachingImageManager()
//            imageManager.stopCachingImagesForAllAssets()
//
//            let opt = PHImageRequestOptions()
//            opt.isSynchronous = false // 异步
//            opt.deliveryMode = .highQualityFormat // 快速
//
//            imageManager.requestImage(
//              for: phasset
//            , targetSize: CGSize(width: 400, height: 400)
//            , contentMode: .aspectFill
//            , options: opt) {  (image, nfo) in
//                if let img = image {
//                    guard let size = img.jpegData(compressionQuality: 0)?.count else { return }
//                    if size > (1024 * 1024 * 5) {
//                        let s =  String(format:"%.2f", CGFloat(size) / 1024 / 1024)
//                        UIAlertController.alert(message: "size:[\(s)M],图片文件最多支持5M以内")
//                    }else {
//                        self.ivAvatar.image = img
//                        self.avatar = MySession.getInstance().uid
//                        self.hasChange = true
//                    }
//                }
//            }
        }
    }
}

class ChangeAvatarCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let img = UIImageView()
        img.layer.cornerRadius = (self.frame.width - 20) / 2
        img.layer.masksToBounds = true
        img.tag = 1
        self.addSubview(img)
        img.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(10)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView(avatar:Int) {
        let url = MyTools.avatarPath(avatar: avatar, thumb: true)
        let img = self.viewWithTag(1) as! UIImageView
        img.exSetImageSrc(url)
    }
}
