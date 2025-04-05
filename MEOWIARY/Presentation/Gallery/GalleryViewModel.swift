//
//  ImageGalleryViewModel.swift
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
  // 이미지 데이터 타입 정의
  struct ImageData {
    let id: String
    let originalPath: String
    let thumbnailPath: String
    let isFavorite: Bool
    let createdAt: Date
    let dayCardId: String?  // 관련 DayCard ID
  }
  
  // MARK: - Input & Output
  struct Input {
    let viewDidLoad: Observable<Void>
  }
  
  struct Output {
    let images: Driver<[ImageData]>
    let isEmpty: Driver<Bool>
  }
  
  // MARK: - Transform
  func transform(input: Input) -> Output {
    
    
    // 이미지 데이터 로드
    input.viewDidLoad
      .flatMap { [weak self] _ -> Observable<[ImageData]> in
        guard let self = self else { return Observable.just([]) }
        return self.loadImageData()
      }
      .subscribe(onNext: { images in
        self.imagesRelay.accept(images)
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
              self?.imagesRelay.accept(images)
          })
          .disposed(by: disposeBag)
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
              // 각 DayCard의 모든 imageRecords를 확인
              for imageRecord in dayCard.imageRecords {
                  if let originalPath = imageRecord.originalImagePath,
                     let thumbnailPath = imageRecord.thumbnailImagePath {
                      
                      let fileExists = self.imageManager.checkImageFileExists(path: originalPath)
                      print("이미지 파일 존재 여부: \(fileExists), 경로: \(originalPath)")
                      
                      let imageData = ImageData(
                          id: imageRecord.id,
                          originalPath: originalPath,
                          thumbnailPath: thumbnailPath,
                          isFavorite: imageRecord.isFavorite,
                          createdAt: dayCard.date,
                          dayCardId: dayCard.id
                      )
                      
                      imageDataList.append(imageData)
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
        .subscribe()
        .disposed(by: disposeBag)
  }
}
