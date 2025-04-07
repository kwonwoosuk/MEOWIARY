//
//  DetailViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/6/25.
//


import UIKit
import RxSwift
import RxCocoa
import RealmSwift

final class DetailViewModel: BaseViewModel {
    
    // MARK: - Properties
    var disposeBag = DisposeBag()
    let year: Int
     let month: Int
     let day: Int
    let imageManager: ImageManager
    private let dayCardRepository = DayCardRepository()
    private let imageRecordRepository = ImageRecordRepository()
    private let imageRecordsRelay = BehaviorRelay<[ImageRecord]>(value: [])
    private let currentIndexRelay = BehaviorRelay<Int>(value: 0)
    private let notesRelay = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Input & Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let favoriteButtonTap: Observable<Void>
        let shareButtonTap: Observable<Void>
        let deleteButtonTap: Observable<Void>
        let currentIndex: Observable<Int>
    }
    
    struct Output {
        let imageRecords: Driver<[ImageRecord]>
           let dateText: Driver<String>
           let isFavorite: Driver<Bool>
           let notesText: Driver<String?>
           let deleteConfirmed: AnyObserver<Void>
           let deleteSuccess: Driver<Void>
    }
    
    // MARK: - Initialization
    init(year: Int, month: Int, day: Int, imageManager: ImageManager) {
        self.year = year
        self.month = month
        self.day = day
        self.imageManager = imageManager
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
        
        // 즐겨찾기 토글
        input.favoriteButtonTap
            .withLatestFrom(currentIndexRelay)
            .subscribe(onNext: { [weak self] index in
                guard let self = self,
                      index < self.imageRecordsRelay.value.count else { return }
                
                let imageRecord = self.imageRecordsRelay.value[index]
                self.imageRecordRepository.toggleFavorite(imageId: imageRecord.id)
                    .subscribe(onNext: { [weak self] in
                        self?.loadData() // 데이터 갱신
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
        
        // 공유 버튼 - ViewModel에서는 현재 이미지 정보만 제공
        let currentImageRecord = Observable.combineLatest(imageRecordsRelay, currentIndexRelay)
            .map { records, index -> ImageRecord? in
                guard index < records.count else { return nil }
                return records[index]
            }
        
        // 삭제 버튼 - 비즈니스 로직은 ViewModel에서 처리하되 실행은 외부 트리거로
        let deleteConfirmed = PublishSubject<Void>()
        
        let deleteResult = deleteConfirmed
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return Observable.just(()) }
                return self.deleteCurrentDayCards()
            }
            .share()
        
        let deleteSuccess = deleteResult
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())
        
        // 날짜 포맷팅
        let dateText = "\(year)년 \(month)월 \(day)일"
        
        // 현재 이미지의 즐겨찾기 상태
        let isFavorite = Observable.combineLatest(imageRecordsRelay, currentIndexRelay)
            .map { records, index -> Bool in
                guard index < records.count else { return false }
                return records[index].isFavorite
            }
        
        return Output(
            imageRecords: imageRecordsRelay.asDriver(),
            dateText: Driver.just(dateText),
            isFavorite: isFavorite.asDriver(onErrorJustReturn: false),
            notesText: notesRelay.asDriver(),
            deleteConfirmed: deleteConfirmed.asObserver(),
            deleteSuccess: deleteSuccess
        )
    }
    
  
  func deleteCurrentDayCards() -> Observable<Void> {
      // 현재 날짜의 DayCard ID들을 먼저 가져옵니다
      let dayCards = dayCardRepository.getDayCards(year: year, month: month)
      let targetDayCards = dayCards.filter { $0.day == day }
      
      if targetDayCards.isEmpty {
          return Observable.error(NSError(domain: "DetailViewModel",
                                         code: -1,
                                         userInfo: [NSLocalizedDescriptionKey: "삭제할 DayCard를 찾을 수 없습니다"]))
      }
      
      // 객체 참조 대신 ID만 저장
      let dayCardIDs = targetDayCards.map { $0.id }
      
      // ID를 기반으로 삭제 요청
      return dayCardRepository.deleteDayCardsByIDs(dayCardIDs)
  }
    // MARK: - Private Methods
    private func loadData() {
        let dayCards = dayCardRepository.getDayCards(year: year, month: month)
        let targetDayCards = dayCards.filter { $0.day == day }
        
        var allImageRecords: [ImageRecord] = []
        var notes: String?
        
        for dayCard in targetDayCards {
            allImageRecords.append(contentsOf: dayCard.imageRecords)
            if notes == nil, let dayCardNotes = dayCard.notes, !dayCardNotes.isEmpty {
                notes = dayCardNotes
            }
        }
        
        imageRecordsRelay.accept(allImageRecords)
        notesRelay.accept(notes)
    }
}
