//
//  AlamofireExtension.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Alamofire
import SwiftyJSON

// 统一访问预处理
class MyRequestAdapter: RequestAdapter {
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        let clientDevice = MyTools.getDeviceName()
        urlRequest.setValue(clientDevice, forHTTPHeaderField: "ClientDevice")
        if MySession.getInstance().isLogin() {
            urlRequest.setValue("Bearer " + MySession.getInstance().token, forHTTPHeaderField: "Authorization")
            urlRequest.setValue(String(MySession.getInstance().uid), forHTTPHeaderField: "ClientUid")
        }
        return urlRequest
    }
}

class MyHttpClient {
    static private var sessionManager: SessionManager? = nil
    static private var refreshTokenFlag: Bool = false
    
    static func getSessionManager() -> SessionManager {
        if (sessionManager == nil) {
            sessionManager = SessionManager()
            sessionManager!.adapter = MyRequestAdapter()
        }
        return sessionManager!
    }
    
    static func refreshToken(completionHandler: @escaping () -> Void) {
        let parameters: Parameters = [
            "refreshToken": MySession.getInstance().refreshtoken
        ]
        
        Alamofire.request(MyConfig.APP_APIHOST + "/jwt/refresh", method: .get, parameters: parameters).responseJSON { response in
            // print("重新刷新token")
            if response.result.isSuccess, let result = response.result.value {
                let json = JSON(result)
                if let ret = json["ret"].int, ret > 0 {
                    MySession.getInstance().token = json["token"].stringValue
                    MySession.getInstance().refreshtoken = json["refreshtoken"].stringValue
                    MySession.getInstance().save()
                    // print("重新刷新token成功，已重置session")
                    completionHandler()
                }
                else {
                    // print("重新刷新token失败")
                    MySession.getInstance().clean()
                    // 融云服务器断开连接
                    RCIM.shared()?.ex_disconnect()
                    
                    UIAlertController.error(message: "登录信息过期,需要重新登录")
                }
            } else {
                UIAlertController.error(message: "refreshToken error")
            }
        }
    }
    
    static func requestJSON(
        _ url: String,
        method: Alamofire.HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        completionHandler: @escaping (Bool, JSON?) -> Void)
    {
        let fullUrl = MyConfig.APP_APIHOST + url
        
        let dataRequest = MyHttpClient.getSessionManager().request(fullUrl, method: method, parameters: parameters, encoding: encoding, headers: headers)
        
        dataRequest.responseJSON(queue: nil, options: .allowFragments) { (res) in
            guard res.result.isSuccess else {
                UIAlertController.error(message: "网络好像有点问题")
                completionHandler(false, nil)
                return
            }
            
            if let result = res.result.value {
                let json = JSON(result)
                let ret = json["ret"].intValue
                if (ret == -99) {  // PHP后台，-99表示登录信息超时
                    // print("登录信息超时，需要重新刷新token")
                    // refreshTokenFlag 避免死循环
                    if (MyHttpClient.refreshTokenFlag == true) {
                        UIAlertController.error(message: "refreshTokenFlag error")
                        return
                    }
                    MyHttpClient.refreshTokenFlag = true
                    
                    MyHttpClient.refreshToken(completionHandler: {
                        MyHttpClient.requestJSON(url, method: method, parameters:parameters, encoding: encoding, headers: headers, completionHandler: completionHandler)
                    })
                } else {
                    MyHttpClient.refreshTokenFlag = false
                    
                    if (ret > 0) {
                        completionHandler(true, json)
                    } else {
                        let msg = json["msg"].string
                        UIAlertController.error(message: msg ?? "未知错误")
                        completionHandler(false, json)
                    }
                }
            } else {
                UIAlertController.error(message: "res.result.value is null")
                completionHandler(false, nil)
            }
        }
    }
}
