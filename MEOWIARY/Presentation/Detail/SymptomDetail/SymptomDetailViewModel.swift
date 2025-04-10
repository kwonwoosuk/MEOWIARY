//
//  SymptomDetailViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/7/25.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift

final class SymptomDetailViewModel: BaseViewModel {
    
    // MARK: - Properties
    var disposeBag = DisposeBag()
    let year: Int
    let month: Int
    let day: Int
    let imageManager: ImageManager
    private let symptomRepository = SymptomRepository()
    private let dayCardRepository = DayCardRepository()
    let symptomsRelay = BehaviorRelay<[Symptom]>(value: [])
    let imageRecordsRelay = BehaviorRelay<[ImageRecord]>(value: [])
    private let currentIndexRelay = BehaviorRelay<Int>(value: 0)
    private let notesRelay = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Input & Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let deleteButtonTap: Observable<Void>
        let shareButtonTap: Observable<Void>
        let currentIndex: Observable<Int>
    }
    
    struct Output {
        let symptoms: Driver<[Symptom]>
        let imageRecords: Driver<[ImageRecord]>
        let dateText: Driver<String>
        let currentSymptom: Driver<Symptom?>
        let notesText: Driver<String?>
        let deleteConfirmed: AnyObserver<Void>
        let deleteSuccess: Driver<[(String?, String?)]>
    }
    
    // MARK: - Initialization
    init(year: Int, month: Int, day: Int, imageManager: ImageManager) {
        self.year = year
        self.month = month
        self.day = day
        self.imageManager = imageManager
    }
    
    func reloadData() {
        loadData()
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        // 데이터 로드
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.loadData()
            })
            .disposed(by: disposeBag)
        
        // 현재 인덱스 업데이트
        input.currentIndex
            .subscribe(onNext: { [weak self] index in
                self?.currentIndexRelay.accept(index)
            })
            .disposed(by: disposeBag)
        
        // 삭제 버튼 - 비즈니스 로직은 ViewModel에서 처리하되 실행은 외부 트리거로
        let deleteConfirmed = PublishSubject<Void>()
        
        // 삭제 전에 이미지 경로 정보 복사
        let pathsRelay = BehaviorRelay<[(String?, String?)]>(value: [])
        
        // 삭제 결과 처리
        let deleteResult = deleteConfirmed
            .do(onNext: { [weak self] _ in
                // 중요: 삭제 전에 이미지 경로 정보 복사하여 저장
                guard let self = self else { return }
                let paths = self.preparePathsForDeletion()
                pathsRelay.accept(paths)
            })
            .flatMap { [weak self] _ -> Observable<[(String?, String?)]> in
                guard let self = self else { return Observable.just([]) }
                return self.deleteCurrentSymptoms()
                    .map { _ in pathsRelay.value } // 삭제 성공 시 저장된 경로 정보 반환
                    .catchError { error in
                        print("삭제 중 에러 발생: \(error)")
                        return Observable.just([]) // 에러 발생 시 빈 배열 반환
                    }
            }
            .share()
        
        // 삭제 성공 시 경로 정보 반환
        let deleteSuccess = deleteResult
            .asDriver(onErrorJustReturn: [])
        
        // 날짜 포맷팅
        let dateText = "\(year)년 \(month)월 \(day)일"
        
        // 현재 증상 정보
        let currentSymptom = Observable.combineLatest(symptomsRelay, currentIndexRelay)
            .map { symptoms, index -> Symptom? in
                guard !symptoms.isEmpty, index < symptoms.count else { return nil }
                return symptoms[index]
            }
        
        return Output(
            symptoms: symptomsRelay.asDriver(),
            imageRecords: imageRecordsRelay.asDriver(),
            dateText: Driver.just(dateText),
            currentSymptom: currentSymptom.asDriver(onErrorJustReturn: nil),
            notesText: notesRelay.asDriver(),
            deleteConfirmed: deleteConfirmed.asObserver(),
            deleteSuccess: deleteSuccess
        )
    }
    
    func getCurrentSymptom() -> Symptom? {
       
       if currentIndexRelay.value < symptomsRelay.value.count {
            return symptomsRelay.value[currentIndexRelay.value]
        }
        return nil
    }
    
    // 증상 삭제 메서드 - 별도 증상 이미지 테이블 사용
    func deleteCurrentSymptoms() -> Observable<Void> {
        let symptoms = symptomsRelay.value
        if symptoms.isEmpty {
            return Observable.error(NSError(domain: "SymptomDetailViewModel",
                                          code: -1,
                                          userInfo: [NSLocalizedDescriptionKey: "삭제할 증상을 찾을 수 없습니다"]))
        }
        
        // 해당 날짜의 DayCard 가져오기
        guard let dayCard = dayCardRepository.getDayCardForDate(year: year, month: month, day: day) else {
            return Observable.error(NSError(domain: "SymptomDetailViewModel",
                                          code: -2,
                                          userInfo: [NSLocalizedDescriptionKey: "DayCard를 찾을 수 없습니다"]))
        }
        
        // 증상 삭제 - 각 증상 삭제 시 증상 이미지도 함께 삭제
        let deleteSymptoms = Observable.merge(
            symptoms.map { symptom in
                self.symptomRepository.deleteSymptom(symptom)
            }
        )
        
        return deleteSymptoms
            .toArray()
            .asObservable()
            .map { _ in () }
            .flatMap { _ -> Observable<Void> in
                // 추가 정리 작업이 필요하면 여기서 수행
                
                // 삭제 후 알림 발송
                NotificationCenter.default.post(
                    name: Notification.Name(DayCardDeletedNotification),
                    object: nil,
                    userInfo: [
                        "year": self.year,
                        "month": self.month,
                        "day": self.day,
                        "isSymptom": true, // 증상 기록임을 표시
                        "forceReload": true
                    ]
                )
                return Observable.just(())
            }
    }
    
    // MARK: - Private Methods
    private func loadData() {
        // 해당 날짜의 증상 목록 로드
        let symptoms = symptomRepository.getSymptoms(year: year, month: month, day: day)
        symptomsRelay.accept(symptoms)
        
        // 증상 이미지를 ImageRecord 형식으로 변환하여 UI에 사용
        var imageRecords: [ImageRecord] = []
        
        for symptom in symptoms {
            for symptomImage in symptom.symptomImages {
                let imageRecord = ImageRecord()
                imageRecord.id = symptomImage.id
                imageRecord.originalImagePath = symptomImage.originalImagePath
                imageRecord.thumbnailImagePath = symptomImage.thumbnailImagePath
                imageRecord.createdAt = symptomImage.createdAt
                imageRecords.append(imageRecord)
            }
        }
        
        imageRecordsRelay.accept(imageRecords)
        
        // DayCard의 노트 정보가 있다면 로드
        if let dayCard = dayCardRepository.getDayCardForDate(year: year, month: month, day: day) {
            notesRelay.accept(dayCard.notes)
        }
    }
    
    func preparePathsForDeletion() -> [(String?, String?)] {
        // 모든 증상 이미지 경로 정보 수집
        var allPaths: [(String?, String?)] = []
        
        for symptom in symptomsRelay.value {
            for symptomImage in symptom.symptomImages {
                allPaths.append((symptomImage.originalImagePath, symptomImage.thumbnailImagePath))
            }
        }
        
        return allPaths
    }
}
