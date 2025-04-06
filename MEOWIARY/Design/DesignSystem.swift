//
//  DesignSystem.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import UIKit

enum DesignSystem {
  enum Color {
    enum Tint: String {
      // 앱 메인 컬러 (분홍색)
      case main = "FF6A6A"
      // 버튼, 액션 관련 컬러 (파란색)
      case action = "42A5F5"
      // 라이트 그레이 (배경)
      case lightGray = "F2F2F2"
      // 일반 텍스트 컬러
      case text = "333333"
      case darkGray = "666666"
      
      func inUIColor() -> UIColor {
        return UIColor(hex: self.rawValue)
      }
    }
    
    enum Background: String {
      case main = "FFFFFF"  // 흰색 배경
      case card = "63C7FE"
      case lightBlue = "E3F2FD"
      
      func inUIColor() -> UIColor {
        return UIColor(hex: self.rawValue)
      }
    }
    
    enum Status: String {
      case negative1 = "9E9E9E"   // 경증 (회색)
      case negative2 = "f0e936"   // 구토 (노란색)
      case negative3 = "FF9800"   // 경고  (주황색)
      case negative4 = "F44336"   //  중증  (빨간색)
      case negative5 = "7a1c1a"   // 혈변등 (갈색)
      
      
      func inUIColor() -> UIColor {
        return UIColor(hex: self.rawValue)
      }
    }
  }
  
  enum Icon {
    enum Navigation: String {
      case back = "arrow.left"
      case search = "magnifyingglass"
      case calendar = "calendar"
      case note = "note.text"
      case add = "plus"
      case archive = "photo.on.rectangle.angled.fill"
      case settings = "gearshape"
      func toUIImage() -> UIImage {
        return UIImage(systemName: self.rawValue)!
      }
    }
    
    enum Weather: String {
      case sunny = "sun.max"
      case cloudy = "cloud"
      case rainy = "cloud.rain"
      case snowy = "cloud.snow"
      case thunderstorm = "cloud.bolt.rain"
      
      func toUIImage() -> UIImage {
        return UIImage(systemName: self.rawValue)!
      }
    }
    
    enum Control: String {
      case prevYear = "chevron.left"
      case nextYear = "chevron.right"
      case options = "ellipsis"
      
      func toUIImage() -> UIImage {
        return UIImage(systemName: self.rawValue)!
      }
    }
  }
  
  enum Font {
    enum Size {
      static let small: CGFloat = 12
      static let regular: CGFloat = 14
      static let medium: CGFloat = 16
      static let large: CGFloat = 22
      static let extraLarge: CGFloat = 32
    }
    
    enum Weight {
      static func regular(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size)
      }
      
      static func bold(size: CGFloat) -> UIFont {
        return .boldSystemFont(ofSize: size)
      }
    }
  }
  
  enum Layout {
    static let standardMargin: CGFloat = 20
    static let smallMargin: CGFloat = 10
    static let cornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 20
  }
}



extension DesignSystem {
  enum Device {
    // 화면 크기별 분류
    enum ScreenType {
      case small      // iPhone SE, 5.4인치 미만 (height <= 667)
      case medium     // iPhone 8 Plus ~ iPhone 13, 5.5~6.1인치 (667 < height <= 844)
      case large      // iPhone 13 Pro Max 이상, 6.5인치 이상 (844 < height)
      
      static var current: ScreenType {
        let height = UIScreen.main.bounds.height
        if height <= 667 {
          return .small
        } else if height <= 844 {
          return .medium
        } else {
          return .large
        }
      }
    }
    
    static var isSmallScreen: Bool {
      return ScreenType.current == .small
    }
    
    static var isMediumScreen: Bool {
      return ScreenType.current == .medium
    }
    
    static var isLargeScreen: Bool {
      return ScreenType.current == .large
    }
    
    // 기기별 마진 가져오기
    static func marginForCurrentDevice(small: CGFloat, medium: CGFloat, large: CGFloat) -> CGFloat {
      switch ScreenType.current {
      case .small:
        return small
      case .medium:
        return medium
      case .large:
        return large
      }
    }
    
    // 기기별 폰트 크기 가져오기
    static func fontSizeForCurrentDevice(small: CGFloat, medium: CGFloat, large: CGFloat) -> CGFloat {
      switch ScreenType.current {
      case .small:
        return small
      case .medium:
        return medium
      case .large:
        return large
      }
    }
  }
}

// Layout enum 확장 - 기기별 마진
extension DesignSystem.Layout {
  static var deviceAdaptiveMargin: CGFloat {
    return DesignSystem.Device.marginForCurrentDevice(
      small: standardMargin - 4,
      medium: standardMargin,
      large: standardMargin + 4
    )
  }
  
  static var deviceAdaptiveSmallMargin: CGFloat {
    return DesignSystem.Device.marginForCurrentDevice(
      small: smallMargin - 2,
      medium: smallMargin,
      large: smallMargin + 2
    )
  }
}

// Font.Size enum 확장 - 기기별 폰트 크기
extension DesignSystem.Font.Size {
  static var deviceAdaptiveSmall: CGFloat {
    return DesignSystem.Device.fontSizeForCurrentDevice(
      small: small - 1,
      medium: small,
      large: small + 1
    )
  }
  
  static var deviceAdaptiveRegular: CGFloat {
    return DesignSystem.Device.fontSizeForCurrentDevice(
      small: regular - 1,
      medium: regular,
      large: regular + 1
    )
  }
  
  static var deviceAdaptiveMedium: CGFloat {
    return DesignSystem.Device.fontSizeForCurrentDevice(
      small: medium - 1,
      medium: medium,
      large: medium + 1
    )
  }
  
  static var deviceAdaptiveLarge: CGFloat {
    return DesignSystem.Device.fontSizeForCurrentDevice(
      small: large - 2,
      medium: large,
      large: large + 2
    )
  }
}
