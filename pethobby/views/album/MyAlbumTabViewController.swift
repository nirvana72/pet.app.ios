//
//  MyAlbumTabViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/20.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Photos

protocol MyAlbumTabDeletate {
    func getMaxCount() -> Int
    func onDismiss()
    func onShowAlbum()
    func onShowAlbumDetail(title: String, fetchResults: PHFetchResult<PHAsset>?)    
    func titleOfAlbumForChinse(title:String?) -> String
    func onSubmit(assets:[PHAsset])
}

class MyAlbumTabViewController: UIViewController, MyAlbumTabDeletate {
    
    private var tabbar: UITabBarController?
    private let tabbarDelegate = SwipeTabBarControllerDelegate() // 必须全局变量才起作用？
    private let albumView = MyAlbumViewController()
    private let albumDetailView = MyAlbumDetailViewController()
    //照片选择完毕后的回调
    private var completeHandler:((_ assets:[PHAsset])->())?
    private var maxCount:Int = 0
    
    init(max: Int, completeHandler:((_ assets:[PHAsset])->())?) {
        super.init(nibName: nil, bundle: nil)
        self.completeHandler = completeHandler
        self.maxCount = max
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tabbar
        self.tabbar = UITabBarController()
        view.addSubview(tabbar!.view)
        tabbar!.view.snp.makeConstraints { (v) in
            v.edges.equalToSuperview()
        }
       
        albumView.deletate = self
        albumDetailView.deletate = self
        self.tabbar!.viewControllers = [ albumView, albumDetailView ]
        
        self.tabbar!.delegate = tabbarDelegate
        self.tabbar!.tabBar.isHidden = true
    }
    
    func getMaxCount() -> Int {
        return self.maxCount
    }
    
    func onShowAlbum() {
        self.tabbar!.selectedIndex = 0
    }
    
    func onShowAlbumDetail(title: String, fetchResults: PHFetchResult<PHAsset>?) {
        albumDetailView.updateViews(title: title, fetchResults: fetchResults)
        self.tabbar!.selectedIndex = 1
    }
    
    func onDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //由于系统返回的相册集名称为英文，我们需要转换为中文
    func titleOfAlbumForChinse(title: String?) -> String {
        if title == "Slo-mo" {
            return "慢动作"
        } else if title == "Recently Added" {
            return "最近添加"
        } else if title == "Favorites" {
            return "个人收藏"
        } else if title == "Recently Deleted" {
            return "最近删除"
        } else if title == "Videos" {
            return "视频"
        } else if title == "All Photos" {
            return "所有照片"
        } else if title == "Selfies" {
            return "自拍"
        } else if title == "Screenshots" {
            return "屏幕快照"
        } else if title == "Camera Roll" {
            return "相机胶卷"
        }
        return title ?? "未知"
    }
    
    func onSubmit(assets: [PHAsset]) {
        self.dismiss(animated: true) {
            self.completeHandler?(assets)
        }        
    }
}
