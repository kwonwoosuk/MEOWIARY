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
import RealmSwift

class DailyDiaryViewModel: BaseViewModel {
    
    var disposeBag = DisposeBag()
    private let imageManager = ImageManager.shared
    private let imageRecordRepository = ImageRecordRepository()
    private let dayCardRepository = DayCardRepository()
    private let currentDate = Date()
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let saveButtonTap: Observable<Void>
        let diaryText: Observable<String>
        let selectedImages: Observable<[UIImage]>
    }
    
    struct Output {
        let currentDateText: Driver<String>
        let dayOfWeekText: Driver<String>
        let isLoading: Driver<Bool>
        let saveSuccess: Driver<Void>
        let saveError: Driver<Error>
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let saveSuccessRelay = PublishRelay<Void>()
        let saveErrorRelay = PublishRelay<Error>()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        let currentDateText = dateFormatter.string(from: currentDate)
        
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekText = dateFormatter.string(from: currentDate)
        
        input.saveButtonTap
            .withLatestFrom(Observable.combineLatest(input.diaryText, input.selectedImages))
            .flatMap { [weak self] (diaryText, selectedImages) -> Observable<Void> in
                guard let self = self else { return Observable.just(()) }
                
                isLoadingRelay.accept(true)
                
                let calendar = Calendar.current
                let year = calendar.component(.year, from: self.currentDate)
                let month = calendar.component(.month, from: self.currentDate)
                let day = calendar.component(.day, from: self.currentDate)
                
                let dayCard = self.dayCardRepository.getDayCardForDate(year: year, month: month, day: day) ?? DayCard(date: self.currentDate)
                
                let saveOperation: Observable<Void>
                if selectedImages.isEmpty {
                    saveOperation = Observable.create { observer in
                        let realm: Realm
                        do {
                            realm = try Realm()
                        } catch {
                            observer.onError(error)
                            return Disposables.create()
                        }
                        do {
                            try realm.write {
                                dayCard.notes = diaryText.isEmpty ? nil : diaryText
                                realm.add(dayCard, update: .modified)
                            }
                            observer.onNext(())
                            observer.onCompleted()
                        } catch {
                            observer.onError(error)
                        }
                        return Disposables.create()
                    }
                } else {
                  saveOperation = Observable<Any>.create { observer in
                        let realm: Realm
                        do {
                            realm = try Realm()
                        } catch {
                            observer.onError(error)
                            return Disposables.create()
                        }
                        do {
                            try realm.write {
                                dayCard.notes = diaryText.isEmpty ? nil : diaryText
                                realm.add(dayCard, update: .modified)
                            }
                            observer.onNext(())
                            observer.onCompleted()
                        } catch {
                            observer.onError(error)
                        }
                        return Disposables.create()
                    }
                    .flatMap { _ -> Observable<Void> in
                        let imageRecordObservables = selectedImages.map { image in
                            self.imageManager.saveImage(image)
                                .flatMap { imageRecord in
                                    self.imageRecordRepository.saveImageRecord(imageRecord)
                                }
                        }
                        return Observable.zip(imageRecordObservables)
                            .flatMap { imageRecords in
                                self.dayCardRepository.addImageRecord(imageRecords, to: dayCard)
                            }
                    }
                }
                
                return saveOperation
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
                    .debug("Final Save Operation")
            }
            .subscribe(
                onNext: { _ in print("Save operation completed successfully") },
                onError: { error in print("Error occurred: \(error)") }
            )
            .disposed(by: disposeBag)
        
        return Output(
            currentDateText: Driver.just(currentDateText),
            dayOfWeekText: Driver.just(dayOfWeekText),
            isLoading: isLoadingRelay.asDriver(),
            saveSuccess: saveSuccessRelay.asDriver(onErrorDriveWith: .empty()),
            saveError: saveErrorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
    
  private func saveWithImage(text: String, image: UIImage) -> Observable<Void> {
      return Observable.create { [weak self] observer in
          guard let self = self else {
              observer.onError(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel is nil"]))
              return Disposables.create()
          }
          
          print("이미지 저장 시작")
          
          let imageRecordObservable = self.imageManager.saveImage(image)
              .flatMap { imageRecord -> Observable<ImageRecord> in
                  print("이미지 매니저에서 ImageRecord 생성됨: \(imageRecord.id)")
                  return self.imageRecordRepository.saveImageRecord(imageRecord)
              }
          
          let saveDayCardObservable = imageRecordObservable
              .flatMap { imageRecord -> Observable<Void> in
                  let calendar = Calendar.current
                  let year = calendar.component(.year, from: self.currentDate)
                  let month = calendar.component(.month, from: self.currentDate)
                  let day = calendar.component(.day, from: self.currentDate)
                  
                  let existingCard = self.dayCardRepository.getDayCardForDate(year: year, month: month, day: day)
                  let dayCard = existingCard ?? DayCard(date: self.currentDate)
                  
                  let realm: Realm
                  do {
                      realm = try Realm()
                  } catch {
                      return Observable.error(error)
                  }
                  do {
                      try realm.write {
                          dayCard.notes = text.isEmpty ? nil : text
                          if existingCard == nil { realm.add(dayCard) }
                          dayCard.imageRecords.append(imageRecord)
                      }
                      return Observable.just(())
                  } catch {
                      return Observable.error(error)
                  }
              }
          
          saveDayCardObservable
              .subscribe(
                  onNext: { _ in
                      print("DayCard 저장 완료 (이미지 포함)")
                      observer.onNext(())
                      observer.onCompleted()
                  },
                  onError: { error in
                      print("저장 오류: \(error)")
                      observer.onError(error)
                  }
              )
              .disposed(by: self.disposeBag)
          
          return Disposables.create()
      }
  }
}
