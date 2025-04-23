//
//  AnalyticsService.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/23/25.
//

import FirebaseCore
import FirebaseAnalytics

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    // 화면 조회 로깅
    func logScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
        
        print("Analytics: 화면 조회 - \(screenName)")
    }
    
    // 일기 작성 이벤트 추적
    func logDiaryCreated(date: Date, hasImages: Bool, hasText: Bool, imageCount: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        Analytics.logEvent("diary_created", parameters: [
            "date": dateString,
            "has_images": hasImages,
            "has_text": hasText,
            "image_count": imageCount,
            "weekday": Calendar.current.component(.weekday, from: date)
        ])
        
        print("Analytics: 일기 작성 - 날짜: \(dateString), 이미지 \(imageCount)개")
    }
    
    // 일정 추가 이벤트 추적
    func logScheduleAdded(title: String, scheduleType: String, date: Date, daysFromNow: Int, color: String) {
        Analytics.logEvent("schedule_added", parameters: [
            "schedule_type": scheduleType,
            "days_from_now": daysFromNow,
            "has_title": !title.isEmpty,
            "color_selected": color,
            "weekday": Calendar.current.component(.weekday, from: date)
        ])
        
        print("Analytics: 일정 추가 - 타입: \(scheduleType), D-day: \(daysFromNow)")
    }
    
    // 증상 기록 이벤트 추적
    func logSymptomRecorded(symptomName: String, severity: Int, date: Date, hasImages: Bool, imageCount: Int, hasNotes: Bool) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        Analytics.logEvent("symptom_recorded", parameters: [
            "symptom_name": symptomName,
            "severity": severity,
            "date": dateString,
            "has_images": hasImages,
            "image_count": imageCount,
            "has_notes": hasNotes,
            "weekday": Calendar.current.component(.weekday, from: date)
        ])
        
        print("Analytics: 증상 기록 - 이름: \(symptomName), 심각도: \(severity)")
    }
    

    // 병원 검색 시작 이벤트
    func logHospitalSearchStarted(useCurrentLocation: Bool, manualLocation: Bool) {
        Analytics.logEvent("hospital_search_started", parameters: [
            "use_current_location": useCurrentLocation,
            "manual_location": manualLocation
        ])
        
        print("Analytics: 병원 검색 시작 - 현재 위치 사용: \(useCurrentLocation)")
    }

    // 병원 검색 결과 이벤트
    func logHospitalSearchResults(resultsCount: Int, latitude: Double, longitude: Double, searchDuration: TimeInterval) {
        Analytics.logEvent("hospital_search_results", parameters: [
            "results_count": resultsCount,
            "has_results": resultsCount > 0,
            "latitude": latitude,
            "longitude": longitude,
            "search_duration_seconds": searchDuration
        ])
        
        print("Analytics: 병원 검색 결과 - \(resultsCount)개 발견")
    }

    // 병원 상세정보 조회 이벤트
    func logHospitalDetailViewed(hospitalName: String, distance: String) {
        Analytics.logEvent("hospital_detail_viewed", parameters: [
            "hospital_name": hospitalName,
            "distance": distance
        ])
        
        print("Analytics: 병원 상세정보 조회 - \(hospitalName)")
    }

    // 병원 네비게이션 요청 이벤트
    func logHospitalNavigationRequested(hospitalName: String, distance: String, latitude: Double, longitude: Double) {
        Analytics.logEvent("hospital_navigation_requested", parameters: [
            "hospital_name": hospitalName,
            "distance": distance,
            "latitude": latitude,
            "longitude": longitude
        ])
        
        print("Analytics: 병원 네비게이션 요청 - \(hospitalName)")
    }

    // 병원 전화걸기 이벤트
    func logHospitalPhoneCall(hospitalName: String, phoneNumber: String) {
        Analytics.logEvent("hospital_phone_call", parameters: [
            "hospital_name": hospitalName,
            "phone_number": phoneNumber.replacingOccurrences(of: "-", with: "")
        ])
        
        print("Analytics: 병원 전화걸기 - \(hospitalName)")
    }
    
    func logAddressSearch(query: String, resultsCount: Int) {
        Analytics.logEvent("address_search", parameters: [
            "query": query,
            "results_count": resultsCount,
            "has_results": resultsCount > 0
        ])
        
        print("Analytics: 주소 검색 - 검색어: \(query), 결과: \(resultsCount)개")
    }

    func logAddressSelected(addressName: String) {
        Analytics.logEvent("address_selected", parameters: [
            "address_name": addressName
        ])
        
        print("Analytics: 주소 선택 - \(addressName)")
    }
}
