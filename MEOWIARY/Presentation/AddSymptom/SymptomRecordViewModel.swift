//
//  SymptomRecordViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/7/25.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class SymptomRecordViewModel: BaseViewModel {
    
    var disposeBag = DisposeBag()
    private let imageManager = ImageManager.shared
    private let imageRecordRepository = ImageRecordRepository()
    private let symptomRepository = SymptomRepository()
    private var currentDate = Date()
    private let toastMessageRelay = PublishRelay<String>()
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let saveButtonTap: Observable<Void>
        let symptomName: Observable<String>
        let severityValue: Observable<Int>
        let notes: Observable<String>
        let selectedImages: Observable<[UIImage]>
    }
    
    struct Output {
        let currentDateText: Driver<String>
        let dayOfWeekText: Driver<String>
        let isLoading: Driver<Bool>
        let saveSuccess: Driver<Void>
        let saveError: Driver<Error>
        let toastMessage: Driver<String>
    }
    
    init() {
        self.currentDate = Date()
    }
    
    // 특정 날짜 지정 생성자
    init(year: Int, month: Int, day: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        // DateComponents로부터 Date 객체 생성
        if let date = Calendar.current.date(from: dateComponents) {
            self.currentDate = date
        } else {
            // 잘못된 날짜인 경우 현재 날짜로 대체
            self.currentDate = Date()
            print("경고: 잘못된 날짜 정보입니다. 현재 날짜로 대체합니다.")
        }
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let saveSuccessRelay = PublishRelay<Void>()
        let saveErrorRelay = PublishRelay<Error>()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        let currentDateText = dateFormatter.string(from: currentDate)
        
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekText = dateFormatter.string(from: currentDate)
        
        // 저장 버튼 클릭 시 처리
        input.saveButtonTap
            .withLatestFrom(Observable.combineLatest(
                input.symptomName,
                input.severityValue,
                input.notes,
                input.selectedImages
            ))
            .flatMap { [weak self] (name, severity, notes, selectedImages) -> Observable<Void> in
                guard let self = self else { return Observable.empty() }
                
                // 유효성 검사: 증상명이 비어있으면 토스트 메시지 발송
                if name.isEmpty {
                    self.toastMessageRelay.accept("증상명을 입력해주세요.")
                    return Observable.empty()
                }
                
                isLoadingRelay.accept(true)
                
                // 새 증상 객체 생성
                let symptom = Symptom(name: name, description: notes, severity: severity)
                
                let saveOperation: Observable<Void>
                
                if selectedImages.isEmpty {
                    // 이미지 없이 증상만 저장
                    saveOperation = self.symptomRepository.saveSymptom(symptom, for: self.currentDate)
                        .map { _ in () }
                } else {
                    // 이미지와 함께 증상 저장
                    saveOperation = Observable.create { observer in
                        // 먼저 증상 저장
                        self.symptomRepository.saveSymptom(symptom, for: self.currentDate)
                            .flatMap { savedSymptom -> Observable<Void> in
                                // 이미지 저장
                                let imageRecordObservables = selectedImages.map { image in
                                    self.imageManager.saveImage(image)
                                        .flatMap { imageRecord in
                                            self.imageRecordRepository.saveImageRecord(imageRecord)
                                        }
                                }
                                
                                return Observable.zip(imageRecordObservables)
                                    .flatMap { imageRecords -> Observable<Void> in
                                        // 날짜로 DayCard 검색
                                        let calendar = Calendar.current
                                        let year = calendar.component(.year, from: self.currentDate)
                                        let month = calendar.component(.month, from: self.currentDate)
                                        let day = calendar.component(.day, from: self.currentDate)
                                        
                                        if let dayCard = self.symptomRepository.dayCardRepository.getDayCardForDate(year: year, month: month, day: day) {
                                            return self.symptomRepository.dayCardRepository.addImageRecord(imageRecords, to: dayCard)
                                        } else {
                                            return Observable.error(NSError(domain: "SymptomRecordViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "DayCard를 찾을 수 없습니다"]))
                                        }
                                    }
                            }
                            .subscribe(
                                onNext: {
                                    observer.onNext(())
                                    observer.onCompleted()
                                },
                                onError: { error in
                                    observer.onError(error)
                                }
                            )
                            .disposed(by: self.disposeBag)
                        
                        return Disposables.create()
                    }
                }
                
                return saveOperation
                    .do(
                        onNext: { _ in
                            isLoadingRelay.accept(false)
                            saveSuccessRelay.accept(())
                            
                            // 저장 성공 시 알림 발송
                            let calendar = Calendar.current
                            let year = calendar.component(.year, from: self.currentDate)
                            let month = calendar.component(.month, from: self.currentDate)
                            let day = calendar.component(.day, from: self.currentDate)
                            
                            // 변경된 날짜 정보와 함께 알림 발송
                            NotificationCenter.default.post(
                                name: Notification.Name(DayCardUpdatedNotification),
                                object: nil,
                                userInfo: ["year": year, "month": month, "day": day]
                            )
                        },
                        onError: { error in
                            isLoadingRelay.accept(false)
                            saveErrorRelay.accept(error)
                        }
                    )
            }
            .subscribe(
                onNext: { _ in print("증상 저장 성공") },
                onError: { error in print("에러 발생: \(error)") }
            )
            .disposed(by: disposeBag)
        
        return Output(
            currentDateText: Driver.just(currentDateText),
            dayOfWeekText: Driver.just(dayOfWeekText),
            isLoading: isLoadingRelay.asDriver(),
            saveSuccess: saveSuccessRelay.asDriver(onErrorDriveWith: .empty()),
            saveError: saveErrorRelay.asDriver(onErrorDriveWith: .empty()),
            toastMessage: toastMessageRelay.asDriver(onErrorJustReturn: "")
        )
    }
}
