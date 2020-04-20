//
//  IndexTabHomeViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Alamofire
import SnapKit
import PullToRefreshKit
import SwiftEntryKit

class IndexTabHomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var btnGoTop: MyButton!
    @IBOutlet weak var constraintTopViewHeight: NSLayoutConstraint!
    
    var articles: [Article] = []
    var scrollYmark:CGFloat = 0
    
    @IBAction func btnGoTop_click(_ sender: UIButton) {
        self.constraintTopViewHeight.constant = 50
        self.tableView.setContentOffset(CGPoint(x: 0, y: -50), animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.isTranslucent = false
        searchBar.placeholder = "搜索"
        searchBar.barTintColor = IndexTabMenuView.BackgroundColor
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = self.searchBar.barTintColor?.cgColor
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 500 // 必需设置一个差不多的值，才能使加载时不闪烁，=0不行
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "IndexTabHomeTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        
        let refreshHeader = ElasticRefreshHeader()
        self.tableView.configRefreshHeader(with: refreshHeader, container: self) { [weak self] in
            MyTools.exDelay(1.0, closure: {
                guard let vc = self else { return }
                vc.fetchData(cmd: "refresh")
            })
        }

        let refreshFooter = DefaultRefreshFooter()
        self.tableView.configRefreshFooter(with: refreshFooter, container: self) { [weak self] in
            MyTools.exDelay(0.5, closure: {
                guard let vc = self else { return }
                vc.fetchData(cmd: "loading")
            })
        }
        
        self.fetchData(cmd: "first")
    }
    
    private func fetchData (cmd: String) {
        var query: Parameters = [ "time": "", "limit": 10 ]
        if cmd == "refresh" {
            query["time"] = ""
        }
        if cmd == "loading" {
            query["time"] = self.articles.last?.writeTime ?? ""
        }
        MyHttpClient.requestJSON("/articles/", method: .get, parameters: query) { (success, json) in
            if cmd == "refresh" {
                self.tableView.switchRefreshHeader(to: .normal(.success, 0.5))
                self.tableView.switchRefreshFooter(to: .normal)
            }
            if cmd == "loading" {
                self.tableView.switchRefreshFooter(to: .normal)
            }
            
            if (success) {
                guard let json = json else { return }
                if json["articles"].arrayValue.count >= 0 {
                    if (cmd == "refresh") || (cmd == "loading" && self.articles.count > 100) {
                        self.articles.removeAll()
                    }
                    
                    for articleJson in json["articles"].arrayValue {
                        let article = Article(json: articleJson)
                        self.articles.append(article)
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                if json["articles"].arrayValue.count < 10 {
                    self.tableView.switchRefreshFooter(to: .noMoreData)
                }
            }
        }
    }
}
// UICollectionView 数据，行为代理
extension IndexTabHomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! IndexTabHomeTableViewCell
        if (cell.delegate == nil) { cell.delegate = self }
        cell.updateView(article: self.articles[indexPath.row], index: indexPath.row)
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.btnGoTop.isHidden = scrollView.contentOffset.y < 1500
        // 上下划渐隐渐现搜索框
        if (scrollView.contentOffset.y > self.scrollYmark) {
            if (self.constraintTopViewHeight.constant > 0 && scrollView.contentOffset.y > 500) {
                self.constraintTopViewHeight.constant -= 2 // 上划
            }
        } else {
            if (self.constraintTopViewHeight.constant < 50) {
                self.constraintTopViewHeight.constant += 2 // 下划
            }
        }
        self.scrollYmark = scrollView.contentOffset.y
    }
}

extension IndexTabHomeViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchString = searchBar.text, searchString.trimmingCharacters(in: .whitespaces) != "" {
            let nextView = IndexSearchResultViewController(searchString: searchString)
            let vc = UIViewController.exGetTopViewController()
            vc?.navigationController?.pushViewController(nextView, animated: true)
            UIApplication.shared.keyWindow?.endEditing(true)
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        UIApplication.shared.keyWindow?.endEditing(true)
    }
}

extension IndexTabHomeViewController: IndexTabHomeCellDelegate {
    func onCellCmd(cmd: String, index: Int) {
        if (cmd == "屏蔽") {
            self.articles.remove(at: index)
            self.tableView.reloadData()
        }
        
        if (cmd == "举报") {
            let alertController = UIAlertController(title: "请选择举报原因", message: "",preferredStyle: .actionSheet)
            //取消按钮
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let action1 = UIAlertAction(title: "色情低俗", style: .default) { (action) in self.jubao(index: index, cmd: "色情低俗")}
            let action2 = UIAlertAction(title: "政治敏感", style: .default)  { (action) in self.jubao(index: index,cmd: "政治敏感")}
            let action3 = UIAlertAction(title: "广告", style: .default) { (action) in self.jubao(index: index,cmd: "广告")}
            let action4 = UIAlertAction(title: "内容恶心", style: .default) { (action) in self.jubao(index: index,cmd: "内容恶心")}
            let action5 = UIAlertAction(title: "违纪违法", style: .default) { (action) in self.jubao(index: index,cmd: "违纪违法")}
            let action6 = UIAlertAction(title: "其它", style: .default) { (action) in self.jubao(index: index,cmd: "其它")}
            
            alertController.addAction(action1)
            alertController.addAction(action2)
            alertController.addAction(action3)
            alertController.addAction(action4)
            alertController.addAction(action5)
            alertController.addAction(action6)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // 举报
    func jubao(index: Int, cmd: String) {
        UIAlertController.alert(message: "感谢您的举报，我们会在24小时内审核该内容")
        let article = self.articles[index]
        let params: Parameters = [
            "article_id": article.Id,
            "report_uid": MySession.getInstance().uid,
            "content": cmd
        ]
        MyHttpClient.getSessionManager().request("\(MyConfig.APP_APIHOST)/log/report", method: .put, parameters: params)
    }
}
