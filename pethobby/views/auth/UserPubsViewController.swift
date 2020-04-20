//
//  UserPubsViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/10/8.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Alamofire
import PullToRefreshKit

class UserPubsViewController: BaseViewController {
    struct Module {
        var Id:Int = 0
        var title:String = ""
        var type:String = ""
        var writetime: String = ""
        var authorname: String = ""
        var image:String = ""
    }
    private var userId:Int = -1
    private var nickName:String = ""
    private var query: Parameters = [ "page": 1, "limit": 10]
    private var dataSource: [Module] = []
    private var tableView: UITableView!
    private var btnGoTop: UIButton!
    
    init(userId: Int, nickName: String) {
        super.init(nibName: nil, bundle: nil)
        self.userId = userId
        self.nickName = nickName
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.title = "发布动态"
        super.viewDidLoad()
        
        self.myNavigationBar.barTintColor = UIColor.myColorLight1
        
        tableView = UITableView()
        tableView.rowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "UserPubsViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView.init(frame: .zero)
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
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (v) in
            v.top.equalTo(self.myNavigationBar.snp.bottom)
            v.leading.trailing.bottom.equalToSuperview()
        }
        //----------------------------------------------------------
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
        //----------------------------------------------------------
        self.fetchData(cmd: "first")
    }
    
    // cmd : refresh / loading
    private func fetchData(cmd: String) {
        if cmd == "refresh" {
            self.query["page"] = 1
        }
        if cmd == "loading" {
            self.query["page"] = (self.query["page"] as! Int) + 1
        }
        
        MyHttpClient.requestJSON("/articles/\(self.userId)/users", method: .get, parameters: query) { (success, json) in
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
                        module.authorname   = self.nickName
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
            }
        }
    }
    
    @objc private func btnGoTop_click(_ sender: UIButton) {
        self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
}

extension UserPubsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserPubsViewCell
        let module = self.dataSource[indexPath.row]
        cell.setupView(module: module)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let module = self.dataSource[indexPath.row]
        let nextView = ArticleShowViewController(articleId: module.Id)
        navigationController?.pushViewController(nextView, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.btnGoTop.isHidden = scrollView.contentOffset.y < 1500
    }
}

class UserPubsViewCell: UITableViewCell {
    @IBOutlet weak var vImg: UIImageView!
    @IBOutlet weak var vTypeIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var lblWritetime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupView(module: UserPubsViewController.Module) {
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
