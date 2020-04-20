//
//  Modules.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Foundation
import SwiftyJSON

class Article: NSObject {
    enum Status:Int {
        case create = 11 // 提交第一步，出错会停留在这一步
        case review = 1  // 正常情况下，提交等街上传资源完成，变成待审核
        case publish = 2 // 审核通过
        case reject = 10 // 审核被拒
        case delete = -1 // 已删除， 文章表中已删除，其它表中还有引用的情况
    }
    // 文章ID
    var Id:Int = 0
    // 文章类型
    var type:String = ""
    // 标题
    var title:String = ""
    // 摘要
    var abstract:String = ""
    // 正文
    var content:String = ""
    // 作者ID
    var authorId:Int = 0
    // 作者
    var authorName:String = ""
    // 作者头像
    var avatar:Int = 1
    // 发布时间
    var writeTime:String = "yyyy-mm-dd"
    // 收藏数
    var likes:Int = 0
    // 点赞数
    var lauds:Int = 0
    // 是否已点赞e
    var lauded:Bool = false
    // 发布时所在地址
    var postAddr:String = ""
    // 是否被登用户收藏
    var liked:Bool = false
    // 用户是否被关注
    var subscribe:Bool = false
    // 评论数
    var comments:Int = 0
    // 文章图片
    var images:[String] = []
    // 状态 1: 审核中  2：发布成功 10：拒绝  其它发布出错
    var status:Int = -1
    // 文章视频
    var videos:[Video] = []
    
    override init() {}
    
    init(json: JSON) {
        self.Id          = json["Id"].intValue
        self.authorName  = json["authorname"].stringValue
        self.likes       = json["likes"].intValue
        self.writeTime   = json["writetime"].stringValue
        self.authorId    = json["authorId"].intValue
        self.title       = json["title"].stringValue
        self.lauds       = json["lauds"].intValue
        self.postAddr    = json["postAddr"].stringValue
        self.abstract    = json["abstract"].stringValue
        self.liked       = json["liked"].boolValue
        self.subscribe   = json["subscribe"].boolValue
        self.comments    = json["comments"].intValue
        self.avatar      = json["avatar"].intValue
        self.type        = json["type"].stringValue
        self.status      = json["status"].intValue
        for img in json["images"].arrayValue {
            self.images.append(img.rawValue as! String)
        }
        for (_, vid ):(String, JSON) in json["videos"] {
            let video = Video()
            video.fname = vid["fname"].stringValue
            video.duration = vid["duration"].intValue
            self.videos.append(video)
        }
    }
}

class Video:NSObject{
    // 文件名
    var fname:String = ""
    // 时长
    var duration:Int = 0
}
