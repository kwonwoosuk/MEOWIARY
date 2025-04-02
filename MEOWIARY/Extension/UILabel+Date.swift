//
//  UILabel+Date.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import UIKit

extension UILabel {
    /// 현재 날짜를 표시하는 날짜 레이블을 생성합니다. (yyyy년 M월 d일 형식)
    static func createDateLabel() -> UILabel {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
        
        // 오늘 날짜 표시
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        label.text = dateFormatter.string(from: Date())
        
        return label
    }
    
    /// 현재 요일을 표시하는 레이블을 생성합니다.
    static func createDayOfWeekLabel() -> UILabel {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
        
        // 요일 표시
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        label.text = dateFormatter.string(from: Date())
        
        return label
    }
    
    /// 특정 날짜의 날짜 레이블을 생성합니다. (yyyy년 M월 d일 형식)
    static func createDateLabel(for date: Date) -> UILabel {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        label.text = dateFormatter.string(from: date)
        
        return label
    }
    
    /// 특정 날짜의 요일 레이블을 생성합니다.
    static func createDayOfWeekLabel(for date: Date) -> UILabel {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        label.text = dateFormatter.string(from: date)
        
        return label
    }
}
