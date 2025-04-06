//
//  DetailViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/6/25.
//


import UIKit
import RxSwift
import RxCocoa

final class DetailViewModel: BaseViewModel {
    
    // MARK: - Properties
    var disposeBag = DisposeBag()
    private let imageData: GalleryViewModel.ImageData
    private let imageManager: ImageManager
    private let imageRecordRepository = ImageRecordRepository()
    private let isFavoriteRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Input & Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let favoriteButtonTap: Observable<Void>
        let shareButtonTap: Observable<Void>
    }
    
    struct Output {
        let image: Driver<UIImage?>
        let dateText: Driver<String>
        let isFavorite: Driver<Bool>
        let notesText: Driver<String?>
    }
    
    // MARK: - Initialization
    init(imageData: GalleryViewModel.ImageData, imageManager: ImageManager) {
        self.imageData = imageData
        self.imageManager = imageManager
        self.isFavoriteRelay.accept(imageData.isFavorite)
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        // 이미지 로드
        let imageObservable = input.viewDidLoad
            .map { [weak self] _ -> UIImage? in
                guard let self = self else { return nil }
                return self.imageManager.loadOriginalImage(from: self.imageData.originalPath)
            }
            .share()
        
        // 날짜 포맷팅
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        let dateText = dateFormatter.string(from: imageData.createdAt)
        
        // 즐겨찾기 상태 토글
        input.favoriteButtonTap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                // 현재 상태의 반대로 토글
                let newState = !self.isFavoriteRelay.value
                
                // Realm 업데이트
                self.imageRecordRepository.toggleFavorite(imageId: self.imageData.id)
                    .subscribe(onNext: {
                        // UI 업데이트
                        self.isFavoriteRelay.accept(newState)
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
        
        return Output(
            image: imageObservable.asDriver(onErrorJustReturn: nil),
            dateText: Driver.just(dateText),
            isFavorite: isFavoriteRelay.asDriver(),
            notesText: Driver.just(imageData.notes)
        )
    }
    
    // MARK: - Public Methods
    func getShareImage() -> UIImage? {
        return imageManager.loadOriginalImage(from: imageData.originalPath)
    }
}
