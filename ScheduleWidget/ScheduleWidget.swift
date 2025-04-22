//
//  ScheduleWidget.swift
//  ScheduleWidget
//
//  Created by 권우석 on 4/22/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), schedules: getSampleSchedules())
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> ()) {
        let entry = ScheduleEntry(date: Date(), schedules: getUpcomingSchedules())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = ScheduleEntry(date: Date(), schedules: getUpcomingSchedules())
        
        // 다음 날 자정에 업데이트 (D-day 계산을 위해)
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(24 * 60 * 60))
        
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
    
    // 임시 샘플 데이터
    private func getSampleSchedules() -> [Schedule] {
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        let twoWeeksLater = Calendar.current.date(byAdding: .day, value: 14, to: today)!
        
        return [
            Schedule(title: "예방접종 일정", date: nextWeek, type: .vaccination, color: "FF6A6A"),
            Schedule(title: "정기 검진", date: twoWeeksLater, type: .checkup, color: "42A5F5")
        ]
    }
    
    // 실제 일정 데이터 가져오기
    private func getUpcomingSchedules() -> [Schedule] {
        // App Group을 통해 UserDefaults 접근
        guard let sharedUserDefaults = UserDefaults(suiteName: "group.com.kwonws.meowiary") else {
            return getSampleSchedules()
        }
        
        // 일정 불러오기
        if let data = sharedUserDefaults.data(forKey: "savedSchedules") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Schedule].self, from: data) {
                // 현재 날짜 이후의 일정만 필터링 & 날짜순 정렬
                let now = Date()
                return decoded.filter { $0.date >= now }
                    .sorted { $0.date < $1.date }
            }
        }
        
        return getSampleSchedules()
    }
}

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let schedules: [Schedule]
}

struct ScheduleWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 10) {
                // 왼쪽: 오늘 날짜
                VStack(alignment: .center) {
                    Text("\(Calendar.current.component(.day, from: Date()))")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(weekdayString())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 70)
                .padding(.vertical, 10)
                
                Rectangle()
                    .fill(Color.pink)
                    .frame(width: 2)
                    .padding(.vertical, 10)
                
                // 오른쪽: 일정 목록
                VStack(alignment: .leading, spacing: 8) {
                    if entry.schedules.isEmpty {
                        Text("예정된 일정이 없습니다")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // 가장 가까운 일정 표시 (최대 2개)
                        ForEach(Array(entry.schedules.prefix(family == .systemSmall ? 1 : 2).enumerated()), id: \.element.id) { _, schedule in
                            ScheduleRow(schedule: schedule)
                        }
                    }
                }
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
        }
    }
    
    func weekdayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
}

struct ScheduleRow: View {
    let schedule: Schedule
    
    var body: some View {
        HStack {
            // 일정 색상 표시
            Circle()
                .fill(Color(UIColor(named: schedule.color) ?? UIColor.gray))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(formatDate(schedule.date))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // Date 포맷팅 함수 추가
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: date)
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

struct ScheduleWidget_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleWidgetEntryView(entry: ScheduleEntry(
            date: Date(),
            schedules: [
                Schedule(title: "예방접종", date: Date().addingTimeInterval(60*60*24*3), type: .vaccination, color: "FF6A6A"),
                Schedule(title: "정기 검진", date: Date().addingTimeInterval(60*60*24*7), type: .checkup, color: "42A5F5")
            ]
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
