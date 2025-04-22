//
//  ScheduleWidget.swift
//  ScheduleWidget
//
//  Created by 권우석 on 4/22/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    // 그룹 UserDefaults 설정
    private let sharedDefaults = UserDefaults(suiteName: "group.com.kwonws.meowiary")
    
    func placeholder(in context: Context) -> ScheduleWidgetEntry {
        ScheduleWidgetEntry(
            date: Date(),
            schedules: [
                ScheduleItem(title: "예방접종", dDay: "D-3", color: "FF6A6A"),
                ScheduleItem(title: "건강검진", dDay: "D-7", color: "42A5F5")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleWidgetEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 현재 날짜
        let currentDate = Date()
        
        // 엔트리 가져오기
        let entry = getEntry()
        
        // 타임라인 생성 - 매일 자정에 업데이트
        let midnight = Calendar.current.startOfDay(for: currentDate.addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        
        completion(timeline)
    }
    
    // 엔트리 생성 메서드
    private func getEntry() -> ScheduleWidgetEntry {
        // 현재 날짜
        let currentDate = Date()
        
        // 상위 3개 일정 가져오기
        let topSchedules = getUpcomingSchedules(limit: 3)
        
        return ScheduleWidgetEntry(
            date: currentDate,
            schedules: topSchedules
        )
    }
    
    // 다음 일정 가져오기
    private func getUpcomingSchedules(limit: Int = 3) -> [ScheduleItem] {
        guard let data = sharedDefaults?.data(forKey: "savedSchedules") else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let schedules = try decoder.decode([Schedule].self, from: data)
            
            // 오늘 이후의 일정만 필터링하고 날짜순 정렬
            let currentDate = Date()
            let upcomingSchedules = schedules.filter { $0.date >= currentDate }
                                           .sorted { $0.date < $1.date }
                                           .prefix(limit)
            
            // ScheduleItem 형식으로 변환
            return upcomingSchedules.map { schedule in
                ScheduleItem(
                    title: schedule.title,
                    dDay: schedule.dDayText(),
                    color: schedule.color
                )
            }
        } catch {
            print("위젯 일정 데이터 디코딩 오류: \(error)")
            return []
        }
    }
}

struct ScheduleItem: Identifiable {
    let id = UUID()
    let title: String
    let dDay: String
    let color: String
}

struct ScheduleWidgetEntry: TimelineEntry {
    let date: Date
    let schedules: [ScheduleItem]
}

struct ScheduleWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // 위젯 크기에 따라 다른 레이아웃 표시
            if family == .systemSmall {
                smallWidgetLayout
            } else {
                mediumWidgetLayout
            }
        }
        .modifier(WidgetBackgroundModifier()) // 배경을 조건부로 설정
    }
    
    // 작은 위젯 레이아웃
    var smallWidgetLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 헤더 - 날짜 정보
            HStack(alignment: .bottom) {
                Text("\(Calendar.current.component(.day, from: Date()))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(weekdayString())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                }
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .padding(.vertical, 2)
            
            // 일정 목록
            if entry.schedules.isEmpty {
                Text("예정된 일정이 없습니다")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
            } else {
                ForEach(entry.schedules.prefix(1)) { schedule in
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(UIColor(hex: schedule.color) ?? .systemGray))
                            .frame(width: 4, height: 16)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(schedule.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                            
                            if !schedule.dDay.isEmpty {
                                Text(schedule.dDay)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 1)
                                    .background(Color(UIColor(hex: schedule.color) ?? .systemGray))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
    }
    
    // 중간 위젯 레이아웃
    var mediumWidgetLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 헤더 - 날짜 정보
            HStack(alignment: .bottom) {
                Text("\(Calendar.current.component(.day, from: Date()))")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                
                Text(weekdayString())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
                    .padding(.leading, 2)
                
                Spacer()
                
                Text(formatDate())
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .padding(.vertical, 4)
            
            // 일정 목록
            if entry.schedules.isEmpty {
                Text("예정된 일정이 없습니다")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
            } else {
                ForEach(entry.schedules.prefix(3)) { schedule in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(UIColor(hex: schedule.color) ?? .systemGray))
                            .frame(width: 4, height: 18)
                        
                        Text(schedule.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if !schedule.dDay.isEmpty {
                            Text(schedule.dDay)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor(hex: schedule.color) ?? .systemGray))
                                .cornerRadius(4)
                                .fixedSize()
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
    }
    
    // 요일 문자열
    private func weekdayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
    
    // 날짜 포맷
    private func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
}

// 배경 설정을 위한 ViewModifier
struct WidgetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .containerBackground(for: .widget) {
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                }
        } else {
            content
                .background(
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                )
        }
    }
}

struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("반려묘 일정")
        .description("예정된 병원 예약, 예방접종 일정을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// HEX 색상 변환을 위한 확장
extension UIColor {
    convenience init?(hex: String?) {
        guard let hex = hex else { return nil }
        
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
