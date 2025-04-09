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
    
    private var currentYear: Int = Calendar.current.component(.year, from: Date())
    private var currentMonth: Int = Calendar.current.component(.month, from: Date())
    
    struct ImageData: Equatable {
        let id: String
        let originalPath: String
        let thumbnailPath: String
        let isFavorite: Bool
        let createdAt: Date
        let dayCardId: String?
        let notes: String?
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
        let searchText: Observable<String> // Added search text input
    }
    
    struct Output {
        let images: Driver<[ImageData]>
        let isEmpty: Driver<Bool>
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        // Load initial data
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
        
        // Year/Month selection
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
        
        // Favorite filter
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
        
        // Search filter
        input.searchText
            .withLatestFrom(allImagesRelay) { (searchText, allImages) -> [ImageData] in
                if searchText.isEmpty {
                    return allImages
                } else {
                    return allImages.filter {
                        "\(($0.day))".contains(searchText) ||
                        ($0.notes?.lowercased().contains(searchText.lowercased()) ?? false)
                    }
                }
            }
            .subscribe(onNext: { [weak self] filteredImages in
                self?.imagesRelay.accept(filteredImages)
            })
            .disposed(by: disposeBag)
        
        let isEmpty = imagesRelay.map { $0.isEmpty }
        
        return Output(
            images: imagesRelay.asDriver(),
            isEmpty: isEmpty.asDriver(onErrorJustReturn: true)
        )
    }
    
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
    
    private func loadImageData(year: Int, month: Int) -> Observable<[ImageData]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }
            
            let dayCards = self.dayCardRepository.getDayCards(year: year, month: month)
            var dayToImageData: [Int: ImageData] = [:]
            let groupedDayCards = Dictionary(grouping: dayCards, by: { $0.day })
            
            for (day, dayCardsInDay) in groupedDayCards.sorted(by: { $0.key > $1.key }) {
                for dayCard in dayCardsInDay {
                    if !dayCard.imageRecords.isEmpty {
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
                                    if let existing = dayToImageData[day] {
                                        if imageRecord.isFavorite && !existing.isFavorite {
                                            dayToImageData[day] = imageData
                                        }
                                    } else {
                                        dayToImageData[day] = imageData
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            let imageDataList = Array(dayToImageData.values).sorted(by: { $0.day > $1.day })
            observer.onNext(imageDataList)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func toggleFavorite(imageId: String) -> Observable<Void> {
        return imageRecordRepository.toggleFavorite(imageId: imageId)
            .do(onNext: { [weak self] in
                self?.refreshData(year: self?.currentYear ?? Calendar.current.component(.year, from: Date()),
                                  month: self?.currentMonth ?? Calendar.current.component(.month, from: Date()))
            })
    }
}
