//
//  IndexTabMyMyViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/29.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import PullToRefreshKit
import Alamofire
import PKHUD

class IndexTabMyMyViewController: UIViewController {
    
    struct Module {
        var Id: Int = 0
        var title: String = ""
        var writetime: String = ""
        var type: String = ""
        var status: Int = -1
        var lauds: Int = 0
        var comments: Int = 0
        var likes: Int = 0
        var image: String = ""
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
        tableView.register(UINib(nibName: "IndexTabMyMyViewCell", bundle: nil), forCellReuseIdentifier: "cell")
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
        
        MyHttpClient.requestJSON("/articles/\(MySession.getInstance().uid)/users", method: .get, parameters: query) { (success, json) in
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
                        module.writetime    = item["writetime"].stringValue
                        module.type         = item["type"].stringValue
                        module.status       = item["status"].intValue
                        module.lauds        = item["lauds"].intValue
                        module.comments     = item["comments"].intValue
                        module.likes        = item["likes"].intValue
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
                    self.dalagate?.updateCount(index: 2, num: json["count"].intValue)
                }
            }
        }
    }
}

extension IndexTabMyMyViewController: UITableViewDelegate, UITableViewDataSource {
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! IndexTabMyMyViewCell       
        let module = self.dataSource[indexPath.row]
        cell.setupView(module: module)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let module = self.dataSource[indexPath.row]
        let nextView = ArticleShowViewController(articleId: module.Id)
        UIViewController.exGetTopViewController()?.navigationController?.pushViewController(nextView, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.btnGoTop.isHidden = scrollView.contentOffset.y < 1500
    }
}

class IndexTabMyMyViewCell: UITableViewCell {
    
    @IBOutlet weak var vImg: UIImageView!
    @IBOutlet weak var vTypeIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblWritetime: UILabel!
    @IBOutlet weak var lblInfo: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupView(module: IndexTabMyMyViewController.Module) {
        var url = MyTools.ossPath(articleId: module.Id, writeTime: module.writetime, fileName: module.image, withHost: true)
        if module.type == "image" || module.type == "rich" {
            url += MyTools.AliOssThumb.img3.toString()
        }
        if module.type == "video" {
            url += MyTools.AliOssThumb.video.toString()
        }
        vImg.exSetImageSrc(url)
        
        vTypeIcon.isHidden = module.type != "video"
        
        let title = module.title.exRegexReplace(pattern: "\n", with: " ")
        var attrStrTitle = NSMutableAttributedString(string: title)
        if (module.status != 2) {
            var status = NSMutableAttributedString(string: "[错] ")
            status.addAttribute(.foregroundColor, value: UIColor.red, range: NSMakeRange(0, status.length))
            if module.status == 1 {
                status = NSMutableAttributedString(string: "[审] ")
                status.addAttribute(.foregroundColor, value: UIColor.blue, range: NSMakeRange(0, status.length))
            }
            if module.status == 10 {
                status = NSMutableAttributedString(string: "[拒] ")
                status.addAttribute(.foregroundColor, value: UIColor.orange, range: NSMakeRange(0, status.length))
            }
            status.append(attrStrTitle)
            attrStrTitle = status
        }
        lblTitle.attributedText = attrStrTitle
        
        lblWritetime.text = module.writetime
        
        let attchLauds = NSTextAttachment()
        attchLauds.image = UIImage(named: "icon_thumb_up")?.exWithTintColor(color: UIColor.myColorDark2)
        attchLauds.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
        let iconLauds = NSAttributedString(attachment: attchLauds)
        let attrLauds = NSMutableAttributedString(string: " \(module.lauds) ")
        attrLauds.insert(iconLauds, at: 0)
        
        let attchComments = NSTextAttachment()
        attchComments.image = UIImage(named: "icon_comment")?.exWithTintColor(color: UIColor.myColorDark2)
        attchComments.bounds = CGRect(x: 0, y: -4, width: 16, height: 16)
        let iconComments = NSAttributedString(attachment: attchComments)
        let attrComments = NSMutableAttributedString(string: " \(module.comments) ")
        attrComments.insert(iconComments, at: 0)
        
        let attchLikes = NSTextAttachment()
        attchLikes.image = UIImage(named: "icon_favorite")?.exWithTintColor(color: UIColor.myColorDark2)
        attchLikes.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
        let iconLikes = NSAttributedString(attachment: attchLikes)
        let attrLikes = NSMutableAttributedString(string: " \(module.likes) ")
        attrLikes.insert(iconLikes, at: 0)
        
        let attrInfo = NSMutableAttributedString()
        attrInfo.append(attrLauds)
        attrInfo.append(attrComments)
        attrInfo.append(attrLikes)
        lblInfo.attributedText = attrInfo
    }
}

