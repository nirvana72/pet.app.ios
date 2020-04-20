//
//  MyImagePickerViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/20.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Photos
import ImageSlideshow

class MyAlbumDetailViewController: UIViewController {
    
    @IBOutlet weak var navBarItem: UINavigationItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblSelectedCount: UILabel!
    
    // 返回相簿
    @IBAction func navToAlbum(_ sender: UIButton) {
        self.deletate?.onShowAlbum()
    }
    // 取消
    @IBAction func navCancel(_ sender: UIBarButtonItem) {
        self.deletate?.onDismiss()
    }
    // 完成
    @IBAction func btnSubmit(_ sender: UIButton) {
        var assets: [PHAsset] = []
        for index in self.selectedIndex {
            if let asset = self.assetsFetchResults?[index] {
                assets.append(asset)
            }
        }
        if (assets.count > 0) {
            self.deletate?.onSubmit(assets: assets)
        }
        else {
            self.deletate?.onDismiss()
        }
    }
    
    let column:CGFloat = 3 // 几列展示
    let space:CGFloat = 5 // 展示间距
    lazy var itemSize: CGSize = { // 生成cell缩略图时要用，所以全局
        let cellSize = (UIScreen.main.bounds.width - self.space * (self.column - 1)) / self.column
        return CGSize(width: cellSize, height: cellSize)
    }()
     // 父TAB视图的代理对像
    var deletate: MyAlbumTabDeletate? = nil
    //取得的资源结果，用了存放的PHAsset ，由父TAB视图传入
    var assetsFetchResults:PHFetchResult<PHAsset>?
    //带缓存的图片管理对象
    var imageManager:PHCachingImageManager!
    //记住选中的下标
    var selectedIndex:[Int] = []
    // 检查选中的下标数组是否存在值， 返回下标
    private func selectedIndexHasValue(val: Int) -> Int {
        for (i, v) in self.selectedIndex.enumerated() {
            if val == v {
                return i
            }
        }
        return -1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //初始化和重置缓存
        self.imageManager = PHCachingImageManager()
        //重置缓存
        self.imageManager.stopCachingImagesForAllAssets()
        // ------------------------------------------------
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = self.itemSize
        layout.minimumLineSpacing = self.space // 行间隔
        layout.minimumInteritemSpacing = self.space // 列间隔
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(UINib(nibName: "MyAlbumDetailViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        // ------------------------------------------------
        self.lblSelectedCount.text = "0 / \(self.deletate!.getMaxCount())"
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navBarItem.title = self.title
    }
    // 显示的时候由父TAB视图调用，生成视图
    func updateViews(title: String, fetchResults: PHFetchResult<PHAsset>?) {
        self.title = title
        if (self.assetsFetchResults != fetchResults) {
            // 是否第一次加载视图
            let firstLoad = self.assetsFetchResults == nil
            self.assetsFetchResults = fetchResults
            if (!firstLoad) { // 如果不是第一次加载， 刷新collectionView
                self.selectedIndex = []
                self.lblSelectedCount.text = "0 / \(self.deletate!.getMaxCount())"
                self.collectionView.reloadData()
            }
        }
    }
}

extension MyAlbumDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, MyAlbumDetialViewCellDelegate {
    // MyAlbumDetialViewCellDelegate cell 自定义事件
    func onSelected(index: Int, selectd: Bool) -> Int {
        let maxCount = self.deletate!.getMaxCount()  // 可选数量由父TAB视图提供
        if (selectd == true) { // 选择
            if (self.selectedIndex.count >= maxCount) {
                UIAlertController.alert(message: "你最多可以选 \(maxCount) 张照片")
                return -1
            } else{
                if (self.selectedIndexHasValue(val: index) >= 0) {
                    return -1 // 已存在
                }
                self.selectedIndex.append(index)
            }
        } else { // 撤选
            let valIndex = self.selectedIndexHasValue(val: index)
            if (valIndex >= 0) {
                self.selectedIndex.remove(at: valIndex)
                //撤选最后一个时，不用更新状态， 否则更新下标之后的那些CELL，主要是更新数字排序
                if (valIndex < self.selectedIndex.count) {
                    var indexPaths: [IndexPath] = []
                    for itm in valIndex...self.selectedIndex.count - 1 {
                        indexPaths.append(IndexPath(row: self.selectedIndex[itm], section: 0))
                    }
                    self.collectionView.reloadItems(at: indexPaths)
                }
            }
        }
        self.lblSelectedCount.text = "\(self.selectedIndex.count) / \(maxCount)"
        return self.selectedIndex.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assetsFetchResults?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MyAlbumDetialViewCell
        if (cell.dalagate == nil) {
            cell.dalagate = self
        }
        let asset = self.assetsFetchResults![indexPath.row]
        let selectedIndex = self.selectedIndexHasValue(val: indexPath.row) // 是否已选
        let size = self.itemSize.width * UIScreen.main.scale
        //获取缩略图
        self.imageManager.requestImage(
              for: asset
            , targetSize: CGSize(width: size, height: size)
            , contentMode: .aspectFit
            , options: .none) {  (image, nfo) in
            
            cell.setupViews(index: indexPath.row, image: image, order: selectedIndex + 1)
        }
        
        return cell
    }
}

protocol MyAlbumDetialViewCellDelegate {
    func onSelected(index: Int, selectd: Bool) -> Int
}

class MyAlbumDetialViewCell: UICollectionViewCell {
    var mIndex: Int = -1
    var mSelected: Bool = false
    var mEnable: Bool = true
    var dalagate: MyAlbumDetialViewCellDelegate? = nil
    
    @IBOutlet weak var imgV: UIImageView!
    @IBOutlet weak var iconSelected: UIView!
    @IBOutlet weak var lblOrder: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgV.contentMode = .scaleAspectFill
        imgV.clipsToBounds = true
        
        let tgr_imgV = UITapGestureRecognizer(target: self, action: #selector(img_click))
        imgV.addGestureRecognizer(tgr_imgV)
    }
    
    func setupViews(index: Int, image: UIImage?, order: Int) {
        self.mIndex = index
        self.mEnable = image != nil
        self.mSelected = order > 0
        self.iconSelected.isHidden = true
        self.imgV.alpha = 0.7
        
        if (self.mEnable) {
            self.imgV.image = image
            if (self.mSelected) {
                self.iconSelected.isHidden = false
                self.lblOrder.text = String(order)
                self.imgV.alpha = 1
            }
        }
    }
    
    @objc private func img_click() {
        if (self.mEnable) {
            let order = dalagate?.onSelected(index: self.mIndex, selectd: !self.mSelected) ?? -1
            if (order >= 0) {
                mSelected = !mSelected
                self.iconSelected.isHidden = true
                self.imgV.alpha = 0.7
                if (self.mSelected) {
                    self.iconSelected.isHidden = false
                    self.lblOrder.text = String(order)
                    self.imgV.alpha = 1
                }
            }
        }
    }
}
