//
//  IndexTabMyLikeViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/29.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import SwipeCellKit
import Alamofire
import PullToRefreshKit
import SwiftyJSON
import PKHUD

// 收藏
class IndexTabMyLikeViewController: UIViewController {

    struct Module {
        var Id:Int = 0
        var title:String = ""
        var type:String = ""
        var writetime: String = ""
        var authorname: String = ""
        var image:String = ""
        var status: Int = -1
    }
    
    var tableView: UITableView!
    var btnGoTop: MyButton!
    var dataSource: [Module] = []
    var dalagate: IndexTabMyViewControllerDalagate? = nil
    var query: Parameters = [ "page": 1, "limit": 10 ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "IndexTabMyLikeViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView.init(frame: .zero)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (v) in
            v.edges.equalToSuperview()
        }
        
        btnGoTop = MyButton()
        btnGoTop.backgroundColor = UIColor.red
        btnGoTop.tintColor = UIColor.white
        btnGoTop.setImage(UIImage(named: "icon_arrow_up"), for: .normal)
        btnGoTop.layer.cornerRadius = 20
        btnGoTop.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        btnGoTop.addTarget(self, action: #selector(btnGoTop_click), for: .touchUpInside)
        btnGoTop.isHidden = true
        self.view.addSubview(btnGoTop)
        btnGoTop.snp.makeConstraints { (v) in
            v.size.equalTo(40)
            v.trailing.bottom.equalToSuperview().offset(-20)
        }
        
        let refreshHeader = ElasticRefreshHeader()
        self.tableView.configRefreshHeader(with: refreshHeader, container: self) { [weak self] in
            MyTools.exDelay(1.0, closure: {
                self?.fetchData(cmd: "refresh")
                self?.tableView.switchRefreshHeader(to: .normal(.success, 0.5))
            })
        }
        
        let refreshFooter = DefaultRefreshFooter()
        refreshFooter.tintColor = UIColor.myColorDark2
        self.tableView.configRefreshFooter(with: refreshFooter, container: self) { [weak self] in
            MyTools.exDelay(1.0, closure: {
                self?.fetchData(cmd: "loading")
                self?.tableView.switchRefreshFooter(to: .normal)
            })
        }
        
        self.fetchData(cmd: "first")
    }

    @objc private func btnGoTop_click(_ sender: UIButton) {
        self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    private func fetchData(cmd: String) {
        if (MySession.getInstance().isLogin() == false) {
            PKHUD.toast(text: "请先登录")
            return
        }
        
        if cmd == "refresh" {
            self.query["page"] = 1
        }
        if cmd == "loading" {
            self.query["page"] = (self.query["page"] as! Int) + 1
        }
        
        MyHttpClient.requestJSON("/articles/\(MySession.getInstance().uid)/likes", method: .get, parameters: query) { (success, json) in
            if cmd == "refresh" {
                self.tableView.switchRefreshHeader(to: .normal(.success, 0.5))
                self.tableView.switchRefreshFooter(to: .normal)
            }
            if cmd == "loading" {
                self.tableView.switchRefreshFooter(to: .normal)
            }
            
            if (success) {
                guard let json = json else { return }
                if json.arrayValue.count >= 0 {
                    if (cmd == "refresh") || (cmd == "loading" && self.dataSource.count > 100) {
                        self.dataSource.removeAll()
                    }
                    
                    for item in json["list"].arrayValue {
                        var module = Module()
                        module.Id           = item["Id"].intValue
                        module.title        = item["title"].stringValue
                        module.type         = item["type"].stringValue
                        module.writetime    = item["writetime"].stringValue
                        module.authorname   = item["authorname"].stringValue
                        module.status       = item["status"].intValue
                        if (module.type == "image" || module.type == "rich") {
                            if (item["images"].arrayValue.count > 0) {
                                module.image = item["images"].arrayValue[0].rawValue as! String
                            }
                        }
                        if (module.type == "video") {
                            if (item["videos"].arrayValue.count > 0) {
                                module.image = item["videos"].arrayValue[0]["fname"].stringValue
                            }
                        }
                        self.dataSource.append(module)
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
                if json["list"].arrayValue.count < 10 {
                    self.tableView.switchRefreshFooter(to: .noMoreData)
                }
                
                if (cmd == "first" || cmd == "refresh") {
                    self.dalagate?.updateCount(index: 0, num: json["count"].intValue)
                }
            }
        }
    }
}

extension IndexTabMyLikeViewController: UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "删除") { action, indexPath in
            let module = self.dataSource[indexPath.row]
            MyHttpClient.requestJSON("/articles/\(module.Id)/like", method: .delete) { (success, json) in
                if success  {
                    let cell = tableView.cellForRow(at: indexPath)
                    UIView.animate(withDuration: 0.5, animations: {
                        cell?.alpha = 0
                    }) { (_) in
                        self.dataSource.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.dalagate?.updateCount(index: 0, num: -1)
                        }
                    }
                }
            }
        }
    
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.minimumButtonWidth = 80
        return options
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! IndexTabMyLikeViewCell
        if (cell.delegate == nil) {
            cell.delegate = self
        }
        let module = self.dataSource[indexPath.row]
        cell.setupView(module: module)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let module = self.dataSource[indexPath.row]
        if (module.status == Article.Status.reject.rawValue || module.status == Article.Status.delete.rawValue) {
            PKHUD.toast(text: "文章不见了。。。")
        }
        else{
            let nextView = ArticleShowViewController(articleId: module.Id)
            UIViewController.exGetTopViewController()?.navigationController?.pushViewController(nextView, animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.btnGoTop.isHidden = scrollView.contentOffset.y < 1500
    }
}

class IndexTabMyLikeViewCell: SwipeTableViewCell {
    @IBOutlet weak var vImg: UIImageView!
    @IBOutlet weak var vTypeIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var lblWritetime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupView(module: IndexTabMyLikeViewController.Module) {
        // 被拒文章 被删文章
        if (module.status == Article.Status.reject.rawValue || module.status == Article.Status.delete.rawValue) {
            vImg.image = nil
            lblTitle.text = "文章不见了。。。"
            lblSubTitle.text = ""
            lblWritetime.text = ""
            vTypeIcon.isHidden = true
        } else {
            var url = MyTools.ossPath(articleId: module.Id, writeTime: module.writetime, fileName: module.image, withHost: true)
            if module.type == "image" || module.type == "rich" {
                url += MyTools.AliOssThumb.img3.toString()
            }
            if module.type == "video" {
                url += MyTools.AliOssThumb.video.toString()
            }
            vImg.exSetImageSrc(url)
            
            vTypeIcon.isHidden = module.type != "video"
            lblTitle.text = module.title.exRegexReplace(pattern: "\n", with: " ")
            lblSubTitle.text = "😃" + module.authorname
            lblWritetime.text = module.writetime
        }
    }
}
