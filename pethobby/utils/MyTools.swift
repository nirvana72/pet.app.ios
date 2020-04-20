//
//  MyTools.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//
import Foundation
import UIKit

class MyTools: NSObject {    
    enum AliOssThumb {
        case avatar, video, img1, img2, img3
        func toString() -> String {
            switch self {
            case .avatar: return "?x-oss-process=style/avatar"
            case .video: return "?x-oss-process=video/snapshot,t_1000,m_fast" //?x-oss-process=video/snapshot,w_300,h_180,t_5000,m_fast"
            case .img1: return "?x-oss-process=style/thumb300_180"
            case .img2: return "?x-oss-process=style/thumb150_120"
            case .img3: return "?x-oss-process=style/thumb100_100"
            }
        }
    }
    
    // 取机型
    static func getDeviceName() -> String {
        var version = "ios|\(UIDevice.current.systemVersion)|\(UIDevice.current.model)"
        version = version.exRegexReplace(pattern: "ʀ", with: "r")        
        return version
    }
    
    // 根据文章信息取OSSdd存储k路径
    static func ossPath(articleId: Int, writeTime:String, fileName:String, withHost:Bool = true) -> String {
        let yyyymm = writeTime.exRegexReplace(pattern: "-", with: "").prefix(6)
        var path = "articles/\(yyyymm)/\(articleId)/\(fileName)"
        if withHost {
            path = MyConfig.APP_oss_host + "/" + path
        }
        return path
    }
    
    // 根据头像ID取OSS上的d存储k路径
    static func avatarPath(avatar: Int, thumb: Bool = true) -> String {
        var url = ""
        if avatar < 100 {
            url = "\(MyConfig.APP_oss_host)/avatar/\(avatar).png"
        } else {
            let groupId = Int( floor(Double(avatar) / 1000) * 1000 )
            url = "\(MyConfig.APP_oss_host)/avatar/\(groupId)/\(avatar).png"
        }
        url += thumb ? MyTools.AliOssThumb.img3.toString() : MyTools.AliOssThumb.avatar.toString()
        if avatar > 100, avatar == MySession.getInstance().avatar {
            url += "&v=" + MySession.getInstance().time
        }
        
        return url
    }
    //把过去的秒数转换成 多少时间前
    static func durationString(duration:Int) ->String {
        let hour = duration / 3600
        let minute = (duration % 3600) / 60
        let second = duration % 60
        var str = ""
        if hour > 0 {
            str += "\(hour):"
        }
        
        if minute < 10 {
            str += "0\(minute):"
        } else {
            str += "\(minute):"
        }
        
        if second < 10 {
            str += "0\(second)"
        } else {
            str += "\(second)"
        }
        return str
    }
    
    static func exDelay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
}
