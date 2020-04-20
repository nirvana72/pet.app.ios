//
//  MyUI.swift
//  pethobby
//
//  Created by 倪佳 on 2019/9/13.
//  Copyright © 2019 倪佳. All rights reserved.
//

import UIKit
import AlamofireImage

// 按钮样式
class MyButton: UIButton {
    var myParameters: [String: Any]?
    
    init(flat: Bool = false) {
        super.init(frame: .null)
        self.setupStyle(flat: flat)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupStyle(flat: true)
    }
    
    func setupStyle (flat: Bool) {
        layer.cornerRadius = 5
        if (!flat) {
            layer.shadowColor = UIColor.myColorDark0.cgColor
            layer.shadowOffset = CGSize(width: 2, height: 2)
            layer.shadowRadius = 5
            layer.shadowOpacity = 0.3
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        layer.shadowColor = UIColor.clear.cgColor
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        layer.shadowColor = UIColor.myColorDark0.cgColor
        super.touchesEnded(touches, with: event)
    }
}

extension UITextField {
    func exAddIcon(icon: String) {
        let ivIcon = UIImageView(frame: CGRect(x: 10, y: 8, width: 30, height: 30))
        ivIcon.image = UIImage(named: icon)
        ivIcon.tintColor = UIColor.myColorDark3
        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.leftViewMode = .always
        self.addSubview(ivIcon)
    }
}

// 图片扩展
extension UIImageView {
    func exSetImageSrc(_ string : String?) {
        if(string != nil){
            let url = URL(string: string!)!
            self.af_setImage(withURL: url)
        }
    }
    //  一般作为图标的点击特效
    func exSetClickAnimate(duration: TimeInterval = 0.2, by: CGFloat = 1.5) {
        let rect = self.bounds
        UIView.animate(withDuration: duration, animations: {
            self.bounds = CGRect(x: 0, y: 0, width: rect.width * by, height: rect.width * by)
        }) { (_) in
            self.bounds = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        }
    }
}

// UIImage 缩放
extension UIImage {
    func exResize(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func exWithTintColor(color: UIColor) ->UIImage {
        
        UIGraphicsBeginImageContext(self.size)
        color.setFill()
        let bounds = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIRectFill(bounds)
        self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
        
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
}

extension UIView {
    // 清空所有子视图
    func exRemoveAllSubview() {
        for v in self.subviews {
            v.removeFromSuperview()
        }
    }
    
    // 虚线边框
    func exAddDashBorder (color: UIColor, frameSize: CGSize) {
        let  borderLayer = CAShapeLayer()
        borderLayer.name  = "borderLayer"
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        borderLayer.bounds = shapeRect
        borderLayer.position = CGPoint(x: frameSize.width/2,y: frameSize.height/2)
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = color.cgColor
        borderLayer.lineWidth = 1
        borderLayer.lineJoin = CAShapeLayerLineJoin.round
        borderLayer.lineDashPattern = NSArray(array: [NSNumber(value: 8),NSNumber(value:4)]) as? [NSNumber]
        
        let path = UIBezierPath.init(roundedRect: shapeRect, cornerRadius: 0)
        
        borderLayer.path = path.cgPath
        
        self.layer.addSublayer(borderLayer)
    }
}

extension UIViewController {
    class func exGetTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return exGetTopViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return exGetTopViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return exGetTopViewController(base: presented)
        }
        return base
    }
}
