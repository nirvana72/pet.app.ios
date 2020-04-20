//
//  MySession.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Foundation

class MySession: Codable {
    var uid: Int = -1
    var nickname: String = ""
    var avatar: Int = 1
    var role: String = "custom"
    var token: String = ""
    var refreshtoken: String = ""
    var time: String = ""
    
    func isLogin() -> Bool {
        return self.uid > 0
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: MySession.TAG)
        }
    }
    
    func clean() {
        MySession.instance = MySession()
        UserDefaults.standard.removeObject(forKey: MySession.TAG)
    }
    
    //------------------------------------------------------------
    
    static let TAG = "MySession"
    static private var instance: MySession? = nil
    static func getInstance() -> MySession {
        if (instance == nil) {
            if let data = UserDefaults.standard.data(forKey: MySession.TAG),
               let session = try? JSONDecoder().decode(MySession.self, from: data) {
                instance = session
            } else {
                instance = MySession()
            }
        }
        return instance!
    }
}
