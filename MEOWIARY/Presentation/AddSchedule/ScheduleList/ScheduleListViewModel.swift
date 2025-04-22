//
//  ScheduleListViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/22/25.
//

import Foundation
import RxSwift
import RxCocoa
import WidgetKit

class ScheduleListViewModel: BaseViewModel {
    
    // MARK: - Properties
    var disposeBag = DisposeBag()
    
    // 일정 데이터
    private let schedulesRelay = BehaviorRelay<[Schedule]>(value: [])
    var schedules: Driver<[Schedule]> {
        return schedulesRelay.asDriver()
    }
    
    // 빈 상태 확인
    var isEmpty: Driver<Bool> {
        return schedulesRelay.map { $0.isEmpty }.asDriver(onErrorJustReturn: true)
    }
    
    // 마지막 데이터 갱신 시간
    private var lastRefreshTime = Date()
    
    // 알림 구독
    private var notificationObserver: NSObjectProtocol?
    
    init() {
        setupNotifications()
    }
    
    deinit {
        // 알림 구독 해제
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Input & Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let deleteSchedule: Observable<Int>
    }
    
    struct Output {
        let schedules: Driver<[Schedule]>
        let isEmpty: Driver<Bool>
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        // 일정 데이터 변경 알림 구독
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ScheduleDataChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadSchedules()
        }
    }
    
    // MARK: - Public Methods
    func loadSchedules() {
        // ScheduleManager에서 일정 가져오기
        let schedules = ScheduleManager.shared.loadSchedules()
        
        // 날짜 기준으로 정렬 (가까운 일정 먼저)
        let sortedSchedules = schedules.sorted { $0.date < $1.date }
        
        print("일정 로드됨: 총 \(sortedSchedules.count)개")
        
        // 갱신 시간 업데이트
        lastRefreshTime = Date()
        
        // UI 업데이트를 위해 메인 스레드에서 처리
        DispatchQueue.main.async { [weak self] in
            self?.schedulesRelay.accept(sortedSchedules)
        }
    }
    
    func deleteSchedule(at index: Int) {
        var currentSchedules = schedulesRelay.value
        
        // 인덱스가 유효한지 확인
        guard index >= 0 && index < currentSchedules.count else { return }
        
        // 삭제할 일정 ID 가져오기
        let scheduleId = currentSchedules[index].id
        
        // ScheduleManager에서 삭제
        ScheduleManager.shared.deleteSchedule(withId: scheduleId)
        
        // 로컬 배열에서도 삭제
        currentSchedules.remove(at: index)
        schedulesRelay.accept(currentSchedules)
        
        // 위젯 업데이트 요청
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func schedule(at index: Int) -> Schedule? {
        let schedules = schedulesRelay.value
        guard index >= 0 && index < schedules.count else { return nil }
        return schedules[index]
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        // 로드 이벤트 처리
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.loadSchedules()
            })
            .disposed(by: disposeBag)
        
        // 삭제 이벤트 처리
        input.deleteSchedule
            .subscribe(onNext: { [weak self] index in
                self?.deleteSchedule(at: index)
            })
            .disposed(by: disposeBag)
        
        return Output(
            schedules: schedulesRelay.asDriver(),
            isEmpty: schedulesRelay.map { $0.isEmpty }.asDriver(onErrorJustReturn: true)
        )
    }
}
