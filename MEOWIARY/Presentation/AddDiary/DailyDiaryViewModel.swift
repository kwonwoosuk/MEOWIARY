//
//  DailyDiaryViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import RealmSwift

class DailyDiaryViewModel: BaseViewModel {
    
    var disposeBag = DisposeBag()
    private let imageManager = ImageManager.shared
    private let imageRecordRepository = ImageRecordRepository()
    private let dayCardRepository = DayCardRepository()
    private var currentDate = Date()
    private let toastMessageRelay = PublishRelay<String>()
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let saveButtonTap: Observable<Void>
        let diaryText: Observable<String>
        let selectedImages: Observable<[UIImage]>
        let isEditMode: Observable<Bool>
        let editingDayCard: Observable<DayCard?>
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
        let isEditModeRelay = BehaviorRelay<Bool>(value: false)
            let editingDayCardRelay = BehaviorRelay<DayCard?>(value: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        let currentDateText = dateFormatter.string(from: currentDate)
        
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekText = dateFormatter.string(from: currentDate)
        
        input.isEditMode
                .bind(to: isEditModeRelay)
                .disposed(by: disposeBag)
            
            input.editingDayCard
                .bind(to: editingDayCardRelay)
                .disposed(by: disposeBag)
        
        input.saveButtonTap
               .withLatestFrom(Observable.combineLatest(
                   input.diaryText,
                   input.selectedImages,
                   isEditModeRelay,
                   editingDayCardRelay
               ))
               .flatMap { [weak self] (diaryText, selectedImages, isEditMode, editingDayCard) -> Observable<Void> in
                   guard let self = self else { return Observable.just(()) }
                   
                   // 유효성 검사
                   if diaryText.isEmpty && selectedImages.isEmpty {
                       self.toastMessageRelay.accept("내용을 입력하거나 이미지를 추가해주세요.")
                       return Observable.empty()
                   }
                   
                   isLoadingRelay.accept(true)
                
                if isEditMode, let dayCard = editingDayCard {
                               return self.updateExistingDayCard(dayCard, text: diaryText, images: selectedImages)
                                   .do(
                                       onNext: { _ in
                                           isLoadingRelay.accept(false)
                                           saveSuccessRelay.accept(())
                                       },
                                       onError: { error in
                                           isLoadingRelay.accept(false)
                                           saveErrorRelay.accept(error)
                                       }
                                   )
                           }
                
                let calendar = Calendar.current
                let year = calendar.component(.year, from: self.currentDate)
                let month = calendar.component(.month, from: self.currentDate)
                let day = calendar.component(.day, from: self.currentDate)
                
                let dayCard = self.dayCardRepository.getDayCardForDate(year: year, month: month, day: day) ?? DayCard(date: self.currentDate)
                
                let saveOperation: Observable<Void>
                if selectedImages.isEmpty {
                    saveOperation = Observable.create { observer in
                        let realm: Realm
                        do {
                            realm = try Realm()
                        } catch {
                            observer.onError(error)
                            return Disposables.create()
                        }
                        do {
                            try realm.write {
                                dayCard.notes = diaryText.isEmpty ? nil : diaryText
                                realm.add(dayCard, update: .modified)
                            }
                            observer.onNext(())
                            observer.onCompleted()
                        } catch {
                            observer.onError(error)
                        }
                        return Disposables.create()
                    }
                } else {
                    saveOperation = Observable<Any>.create { observer in
                        let realm: Realm
                        do {
                            realm = try Realm()
                        } catch {
                            observer.onError(error)
                            return Disposables.create()
                        }
                        do {
                            try realm.write {
                                dayCard.notes = diaryText.isEmpty ? nil : diaryText
                                realm.add(dayCard, update: .modified)
                            }
                            observer.onNext(())
                            observer.onCompleted()
                        } catch {
                            observer.onError(error)
                        }
                        return Disposables.create()
                    }
                    .flatMap { _ -> Observable<Void> in
                        let imageRecordObservables = selectedImages.map { image in
                            self.imageManager.saveImage(image)
                                .flatMap { imageRecord in
                                    self.imageRecordRepository.saveImageRecord(imageRecord)
                                }
                        }
                        return Observable.zip(imageRecordObservables)
                            .flatMap { imageRecords in
                                self.dayCardRepository.addImageRecord(imageRecords, to: dayCard)
                            }
                    }
                }
                
                return saveOperation
                    .do(
                        onNext: { _ in
                            isLoadingRelay.accept(false)
                            saveSuccessRelay.accept(())
                            // Analytics 이벤트 로깅
                            AnalyticsService.shared.logDiaryCreated(
                                                    date: self.currentDate,
                                                    hasImages: !selectedImages.isEmpty,
                                                    hasText: !diaryText.isEmpty,
                                                    imageCount: selectedImages.count
                                                )
                            
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
                onNext: { _ in print("Save operation completed successfully") },
                onError: { error in print("Error occurred: \(error)") }
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
    
    private func updateExistingDayCard(_ dayCard: DayCard, text: String, images: [UIImage]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            let realm: Realm
            do {
                realm = try Realm()
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
            
            // 1. 텍스트 업데이트
            do {
                try realm.write {
                    dayCard.notes = text.isEmpty ? nil : text
                }
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
            
            // 2. 이미지 처리
            // 모든 기존 이미지 참조 제거 후 새 이미지로 교체
            let oldImageRecords = Array(dayCard.imageRecords)
            
            do {
                try realm.write {
                    dayCard.imageRecords.removeAll()
                }
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
            
            // 이미지가 있으면 저장, 없으면 바로 완료
            if images.isEmpty {
                // 변경 알림 발송
                let calendar = Calendar.current
                let year = calendar.component(.year, from: self.currentDate)
                let month = calendar.component(.month, from: self.currentDate)
                let day = calendar.component(.day, from: self.currentDate)
                
                NotificationCenter.default.post(
                    name: Notification.Name(DayCardUpdatedNotification),
                    object: nil,
                    userInfo: ["year": year, "month": month, "day": day]
                )
                
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 이미지 저장 배열 Observable 생성
            let imageObservables = images.map { image -> Observable<Void> in
                return self.imageManager.saveImage(image)
                    .flatMap { imageRecord in
                        return self.imageRecordRepository.saveImageRecord(imageRecord)
                    }
                    .flatMap { imageRecord -> Observable<Void> in
                        do {
                            try realm.write {
                                dayCard.imageRecords.append(imageRecord)
                            }
                            return Observable.just(())
                        } catch {
                            return Observable.error(error)
                        }
                    }
            }
            
            // 모든 이미지 저장 완료 후 성공 처리
            Observable.concat(imageObservables)
                .takeLast(1)
                .subscribe(
                    onNext: { _ in
                        // 변경 알림 발송
                        let calendar = Calendar.current
                        let year = calendar.component(.year, from: self.currentDate)
                        let month = calendar.component(.month, from: self.currentDate)
                        let day = calendar.component(.day, from: self.currentDate)
                        
                        NotificationCenter.default.post(
                            name: Notification.Name(DayCardUpdatedNotification),
                            object: nil,
                            userInfo: ["year": year, "month": month, "day": day]
                        )
                        
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
    
    private func saveWithImage(text: String, image: UIImage) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel is nil"]))
                return Disposables.create()
            }
            
            print("이미지 저장 시작")
            
            let imageRecordObservable = self.imageManager.saveImage(image)
                .flatMap { imageRecord -> Observable<ImageRecord> in
                    print("이미지 매니저에서 ImageRecord 생성됨: \(imageRecord.id)")
                    return self.imageRecordRepository.saveImageRecord(imageRecord)
                }
            
            let saveDayCardObservable = imageRecordObservable
                .flatMap { imageRecord -> Observable<Void> in
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: self.currentDate)
                    let month = calendar.component(.month, from: self.currentDate)
                    let day = calendar.component(.day, from: self.currentDate)
                    
                    let existingCard = self.dayCardRepository.getDayCardForDate(year: year, month: month, day: day)
                    let dayCard = existingCard ?? DayCard(date: self.currentDate)
                    
                    let realm: Realm
                    do {
                        realm = try Realm()
                    } catch {
                        return Observable.error(error)
                    }
                    do {
                        try realm.write {
                            dayCard.notes = text.isEmpty ? nil : text
                            if existingCard == nil { realm.add(dayCard) }
                            dayCard.imageRecords.append(imageRecord)
                        }
                        return Observable.just(())
                    } catch {
                        return Observable.error(error)
                    }
                }
            
            saveDayCardObservable
                .subscribe(
                    onNext: { _ in
                        print("DayCard 저장 완료 (이미지 포함)")
                        observer.onNext(())
                        observer.onCompleted()
                    },
                    onError: { error in
                        print("저장 오류: \(error)")
                        observer.onError(error)
                    }
                )
                .disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}
