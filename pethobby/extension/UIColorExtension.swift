//
//  ColorExtension.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/13.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit

extension UIColor {
    static func exFromHEX(hex: String) -> UIColor{
        var cstr = hex.trimmingCharacters(in:  CharacterSet.whitespacesAndNewlines).uppercased() as NSString;
        if(cstr.length < 6){
            return UIColor.clear;
        }
        if(cstr.hasPrefix("0X")){
            cstr = cstr.substring(from: 2) as NSString
        }
        if(cstr.hasPrefix("#")){
            cstr = cstr.substring(from: 1) as NSString
        }
        if(cstr.length != 6){
            return UIColor.clear;
        }
        var range = NSRange.init()
        range.location = 0
        range.length = 2
        //r
        let rStr = cstr.substring(with: range);
        //g
        range.location = 2;
        let gStr = cstr.substring(with: range)
        //b
        range.location = 4;
        let bStr = cstr.substring(with: range)
        var r :UInt32 = 0x0;
        var g :UInt32 = 0x0;
        var b :UInt32 = 0x0;
        Scanner.init(string: rStr).scanHexInt32(&r);
        Scanner.init(string: gStr).scanHexInt32(&g);
        Scanner.init(string: bStr).scanHexInt32(&b);
        return UIColor.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1);
    }
    
    static func exGetRandomColor() -> UIColor {
        let red = CGFloat(arc4random()%256)/255.0
        let green = CGFloat(arc4random()%256)/255.0
        let blue = CGFloat(arc4random()%256)/255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    // ----------------------------------------------
    // 常用颜色
    static let myColorBlue = UIColor(named: "myColorBlue")!
    static let myColorGreen = UIColor(named: "myColorGreen")!    
    static let myColorLight0 = UIColor(named: "myColorLight0")!
    static let myColorLight1 = UIColor(named: "myColorLight1")!
    static let myColorLight2 = UIColor(named: "myColorLight2")!
    static let myColorLight3 = UIColor(named: "myColorLight3")!
    static let myColorDark0 = UIColor(named: "myColorDark0")!
    static let myColorDark1 = UIColor(named: "myColorDark1")!
    static let myColorDark2 = UIColor(named: "myColorDark2")!
    static let myColorDark3 = UIColor(named: "myColorDark3")!
}
