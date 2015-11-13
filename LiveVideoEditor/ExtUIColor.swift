//
//  ExtUIColor.swift
//  FillDay
//
//  Created by ParkSangHa on 2015. 10. 13..
//  Copyright © 2015년 ParkSangHa. All rights reserved.
//

import Foundation


extension UIColor{
    convenience init(hexString: String) {
        // Trim leading '#' if needed
        let cleanedHexString = hexString
        
        // String -> UInt32
        var rgbValue: UInt32 = 0
        NSScanner(string: cleanedHexString).scanHexInt(&rgbValue)
        
        // UInt32 -> R,G,B
        let red = CGFloat((rgbValue >> 16) & 0xff) / 255.0
        let green = CGFloat((rgbValue >> 08) & 0xff) / 255.0
        let blue = CGFloat((rgbValue >> 00) & 0xff) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    
    static func greenColorCustom() -> UIColor{
        return UIColor(hexString: "3B8C88")
    }
    static func redColorCustom() -> UIColor{
        return UIColor(hexString: "FF3D5A")
    }
    static func orangeColorCustom() -> UIColor{
        return UIColor(hexString: "FFB969")
    }
    static func blueColorCustom() ->UIColor{
        return UIColor(hexString: "3498DB")
    }
    
    
    static func progressRedColorCustom() -> UIColor{
        return UIColor(hexString: "E74C3C")
    }
    
    static func progressYellowColorCustom() -> UIColor{
        return UIColor(hexString: "F1C40F")
    }
    
    static func progressGreenColorCustom() -> UIColor{
        return UIColor(hexString: "1ABC9C")
    }
    
    
    static func darkNavyColorCustom()-> UIColor{
        return UIColor(hexString: "34495E")
    }
}