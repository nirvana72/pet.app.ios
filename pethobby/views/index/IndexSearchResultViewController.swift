//
//  IndexSearchResultViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/15.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class IndexSearchResultViewController: BaseViewController {
    
    struct Module {
        var Id:Int = 0
        var title:String = ""
        var type:String = ""
        var writetime: String = ""
        var authorname: String = ""
        var image:String = ""
    }
    
    private var query: Parameters = [ "search": "", "limit": 10]
    private var dataSource: [Module] = []
    private var tableView: UITableView!
    private var lblNoData: UILabel!
    
    convenience init(searchString: String) {
        self.init()
        self.query["search"] = searchString
    }
    
    override func viewDidLoad() {
        self.title = "查询结果"
        super.viewDidLoad()
        
        self.myNavigationBar.barTintColor = UIColor.myColorLight1
        
        tableView = UITableView()
        tableView.rowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "IndexSearchResultViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView.init(frame: .zero)
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (v) in
            v.top.equalTo(self.myNavigationBar.snp.bottom)
            v.leading.trailing.bottom.equalToSuperview()
        }
        
        lblNoData = UILabel()
        lblNoData.isHidden = true
        lblNoData.text = "没有找到搜索内容"
        lblNoData.font = UIFont.systemFont(ofSize: 14)
        lblNoData.textColor = UIColor.myColorDark3
        self.view.addSubview(lblNoData)
        lblNoData.snp.makeConstraints { (v) in
            v.center.equalToSuperview()
        }
        
        self.fetchData()
    }
    
    // cmd : refresh / loading
    func fetchData() {
        MyHttpClient.requestJSON("/articles/", method: .get, parameters: self.query) { (success, json) in            
            if success {
                guard let json = json else { return }
                if json["articles"].arrayValue.count > 0 {
                    
                    for item in json["articles"].arrayValue {
                        var module = Module()
                        module.Id           = item["Id"].intValue
                        module.title        = item["title"].stringValue
                        module.type         = item["type"].stringValue
                        module.writetime    = item["writetime"].stringValue
                        module.authorname   = item["authorname"].stringValue
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
                } else {
                    self.lblNoData.isHidden = false
                }
            }
        }
    }
}

extension IndexSearchResultViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! IndexSearchResultCell
        let module = self.dataSource[indexPath.row]
        cell.setupView(module: module)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let module = self.dataSource[indexPath.row]
        let nextView = ArticleShowViewController(articleId: module.Id)
        navigationController?.pushViewController(nextView, animated: true)
    }
}

class IndexSearchResultCell: UITableViewCell {
    @IBOutlet weak var vImg: UIImageView!
    @IBOutlet weak var vTypeIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var lblWritetime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupView(module: IndexSearchResultViewController.Module) {
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
