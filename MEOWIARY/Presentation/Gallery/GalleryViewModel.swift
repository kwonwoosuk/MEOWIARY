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
  
  // 이미지 데이터 타입 정의
  struct ImageData: Equatable {
    let id: String
    let originalPath: String
    let thumbnailPath: String
    let isFavorite: Bool
    let createdAt: Date
    let dayCardId: String?  // 관련 DayCard ID
    let notes: String?      // 노트 내용 추가
    
    static func == (lhs: ImageData, rhs: ImageData) -> Bool {
      return lhs.id == rhs.id
    }
  }
  
  // MARK: - Input & Output
  struct Input {
    let viewDidLoad: Observable<Void>
    let toggleFavoriteFilter: Observable<Bool>
    let searchQuery: Observable<String>
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
        return self.loadImageData()
      }
      .subscribe(onNext: { [weak self] images in
        guard let self = self else { return }
        self.allImagesRelay.accept(images)
        self.imagesRelay.accept(images)
      })
      .disposed(by: disposeBag)
    
    // 즐겨찾기 필터링
    input.toggleFavoriteFilter
      .withLatestFrom(allImagesRelay) { (isFilteringFavorites, allImages) -> [ImageData] in
        if isFilteringFavorites {
          // 즐겨찾기된 항목만 필터링
          return allImages.filter { $0.isFavorite }
        } else {
          // 모든 항목 표시
          return allImages
        }
      }
      .subscribe(onNext: { [weak self] filteredImages in
        self?.imagesRelay.accept(filteredImages)
      })
      .disposed(by: disposeBag)
    
    // 검색 기능
    input.searchQuery
      .withLatestFrom(allImagesRelay) { (query, allImages) -> [ImageData] in
        guard !query.isEmpty else { return allImages }
        
        // 검색어로 필터링
        return allImages.filter { imageData in
          // 노트 내용에서 검색
          if let notes = imageData.notes, notes.lowercased().contains(query.lowercased()) {
            return true
          }
          
          // 날짜 문자열에서 검색
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy년 MM월 dd일"
          let dateString = dateFormatter.string(from: imageData.createdAt)
          if dateString.contains(query) {
            return true
          }
          
          return false
        }
      }
      .subscribe(onNext: { [weak self] searchResults in
        self?.imagesRelay.accept(searchResults)
      })
      .disposed(by: disposeBag)
    
    // 빈 상태 감지
    let isEmpty = imagesRelay.map { $0.isEmpty }
    
    return Output(
      images: imagesRelay.asDriver(),
      isEmpty: isEmpty.asDriver(onErrorJustReturn: true)
    )
  }
  
  func refreshData() {
    // 데이터 다시 로드
    loadImageData()
      .subscribe(onNext: { [weak self] images in
        guard let self = self else { return }
        self.allImagesRelay.accept(images)
        self.imagesRelay.accept(images)
      })
      .disposed(by: disposeBag)
  }
  
  // 검색 기능 추가
  func searchImages(query: String) {
    guard !query.isEmpty else {
      // 빈 검색어면 모든 이미지 표시
      imagesRelay.accept(allImagesRelay.value)
      return
    }
    
    let allImages = allImagesRelay.value
    let searchResults = allImages.filter { imageData in
      // 노트 내용에서 검색
      if let notes = imageData.notes, notes.lowercased().contains(query.lowercased()) {
        return true
      }
      
      // 날짜 문자열에서 검색
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy년 MM월 dd일"
      let dateString = dateFormatter.string(from: imageData.createdAt)
      if dateString.contains(query) {
        return true
      }
      
      return false
    }
    
    imagesRelay.accept(searchResults)
  }
  
  // MARK: - Methods
  private func loadImageData() -> Observable<[ImageData]> {
    return Observable.create { [weak self] observer in
      guard let self = self else {
        observer.onNext([])
        observer.onCompleted()
        return Disposables.create()
      }
      
      // Realm에서 모든 DayCard 가져오기
      let dayCards = self.dayCardRepository.getAllDayCards()
      
      // ImageData 배열 생성
      var imageDataList: [ImageData] = []
      
      for dayCard in dayCards {
        // imageRecords 리스트에서 모든 이미지 레코드 처리
        for imageRecord in dayCard.imageRecords {
          if let originalPath = imageRecord.originalImagePath,
             let thumbnailPath = imageRecord.thumbnailImagePath {
            
            let fileExists = self.imageManager.checkImageFileExists(path: originalPath)
            
            if fileExists {
              let imageData = ImageData(
                id: imageRecord.id,
                originalPath: originalPath,
                thumbnailPath: thumbnailPath,
                isFavorite: imageRecord.isFavorite,
                createdAt: dayCard.date,
                dayCardId: dayCard.id,
                notes: dayCard.notes
              )
              
              imageDataList.append(imageData)
            }
          }
        }
      }
      
      // 최신 이미지가 먼저 표시되도록 정렬
      let sortedList = imageDataList.sorted { $0.createdAt > $1.createdAt }
      
      observer.onNext(sortedList)
      observer.onCompleted()
      
      return Disposables.create()
    }
  }
  
  // 즐겨찾기 토글
  func toggleFavorite(imageId: String) {
    imageRecordRepository.toggleFavorite(imageId: imageId)
      .subscribe(onNext: { [weak self] in
        // 즐겨찾기 상태가 변경된 후 데이터 다시 로드
        self?.refreshData()
      })
      .disposed(by: disposeBag)
  }
}
