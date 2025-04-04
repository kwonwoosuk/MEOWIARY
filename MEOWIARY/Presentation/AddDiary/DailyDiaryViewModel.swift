//
//  DailyDiaryViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

// DailyDiaryViewModel.swift
import Foundation
import RxSwift
import RxCocoa
import UIKit

class DailyDiaryViewModel: BaseViewModel {
  
  // MARK: - Properties
  var disposeBag = DisposeBag()
  private let imageManager = ImageManager.shared
  private let imageRecordRepository = ImageRecordRepository()
  private let dayCardRepository = DayCardRepository()
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
      .do(onNext: { (diaryText, selectedImage) in
        print("저장 로직 시작: 텍스트 길이=\(diaryText.count), 이미지 있음=\(selectedImage != nil)")
        isLoadingRelay.accept(true)
      })
        .flatMap { [weak self] (diaryText, selectedImage) -> Observable<Void> in
          guard let self = self else { return Observable.error(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: nil)) }
          
          // 이미지가 있으면 저장
          if let image = selectedImage {
            print("이미지 저장 시작")
            return self.imageManager.saveImage(image)
              .flatMap { imageRecord -> Observable<ImageRecord> in
                print("이미지 메니저에서 ImageRecord 생성됨, ID: \(imageRecord.id)")
                return self.imageRecordRepository.saveImageRecord(imageRecord)
              }
              .flatMap { imageRecord -> Observable<DayCard> in
                print("ImageRecord Realm에 저장됨, ID: \(imageRecord.id)")
                // DayCard 생성 및 저장
                let dayCard = DayCard(date: self.currentDate, imageRecord: imageRecord, notes: diaryText)
                return self.dayCardRepository.saveDayCard(dayCard)
              }
              .map { _ in () } // Void로 변환
              .do(onNext: { _ in
                print("저장 완료 (이미지 포함)")
              }, onError: { error in
                print("저장 오류: \(error)")
              })
                } else {
                  // 이미지 없이 텍스트만 저장
                  let dayCard = DayCard(date: self.currentDate, notes: diaryText)
                  return self.dayCardRepository.saveDayCard(dayCard)
                    .map { _ in () } // Void로 변환
                    .do(onNext: { _ in
                      print("저장 완료 (텍스트만)")
                    })
                      }
        }
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
  
  
  // MARK: - Helper Methods
  
  // 이미지와 함께 저장
  private func saveWithImage(text: String, image: UIImage) -> Observable<Void> {
    return Observable.create { [weak self] observer in
      guard let self = self else {
        observer.onError(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel is nil"]))
        return Disposables.create()
      }
      
      print("이미지 저장 시작")
      
      // 이미지 먼저 저장
      self.imageManager.saveImage(image)
        .flatMap { imageRecord -> Observable<ImageRecord> in
          print("이미지 메니저에서 ImageRecord 생성됨: \(imageRecord.id)")
          return self.imageRecordRepository.saveImageRecord(imageRecord)
        }
        .flatMap { imageRecord -> Observable<DayCard> in
          print("ImageRecord Realm에 저장됨: \(imageRecord.id)")
          
          // 기존에 해당 날짜의 DayCard가 있는지 확인
          let calendar = Calendar.current
          let year = calendar.component(.year, from: self.currentDate)
          let month = calendar.component(.month, from: self.currentDate)
          let day = calendar.component(.day, from: self.currentDate)
          
          let existingCard = self.dayCardRepository.getDayCardForDate(year: year, month: month, day: day)
          
          let dayCard: DayCard
          if let existingCard = existingCard {
            // 기존 DayCard 업데이트
            dayCard = existingCard
            dayCard.notes = text
            dayCard.imageRecord = imageRecord
            print("기존 DayCard 업데이트: \(dayCard.id)")
          } else {
            // 새 DayCard 생성
            dayCard = DayCard(date: self.currentDate, imageRecord: imageRecord, notes: text)
            print("새 DayCard 생성: \(dayCard.id)")
          }
          
          return self.dayCardRepository.saveDayCard(dayCard)
        }
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
  
  // 이미지 없이 텍스트만 저장
  private func saveWithoutImage(text: String) -> Observable<Void> {
    return Observable.create { [weak self] observer in
      guard let self = self else {
        observer.onError(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel is nil"]))
        return Disposables.create()
      }
      
      // 기존에 해당 날짜의 DayCard가 있는지 확인
      let calendar = Calendar.current
      let year = calendar.component(.year, from: self.currentDate)
      let month = calendar.component(.month, from: self.currentDate)
      let day = calendar.component(.day, from: self.currentDate)
      
      let existingCard = self.dayCardRepository.getDayCardForDate(year: year, month: month, day: day)
      
      let dayCard: DayCard
      if let existingCard = existingCard {
        // 기존 DayCard 업데이트
        dayCard = existingCard
        dayCard.notes = text
        print("기존 DayCard 업데이트 (텍스트만): \(dayCard.id)")
      } else {
        // 새 DayCard 생성
        dayCard = DayCard(date: self.currentDate, notes: text)
        print("새 DayCard 생성 (텍스트만): \(dayCard.id)")
      }
      
      self.dayCardRepository.saveDayCard(dayCard)
        .subscribe(
          onNext: { _ in
            print("DayCard 저장 완료 (텍스트만)")
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
