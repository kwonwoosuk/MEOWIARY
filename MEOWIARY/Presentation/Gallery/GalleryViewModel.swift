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
            
            // 모든 DayCard 가져오기
            let dayCards = self.dayCardRepository.getDayCards(year: year, month: month)
            
            // 날짜별 대표 이미지를 저장할 Dictionary
            var dayToImageData: [Int: ImageData] = [:]
            let groupedDayCards = Dictionary(grouping: dayCards, by: { $0.day })
            
            for (day, dayCardsInDay) in groupedDayCards.sorted(by: { $0.key > $1.key }) {
                // 일상 기록 이미지만 표시 - 증상 기록은 제외
                for dayCard in dayCardsInDay {
                    if !dayCard.imageRecords.isEmpty {
                        // 이미지 레코드 처리
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
                                        notes: dayCard.notes,
                                        year: dayCard.year,
                                        month: dayCard.month,
                                        day: dayCard.day
                                    )
                                    
                                    // 해당 날짜의 대표 이미지 선택 로직
                                    if let existing = dayToImageData[day] {
                                        // 즐겨찾기된 이미지를 우선적으로 선택
                                        if imageRecord.isFavorite && !existing.isFavorite {
                                            dayToImageData[day] = imageData
                                        }
                                    } else {
                                        // 첫 이미지는 무조건 등록
                                        dayToImageData[day] = imageData
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Dictionary에서 대표 이미지만 추출하여 날짜 내림차순으로 정렬
            let imageDataList = Array(dayToImageData.values).sorted(by: { $0.day > $1.day })
            
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
