//
//  ScheduleAddViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/22/25.
//

import Foundation
import RxSwift
import RxCocoa

class ScheduleAddViewModel: BaseViewModel {
    
    // MARK: - Properties
    var disposeBag = DisposeBag()
    
    // 컬러 팔레트
    let colors = [
        "FF6A6A", // 메인 색상(분홍)
        "42A5F5", // 액션 색상(파랑)
        "FFC107", // 노랑
        "8BC34A", // 초록
        "9C27B0", // 보라
        "FF9800", // 주황
        "607D8B", // 회색
        "E91E63"  // 진한 분홍
    ]
    
    // 선택된 컬러 인덱스
    let selectedColorIndex = BehaviorRelay<Int>(value: 0)
    
    // 날짜 포맷터
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    // MARK: - Input & Output
    struct Input {
        let title: Observable<String>
        let date: Observable<Date>
        let type: Observable<Int>
        let saveTap: Observable<Void>
    }
    
    struct Output {
        let isValidForm: Driver<Bool>
        let saveResult: Driver<Bool>
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        // 유효성 검사
        let isValidForm = input.title
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: false)
        
        // 저장 결과
        let saveResult = input.saveTap
            .withLatestFrom(
                Observable.combineLatest(
                    input.title,
                    input.date,
                    input.type,
                    selectedColorIndex.asObservable()
                )
            )
            .map { [weak self] (title, date, typeIndex, colorIndex) -> Bool in
                guard let self = self, !title.isEmpty else { return false }
                
                let scheduleTypes: [Schedule.ScheduleType] = [
                    .hospital, .vaccination, .medicine, .checkup, .other
                ]
                
                let schedule = Schedule(
                    title: title,
                    date: date,
                    type: scheduleTypes[typeIndex],
                    color: self.colors[colorIndex]
                )
                
                // 일정 저장
                ScheduleManager.shared.addSchedule(schedule)
                return true
            }
            .asDriver(onErrorJustReturn: false)
        
        return Output(
            isValidForm: isValidForm,
            saveResult: saveResult
        )
    }
}
