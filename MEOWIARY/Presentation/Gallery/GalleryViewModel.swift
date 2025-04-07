//
//  GalleryViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class GalleryViewModel: BaseViewModel {
  
  // MARK: - Properties
  var disposeBag = DisposeBag()
  let imageManager = ImageManager.shared
  private let dayCardRepository = DayCardRepository()
  private let imageRecordRepository = ImageRecordRepository()
  private let imagesRelay = BehaviorRelay<[ImageData]>(value: [])
  private let allImagesRelay = BehaviorRelay<[ImageData]>(value: [])
  
  // 현재 선택된 년/월
  private var currentYear: Int = Calendar.current.component(.year, from: Date())
  private var currentMonth: Int = Calendar.current.component(.month, from: Date())
  
  // 이미지 데이터 타입 정의
  struct ImageData: Equatable {
    let id: String
    let originalPath: String
    let thumbnailPath: String
    let isFavorite: Bool
    let createdAt: Date
    let dayCardId: String?  // 관련 DayCard ID
    let notes: String?      // 노트 내용 추가
    let year: Int
    let month: Int
    let day: Int
    
    static func == (lhs: ImageData, rhs: ImageData) -> Bool {
      return lhs.id == rhs.id
    }
  }
  
  // MARK: - Input & Output
  struct Input {
    let viewDidLoad: Observable<Void>
    let yearMonthSelected: Observable<(Int, Int)>
    let toggleFavoriteFilter: Observable<Bool>
  }
  
  struct Output {
    let images: Driver<[ImageData]>
    let isEmpty: Driver<Bool>
  }
  
  // MARK: - Transform
  func transform(input: Input) -> Output {
    // 최초 이미지 데이터 로드
    input.viewDidLoad
      .flatMap { [weak self] _ -> Observable<[ImageData]> in
        guard let self = self else { return Observable.just([]) }
        return self.loadImageData(year: self.currentYear, month: self.currentMonth)
      }
      .subscribe(onNext: { [weak self] images in
        guard let self = self else { return }
        self.allImagesRelay.accept(images)
        self.imagesRelay.accept(images)
      })
      .disposed(by: disposeBag)
    
    // 년월 선택 시 필터링
    input.yearMonthSelected
      .subscribe(onNext: { [weak self] (year, month) in
        guard let self = self else { return }
        self.currentYear = year
        self.currentMonth = month
        
        self.loadImageData(year: year, month: month)
          .subscribe(onNext: { [weak self] images in
            self?.allImagesRelay.accept(images)
            self?.imagesRelay.accept(images)
          })
          .disposed(by: self.disposeBag)
      })
      .disposed(by: disposeBag)
    
    // 즐겨찾기 필터링
    input.toggleFavoriteFilter
      .withLatestFrom(allImagesRelay) { (isFilteringFavorites, allImages) -> [ImageData] in
        if isFilteringFavorites {
          return allImages.filter { $0.isFavorite }
        } else {
          return allImages
        }
      }
      .subscribe(onNext: { [weak self] filteredImages in
        self?.imagesRelay.accept(filteredImages)
      })
      .disposed(by: disposeBag)
    
    // 빈 상태 감지
    let isEmpty = imagesRelay.map { $0.isEmpty }
    
    return Output(
      images: imagesRelay.asDriver(),
      isEmpty: isEmpty.asDriver(onErrorJustReturn: true)
    )
  }
  
  // 특정 년/월의 데이터만 불러오기
  func refreshData(year: Int = Calendar.current.component(.year, from: Date()),
                   month: Int = Calendar.current.component(.month, from: Date())) {
    self.currentYear = year
    self.currentMonth = month
    
    loadImageData(year: year, month: month)
      .subscribe(onNext: { [weak self] images in
        guard let self = self else { return }
        self.allImagesRelay.accept(images)
        self.imagesRelay.accept(images)
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Methods
    private func loadImageData(year: Int, month: Int) -> Observable<[ImageData]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }
            
            let dayCards = self.dayCardRepository.getDayCards(year: year, month: month)
                .filter { $0.symptoms.isEmpty } // 증상이 없는 DayCard만
            
            var imageDataList: [ImageData] = []
            let groupedDayCards = Dictionary(grouping: dayCards, by: { $0.day })
            
            for (day, dayCardsInDay) in groupedDayCards.sorted(by: { $0.key > $1.key }) {
                if let firstDayCard = dayCardsInDay.first,
                   let firstImageRecord = firstDayCard.imageRecords.first,
                   let originalPath = firstImageRecord.originalImagePath,
                   let thumbnailPath = firstImageRecord.thumbnailImagePath {
                    
                    let fileExists = self.imageManager.checkImageFileExists(path: originalPath)
                    
                    if fileExists {
                        let imageData = ImageData(
                            id: firstImageRecord.id,
                            originalPath: originalPath,
                            thumbnailPath: thumbnailPath,
                            isFavorite: firstImageRecord.isFavorite,
                            createdAt: firstDayCard.date,
                            dayCardId: firstDayCard.id,
                            notes: firstDayCard.notes,
                            year: firstDayCard.year,
                            month: firstDayCard.month,
                            day: firstDayCard.day
                        )
                        imageDataList.append(imageData)
                    }
                }
            }
            
            observer.onNext(imageDataList)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
  
  // 즐겨찾기 토글
  func toggleFavorite(imageId: String) -> Observable<Void> {
    return imageRecordRepository.toggleFavorite(imageId: imageId)
      .do(onNext: { [weak self] in
        self?.refreshData(year: self?.currentYear ?? Calendar.current.component(.year, from: Date()),
                         month: self?.currentMonth ?? Calendar.current.component(.month, from: Date()))
      })
  }
}
