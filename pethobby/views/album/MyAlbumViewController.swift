//
//  MyAlbumViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/20.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Photos

class MyAlbumViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    //相簿列表项
    struct ImageAlbumItem {
        //相簿名称
        var title:String?
        //相簿内的资源
        var fetchResult:PHFetchResult<PHAsset>
    }
    //显示相簿列表项的表格
    @IBOutlet weak var tblAlbum: UITableView!
    // 自定义导航栏 取消
    @IBAction func onNavCancel(_ sender: UIBarButtonItem) {
        self.deletate?.onDismiss()
    }
    //相簿列表项集合
    var items:[ImageAlbumItem] = []
    
    var deletate: MyAlbumTabDeletate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tblAlbum.delegate = self
        self.tblAlbum.dataSource = self
        self.tblAlbum.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tblAlbum.tableFooterView = UIView.init(frame: .zero)
        
        //申请权限
        PHPhotoLibrary.requestAuthorization({ (status) in
            if status != .authorized {
                return
            }
            
            // 列出所有系统的智能相册
            let smartOptions = PHFetchOptions()
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                      subtype: .albumRegular,
                                                                      options: smartOptions)
            self.convertCollection(collection: smartAlbums)
            
            //列出所有用户创建的相册
            let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
            self.convertCollection(collection: userCollections as! PHFetchResult<PHAssetCollection>)
            
            //相册按包含的照片数量排序（降序）
            self.items.sort { (item1, item2) -> Bool in
                return item1.fetchResult.count > item2.fetchResult.count
            }
            
            //异步加载表格数据,需要在主线程中调用reloadData() 方法
            DispatchQueue.main.async{
                self.tblAlbum.reloadData()
                
                //首次进来后直接进入第一个相册图片展示页面（相机胶卷）
//                if let imageCollectionVC = self.storyboard?
//                    .instantiateViewController(withIdentifier: "hgImageCollectionVC")
//                    as? HGImageCollectionViewController{
//                    imageCollectionVC.title = self.items.first?.title
//                    imageCollectionVC.assetsFetchResults = self.items.first?.fetchResult
//                    imageCollectionVC.completeHandler = self.completeHandler
//                    imageCollectionVC.maxSelected = self.maxSelected
//                    self.navigationController?.pushViewController(imageCollectionVC,
//                                                                  animated: false)
//                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.selectionStyle = .none // uitableview cell 选中背景不变色
        cell.accessoryType = .disclosureIndicator // cell 右侧箭头样式
        
        let item = self.items[indexPath.row]
        let tit = item.title ?? "未知"
        let txt = NSMutableAttributedString(string:"\(tit)  ")
        let statusAttrs = [NSAttributedString.Key.foregroundColor : UIColor.myColorDark2]
        txt.append(NSMutableAttributedString(string:"(\(item.fetchResult.count))", attributes:statusAttrs))
        cell.textLabel?.attributedText = txt
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.deletate?.onShowAlbumDetail(title: item.title ?? "未知", fetchResults: item.fetchResult)
    }
    
    //转化处理获取到的相簿
    private func convertCollection(collection:PHFetchResult<PHAssetCollection>){
        for i in 0..<collection.count{
            //获取出当前相簿内的图片
            let resultsOptions = PHFetchOptions()
            resultsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            resultsOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            
            let c = collection[i]
            let assetsFetchResult = PHAsset.fetchAssets(in: c , options: resultsOptions)
            //没有图片的空相簿不显示
            if assetsFetchResult.count > 0 {
                let title = self.deletate?.titleOfAlbumForChinse(title: c.localizedTitle)
                items.append(ImageAlbumItem(title: title, fetchResult: assetsFetchResult))
            }
        }
    }
}
