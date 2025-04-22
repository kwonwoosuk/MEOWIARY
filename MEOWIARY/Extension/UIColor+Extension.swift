//
//  UIColor+Extension.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import UIKit

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func toHexString() -> String {
           var r: CGFloat = 0
           var g: CGFloat = 0
           var b: CGFloat = 0
           var a: CGFloat = 0
           
           getRed(&r, green: &g, blue: &b, alpha: &a)
           
           return String(
               format: "%02X%02X%02X",
               Int(r * 255),
               Int(g * 255),
               Int(b * 255)
           )
       }
       
       // 추가: 색상 밝기 조정 (카드 색상 변형용)
       func lighter(by percentage: CGFloat = 0.2) -> UIColor {
           return self.adjust(by: abs(percentage))
       }
       
       func darker(by percentage: CGFloat = 0.2) -> UIColor {
           return self.adjust(by: -abs(percentage))
       }
       
       private func adjust(by percentage: CGFloat) -> UIColor {
           var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
           
           if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
               return UIColor(
                   red: min(red + percentage, 1.0),
                   green: min(green + percentage, 1.0),
                   blue: min(blue + percentage, 1.0),
                   alpha: alpha
               )
           }
           
           return self
       }
       
       // 추가: 두 색상 간의 대비 체크 (텍스트 색상 결정용)
       func isLight() -> Bool {
           guard let components = self.cgColor.components else { return true }
           
           let red: CGFloat
           let green: CGFloat
           let blue: CGFloat
           
           if components.count >= 3 {
               red = components[0]
               green = components[1]
               blue = components[2]
           } else {
               let brightness = components[0]
               red = brightness
               green = brightness
               blue = brightness
           }
           
           // YIQ 공식을 사용한 밝기 계산
           let brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000
           
           return brightness > 0.5
       }
       
       // 추가: 텍스트에 사용할 적합한 색상 반환 (검정 또는 흰색)
       func contrastingTextColor() -> UIColor {
           return isLight() ? .black : .white
       }
    
}

