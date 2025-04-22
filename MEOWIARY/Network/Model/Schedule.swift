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
            self.synchronize()
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

// App Group 설정을 위한 유틸리티
class ScheduleManager {
    static let shared = ScheduleManager()
    private let userDefaults: UserDefaults
    
    private init() {
        // App Group UserDefaults 설정
        if let groupUserDefaults = UserDefaults(suiteName: "group.com.kwonws.meowiary") {
            self.userDefaults = groupUserDefaults
        } else {
            self.userDefaults = UserDefaults.standard
        }
    }
    
    // 일정 저장
    func saveSchedules(_ schedules: [Schedule]) {
        userDefaults.saveSchedules(schedules)
    }
    
    // 일정 불러오기
    func loadSchedules() -> [Schedule] {
        return userDefaults.loadSchedules()
    }
    
    // 새 일정 추가
    func addSchedule(_ schedule: Schedule) {
        var schedules = loadSchedules()
        schedules.append(schedule)
        saveSchedules(schedules)
    }
    
    // 일정 삭제
    func deleteSchedule(withId id: String) {
        var schedules = loadSchedules()
        schedules.removeAll { $0.id == id }
        saveSchedules(schedules)
    }
    
    // 가장 가까운 일정 가져오기
    func getUpcomingSchedules(limit: Int = 5) -> [Schedule] {
        let schedules = loadSchedules()
        let now = Date()
        
        // 미래 일정만 필터링하고 날짜순으로 정렬
        let upcoming = schedules.filter { $0.date >= now }
            .sorted { $0.date < $1.date }
        
        // 지정된 개수만큼 반환
        if limit > 0 && upcoming.count > limit {
            return Array(upcoming.prefix(limit))
        }
        return upcoming
    }
    
    // 특정 날짜에 일정이 있는지 확인
    func hasSchedule(on date: Date) -> Bool {
        return userDefaults.hasSchedule(on: date)
    }
}
