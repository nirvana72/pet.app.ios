//
//  IntExtension.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/14.
//  Copyright © 2019 倪佳. All rights reserved.
//

import Foundation

extension Int {
    /*这是一个内置函数
     lower : 内置为 0，可根据自己要获取的随机数进行修改。
     upper : 内置为 UInt32.max 的最大值，这里防止转化越界，造成的崩溃。
     返回的结果： [lower,upper) 之间的半开半闭区间的数。
     */
    public static func exRandomIntNumber(lower: Int = 0,upper: Int = Int(UInt32.max)) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower)))
    }
    /**
     生成某个区间的随机数
     range: 1..7
     */
    public static func exRandomIntNumber(range: Range<Int>) -> Int {
        return exRandomIntNumber(lower: range.lowerBound, upper: range.upperBound)
    }
}
