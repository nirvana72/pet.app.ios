//
//  IndexTabMyFansViewController.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/29.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import Alamofire
import PullToRefreshKit
import PKHUD
// 粉丝
class IndexTabMyFansViewController: UIViewController {
    struct Module {
        var uid:Int = 0
        var nickname:String = ""
        var avatar:Int = 0
        var profile: String = ""
        var fans:Int = 0
        var articles:Int = 0
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
        tableView.register(UINib(nibName: "IndexTabMyFansViewCell", bundle: nil), forCellReuseIdentifier: "cell")
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
        
        MyHttpClient.requestJSON("/subscribes/\(MySession.getInstance().uid)/fans", method: .get, parameters: query) { (success, json) in
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
                        module.uid          = item["uid"].intValue
                        module.avatar       = item["avatar"].intValue
                        module.nickname     = item["nickname"].stringValue
                        module.profile      = item["profile"].stringValue
                        module.fans         = item["fans"].intValue
                        module.articles     = item["articles"].intValue
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
                    self.dalagate?.updateCount(index: 3, num: json["count"].intValue)
                }
            }
        }
    }
}

extension IndexTabMyFansViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! IndexTabMyFansViewCell
        let module = self.dataSource[indexPath.row]
        cell.setupView(module: module)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let module = self.dataSource[indexPath.row]
        let nextView = UserInfoViewController(userId: module.uid)
        UIViewController.exGetTopViewController()?.navigationController?.pushViewController(nextView, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.btnGoTop.isHidden = scrollView.contentOffset.y < 1500
    }
}

class IndexTabMyFansViewCell: UITableViewCell {
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var lblNickName: UILabel!
    @IBOutlet weak var lblProfile: UILabel!
    @IBOutlet weak var lblInfo: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupView(module: IndexTabMyFansViewController.Module) {
        let avatarUrl = MyTools.avatarPath(avatar: module.avatar, thumb: true)
        ivAvatar.exSetImageSrc(avatarUrl)
        lblNickName.text = module.nickname
        lblProfile.text = module.profile
        lblInfo.text = "粉丝 \(module.fans) · 发布 \(module.articles)"
    }
}
