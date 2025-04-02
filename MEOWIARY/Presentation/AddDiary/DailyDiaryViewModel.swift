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

class DailyDiaryViewModel: BaseViewModel {
    
    // MARK: - Properties
    var disposeBag = DisposeBag()
    private let realmManager = RealmManager()
    private let imageManager = ImageManager.shared
    private let currentDate = Date()
    
    // MARK: - Input & Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let saveButtonTap: Observable<Void>
        let diaryText: Observable<String>
        let selectedImage: Observable<UIImage?>
    }
    
    struct Output {
        let currentDateText: Driver<String>
        let dayOfWeekText: Driver<String>
        let isLoading: Driver<Bool>
        let saveSuccess: Driver<Void>
        let saveError: Driver<Error>
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let saveSuccessRelay = PublishRelay<Void>()
        let saveErrorRelay = PublishRelay<Error>()
        
        // 날짜 표시 포맷
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        let currentDateText = dateFormatter.string(from: currentDate)
        
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekText = dateFormatter.string(from: currentDate)
        
        // 저장 버튼 클릭 시
        input.saveButtonTap
            .withLatestFrom(Observable.combineLatest(input.diaryText, input.selectedImage))
            .flatMap { [weak self] (diaryText, selectedImage) -> Observable<Void> in
                guard let self = self else { return Observable.error(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: nil)) }
                
                isLoadingRelay.accept(true)
                
                // 이미지가 있으면 저장
                if let image = selectedImage {
                    return self.imageManager.saveImage(image)
                        .flatMap { imageRecord -> Observable<Void> in
                            // 일기 데이터 저장
                            let dayCard = DayCard(date: self.currentDate, imageRecord: imageRecord, notes: diaryText)
                            self.realmManager.saveDayCard(dayCard)
                            return Observable.just(())
                        }
                        .do(onNext: { _ in
                            isLoadingRelay.accept(false)
                            saveSuccessRelay.accept(())
                        }, onError: { error in
                            isLoadingRelay.accept(false)
                            saveErrorRelay.accept(error)
                        })
                } else {
                    // 이미지 없이 텍스트만 저장
                    let dayCard = DayCard(date: self.currentDate, notes: diaryText)
                    self.realmManager.saveDayCard(dayCard)
                    isLoadingRelay.accept(false)
                    saveSuccessRelay.accept(())
                    return Observable.just(())
                }
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        return Output(
            currentDateText: Driver.just(currentDateText),
            dayOfWeekText: Driver.just(dayOfWeekText),
            isLoading: isLoadingRelay.asDriver(),
            saveSuccess: saveSuccessRelay.asDriver(onErrorDriveWith: .empty()),
            saveError: saveErrorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
