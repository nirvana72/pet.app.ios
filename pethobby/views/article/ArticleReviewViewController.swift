//
//  ArticleReviewViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/10/10.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwipeCellKit
import SwiftEntryKit

class ArticleReviewViewController: BaseViewController {
    
    struct Module {
        var Id:Int = 0
        var title:String = ""
        var type:String = ""
        var writetime: String = ""
        var authorname: String = ""
    }
    
    private var dataSource: [Module] = []
    private var tableView: UITableView!
    private var lblNoData: UILabel!
    
    override func viewDidLoad() {
        self.title = "待审列表"
        super.viewDidLoad()
        
        self.myNavigationBar.barTintColor = view.backgroundColor
        
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "ArticleReviewViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView.init(frame: .zero)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (v) in
            v.top.equalTo(self.myNavigationBar.snp.bottom)
            v.trailing.leading.bottom.equalToSuperview()
        }
        
        lblNoData = UILabel()
        lblNoData.isHidden = true
        lblNoData.text = "没有待审核的文章"
        lblNoData.font = UIFont.systemFont(ofSize: 14)
        lblNoData.textColor = UIColor.myColorDark3
        self.view.addSubview(lblNoData)
        lblNoData.snp.makeConstraints { (v) in
            v.center.equalToSuperview()
        }
        
        self.fetchData()
    }
    
    private func fetchData() {
        MyHttpClient.requestJSON("/articles/reviewlist", method: .get) { (success, json) in           
            if (success) {
                guard let json = json else { return }
                for item in json["list"].arrayValue {
                    var module = Module()
                    module.Id           = item["Id"].intValue
                    module.title        = item["title"].stringValue
                    module.type         = item["type"].stringValue
                    module.writetime    = item["writetime"].stringValue
                    module.authorname   = item["authorname"].stringValue
                    self.dataSource.append(module)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                self.lblNoData.isHidden = self.dataSource.count > 0
            }
        }
    }
}

extension ArticleReviewViewController: UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ArticleReviewViewCell
        if (cell.delegate == nil) {
            cell.delegate = self
        }
        let module = self.dataSource[indexPath.row]
        cell.setupView(module: module)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let module = self.dataSource[indexPath.row]
        let nextView = ArticleShowViewController(articleId: module.Id)
        UIViewController.exGetTopViewController()?.navigationController?.pushViewController(nextView, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.minimumButtonWidth = 80
        return options
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let action1 = SwipeAction(style: .default, title: "通过") { action, indexPath in
            let articleId = self.dataSource[indexPath.row].Id
            let query: Parameters = [ "cmd": "publish"]
            MyHttpClient.requestJSON("/articles/\(articleId)/review", method: .put, parameters: query) { (success, json) in
                if (success) {
                    let cell = self.tableView.cellForRow(at: indexPath)
                    UIView.animate(withDuration: 0.5, animations: {
                        cell?.alpha = 0
                    }) { (_) in
                        self.dataSource.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
        action1.backgroundColor = UIColor.myColorBlue
        
        let action2 = SwipeAction(style: .destructive, title: "拒绝") { action, indexPath in
            let rejectView = ArticleReviewRejectDialogViewController(indexPath: indexPath)
            rejectView.opener = self
            SwiftEntryKit.display(entry: rejectView, using: ArticleReviewRejectDialogViewController.getEKAttributes())
        }
    
        return [action2, action1]
    }
    // 拒绝回调
    func rejectCallBack(indexPath: IndexPath, reason: String) {
        SwiftEntryKit.dismiss()
        let articleId = self.dataSource[indexPath.row].Id
        let query: Parameters = [ "cmd": "reject", "reason": reason]
        MyHttpClient.requestJSON("/articles/\(articleId)/review", method: .put, parameters: query) { (success, json) in
            if (success) {
                let cell = self.tableView.cellForRow(at: indexPath)
                UIView.animate(withDuration: 0.5, animations: {
                    cell?.alpha = 0
                }) { (_) in
                    self.dataSource.remove(at: indexPath.row)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
}

class ArticleReviewViewCell: SwipeTableViewCell {
    @IBOutlet weak var ivIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var lblWritetime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupView(module: ArticleReviewViewController.Module) {
        switch module.type {
            case "image":
                ivIcon.image = UIImage(named: "icon_photo")
                ivIcon.superview?.backgroundColor = UIColor.exFromHEX(hex: "#019688")
            case "video":
                ivIcon.image = UIImage(named: "icon_play_circle")
                ivIcon.superview?.backgroundColor = UIColor.exFromHEX(hex: "#F44436")
            case "rich":
                ivIcon.image = UIImage(named: "icon_document")
                ivIcon.superview?.backgroundColor = UIColor.exFromHEX(hex: "#9B26B0")
            default:
                break
        }
        lblTitle.text = module.title.exRegexReplace(pattern: "\n", with: " ")
        lblSubTitle.text = "😃" + module.authorname
        lblWritetime.text = module.writetime
    }
}
