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
import RealmSwift

class SymptomRecordViewModel: BaseViewModel {
    
    var disposeBag = DisposeBag()
    private let imageManager = ImageManager.shared
    private let symptomRepository = SymptomRepository()
    private let symptomImageRepository = SymptomImageRepository() // 새로 추가
    private var currentDate = Date()
    private let toastMessageRelay = PublishRelay<String>()
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let saveButtonTap: Observable<Void>
        let symptomName: Observable<String>
        let severityValue: Observable<Int>
        let notes: Observable<String>
        let selectedImages: Observable<[UIImage]>
        let isEditMode: Observable<Bool>
        let editingSymptom: Observable<Symptom?>
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
            let editingSymptomRelay = BehaviorRelay<Symptom?>(value: nil)
            
            input.isEditMode
                .bind(to: isEditModeRelay)
                .disposed(by: disposeBag)
            
            input.editingSymptom
                .bind(to: editingSymptomRelay)
                .disposed(by: disposeBag)
        
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
                    input.selectedImages,
                    isEditModeRelay,
                    editingSymptomRelay
                ))
                .flatMap { [weak self] (name, severity, notes, selectedImages, isEditMode, editingSymptom) -> Observable<Void> in
                    guard let self = self else { return Observable.empty() }
                    
                    // 유효성 검사
                    if name.isEmpty {
                        self.toastMessageRelay.accept("증상명을 입력해주세요.")
                        return Observable.empty()
                    }
                    
                    isLoadingRelay.accept(true)
                    
                    // 수정 모드일 경우
                    if isEditMode, let symptom = editingSymptom {
                        return self.updateExistingSymptom(
                            symptom,
                            name: name,
                            severity: severity,
                            notes: notes,
                            images: selectedImages
                        )
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
                
                // 새 증상 객체 생성
                let symptom = Symptom(name: name, description: notes, severity: severity)
                
                // 이미지가 없는 경우와 있는 경우 처리 분리
                if selectedImages.isEmpty {
                    // 이미지 없이 증상만 저장
                    return self.symptomRepository.saveSymptom(symptom, for: self.currentDate)
                        .map { _ in () }
                        .do(
                            onNext: { [weak self] _ in
                                guard let self = self else { return }
                                isLoadingRelay.accept(false)
                                saveSuccessRelay.accept(())
                                
                                // Analytics 이벤트 로깅 
                                AnalyticsService.shared.logSymptomRecorded(
                                    symptomName: name,
                                    severity: severity,
                                    date: self.currentDate,
                                    hasImages: !selectedImages.isEmpty,
                                    imageCount: selectedImages.count,
                                    hasNotes: !notes.isEmpty
                                )
                                
                                // 증상 저장 성공 알림 발송
                                let calendar = Calendar.current
                                let year = calendar.component(.year, from: self.currentDate)
                                let month = calendar.component(.month, from: self.currentDate)
                                let day = calendar.component(.day, from: self.currentDate)
                                
                                NotificationCenter.default.post(
                                    name: Notification.Name(DayCardUpdatedNotification),
                                    object: nil,
                                    userInfo: [
                                        "year": year,
                                        "month": month,
                                        "day": day,
                                        "isSymptom": true
                                    ]
                                )
                            },
                            onError: { error in
                                isLoadingRelay.accept(false)
                                saveErrorRelay.accept(error)
                            }
                        )
                } else {
                    // 이미지가 있는 경우: 이미지 저장 후 증상 저장
                    return self.symptomRepository.saveSymptom(symptom, for: self.currentDate)
                        .flatMap { savedSymptom -> Observable<Void> in
                            // 각 이미지를 순차적으로 처리
                            let imageObservables = selectedImages.map { image -> Observable<Void> in
                                // 이미지 저장 및 SymptomImage 생성
                                return self.imageManager.saveImage(image)
                                    .flatMap { imageRecord -> Observable<SymptomImage> in
                                        let symptomImage = SymptomImage(
                                            originalImagePath: imageRecord.originalImagePath ?? "",
                                            thumbnailImagePath: imageRecord.thumbnailImagePath ?? ""
                                        )
                                        return self.symptomImageRepository.saveSymptomImage(symptomImage)
                                    }
                                    .flatMap { symptomImage -> Observable<Void> in
                                        // 각 이미지를 증상과 연결
                                        return self.symptomRepository.addSymptomImage(symptomImage, to: savedSymptom)
                                    }
                            }
                            
                            // 모든 이미지 처리가 완료되면 완료 신호 보내기
                            return Observable.concat(imageObservables)
                                .takeLast(1)
                                .map { _ in () }
                        }
                        .do(
                            onNext: { [weak self] _ in
                                guard let self = self else { return }
                                isLoadingRelay.accept(false)
                                saveSuccessRelay.accept(())
                                
                                // 증상 저장 성공 알림 발송
                                let calendar = Calendar.current
                                let year = calendar.component(.year, from: self.currentDate)
                                let month = calendar.component(.month, from: self.currentDate)
                                let day = calendar.component(.day, from: self.currentDate)
                                
                                NotificationCenter.default.post(
                                    name: Notification.Name(DayCardUpdatedNotification),
                                    object: nil,
                                    userInfo: [
                                        "year": year,
                                        "month": month,
                                        "day": day,
                                        "isSymptom": true
                                    ]
                                )
                            },
                            onError: { error in
                                isLoadingRelay.accept(false)
                                saveErrorRelay.accept(error)
                            }
                        )
                }
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
    private func updateExistingSymptom(_ symptom: Symptom, name: String, severity: Int, notes: String, images: [UIImage]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "SymptomRecordViewModel", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            let realm: Realm
            do {
                realm = try Realm()
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
            
            // 1. 기본 정보 업데이트
            do {
                try realm.write {
                    symptom.name = name
                    symptom.severity = severity
                    symptom.notes = notes.isEmpty ? nil : notes
                }
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
            
            // 2. 이미지 처리
            // 모든 기존 이미지 참조 제거 후 새 이미지로 교체
            let oldSymptomImages = Array(symptom.symptomImages)
            
            do {
                try realm.write {
                    symptom.symptomImages.removeAll()
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
                    userInfo: [
                        "year": year,
                        "month": month,
                        "day": day,
                        "isSymptom": true
                    ]
                )
                
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 이미지 저장 배열 Observable 생성
            let imageObservables = images.map { image -> Observable<Void> in
                return self.imageManager.saveImage(image)
                    .flatMap { imageRecord -> Observable<SymptomImage> in
                        let symptomImage = SymptomImage(
                            originalImagePath: imageRecord.originalImagePath ?? "",
                            thumbnailImagePath: imageRecord.thumbnailImagePath ?? ""
                        )
                        return self.symptomImageRepository.saveSymptomImage(symptomImage)
                    }
                    .flatMap { symptomImage -> Observable<Void> in
                        do {
                            try realm.write {
                                symptom.symptomImages.append(symptomImage)
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
                            userInfo: [
                                "year": year,
                                "month": month,
                                "day": day,
                                "isSymptom": true
                            ]
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
}
