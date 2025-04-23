//
//  Schedule.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/22/25.
//

import Foundation


struct Schedule: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var date: Date
    var type: ScheduleType
    var color: String
    
    enum ScheduleType: String, Codable {
        case hospital = "병원"
        case vaccination = "예방접종"
        case medicine = "약"
        case checkup = "검진"
        case other = "기타"
    }
    
    // 현재 날짜 기준으로 D-day 계산
    func calculateDDay() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        
        if let days = calendar.dateComponents([.day], from: today, to: targetDate).day {
            return days
        }
        return 0
    }
    
    // D-day 텍스트 반환
    func dDayText() -> String {
        let days = calculateDDay()
        if days == 0 {
            return "D-day"
        } else if days > 0 {
            return "D-\(days)"
        } else {
            return "D+\(abs(days))"
        }
    }
    
    static func == (lhs: Schedule, rhs: Schedule) -> Bool {
        return lhs.id == rhs.id
    }
}

// UserDefaults 저장을 위한 확장
extension UserDefaults {
    private static let scheduleKey = "savedSchedules"
    
    func saveSchedules(_ schedules: [Schedule]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(schedules) {
            self.set(encoded, forKey: UserDefaults.scheduleKey)
            self.synchronize() // 명시적 동기화 추가
        }
    }
    
    func loadSchedules() -> [Schedule] {
        if let data = self.data(forKey: UserDefaults.scheduleKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Schedule].self, from: data) {
                return decoded
            }
        }
        return []
    }
    
    // 특정 날짜에 일정이 있는지 확인하는 메서드
    func hasSchedule(on date: Date) -> Bool {
        let schedules = loadSchedules()
        let calendar = Calendar.current
        
        return schedules.contains { schedule in
            return calendar.isDate(schedule.date, inSameDayAs: date)
        }
    }
}


