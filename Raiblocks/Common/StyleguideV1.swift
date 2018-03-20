//
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit


enum Styleguide {

    enum Colors: UInt32 {
        case lightBlue = 0x4A90E2
        case darkBlue = 0x000034
        case textLightBlue = 0x4B90E2
        case orange = 0xE1990F
        case lime = 0xEAFAD9
        case red = 0xD0021B

        var color: UIColor {
            return UIColor.from(rgb: self.rawValue)
        }
    }

    enum Fonts: String {
        case nunitoLight = "Nunito-Light"
        case nunitoRegular = "Nunito-Regular"
        case notoSansRegular = "NotoSans-Regular"

        func font(ofSize size: CGFloat) -> UIFont {
            return UIFont(name: self.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
        }
    }

}
