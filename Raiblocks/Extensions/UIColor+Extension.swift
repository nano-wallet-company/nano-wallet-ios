//
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import UIKit


extension UIColor {

    var coreImageColor: CIColor {
        return CIColor(color: self)
    }

    class func from(rgb: UInt32) -> UIColor {
        return UIColor(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    func lighterColor(percent: Double) -> UIColor {
        return colorWithBrightnessFactor(factor: CGFloat(1 + percent))
    }

    func darkerColor(percent: Double) -> UIColor {
        return colorWithBrightnessFactor(factor: CGFloat(1 - percent))
    }

    func colorWithBrightnessFactor(factor: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: brightness * factor, alpha: alpha)
        } else {
            return self
        }
    }

}

