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
        
        // 선택된 이미지와 텍스트 결합
        let diaryInputs = Observable.combineLatest(
            input.diaryText,
            input.selectedImage
        )
        
        // 저장 버튼 클릭 시
        input.saveButtonTap
            .withLatestFrom(diaryInputs)
            .do(onNext: { _ in isLoadingRelay.accept(true) })
            .flatMap { [weak self] (text, image) -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel is nil"]))
                }
                
                // 텍스트가 비어있는지 확인
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return Observable.error(NSError(domain: "DailyDiaryViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "일기 내용을 입력해주세요."]))
                }
                
                // 이미지가 있을 경우 이미지 먼저 저장
                if let selectedImage = image {
                    return self.saveWithImage(text: text, image: selectedImage)
                } else {
                    return self.saveWithoutImage(text: text)
                }
            }
            .subscribe(
                onNext: { _ in
                    isLoadingRelay.accept(false)
                    saveSuccessRelay.accept(())
                },
                onError: { error in
                    isLoadingRelay.accept(false)
                    saveErrorRelay.accept(error)
                }
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
    
    // MARK: - Helper Methods
    
    // 이미지와 함께 저장
  private func saveWithImage(text: String, image: UIImage) -> Observable<Void> {
          return Observable.create { [weak self] observer in
              guard let self = self else {
                  observer.onError(NSError(domain: "DailyDiaryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel is nil"]))
                  return Disposables.create()
              }
              
              // 이미지 먼저 저장
              self.imageManager.saveImage(image)
                  .subscribe(
                      onNext: { imageRecord in
                          do {
                              print("이미지 저장 성공: \(imageRecord.id), 경로: \(imageRecord.originalImagePath ?? "없음")")
                              
                              // Realm에 저장
                              try self.realmManager.realm.write {
                                  // ImageRecord 먼저 저장
                                  self.realmManager.realm.add(imageRecord)
                                  
                                  // 기존에 해당 날짜의 DayCard가 있는지 확인
                                  let calendar = Calendar.current
                                  let year = calendar.component(.year, from: self.currentDate)
                                  let month = calendar.component(.month, from: self.currentDate)
                                  let day = calendar.component(.day, from: self.currentDate)
                                  
                                  // 기존 DayCard 가져오기 또는 새로 생성
                                  let dayCard: DayCard
                                  if let existingCard = self.realmManager.getDayCardForDate(year: year, month: month, day: day) {
                                      dayCard = existingCard
                                      print("기존 DayCard 업데이트: \(dayCard.id)")
                                  } else {
                                      dayCard = DayCard(date: self.currentDate)
                                      print("새 DayCard 생성: \(dayCard.id)")
                                  }
                                  
                                  // 데이터 업데이트
                                  dayCard.notes = text
                                  dayCard.imageRecord = imageRecord
                                  
                                  // 아직 Realm에 추가되지 않은 경우 추가
                                  if dayCard.realm == nil {
                                      self.realmManager.realm.add(dayCard)
                                  }
                                  
                                  print("DayCard 저장 완료: \(dayCard.id), 이미지 레코드: \(dayCard.imageRecord?.id ?? "없음")")
                              }
                              
                              observer.onNext(())
                              observer.onCompleted()
                          } catch {
                              print("Realm 저장 오류: \(error.localizedDescription)")
                              observer.onError(error)
                          }
                      },
                      onError: { error in
                          print("이미지 저장 오류: \(error.localizedDescription)")
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
            
            do {
                try self.realmManager.realm.write {
                    // 기존에 해당 날짜의 DayCard가 있는지 확인
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: self.currentDate)
                    let month = calendar.component(.month, from: self.currentDate)
                    let day = calendar.component(.day, from: self.currentDate)
                    
                    // 기존 DayCard 가져오기 또는 새로 생성
                    let dayCard: DayCard
                    if let existingCard = self.realmManager.getDayCardForDate(year: year, month: month, day: day) {
                        dayCard = existingCard
                    } else {
                        dayCard = DayCard(date: self.currentDate)
                    }
                    
                    // 데이터 업데이트
                    dayCard.notes = text
                    
                    // 아직 Realm에 추가되지 않은 경우 추가
                    if dayCard.realm == nil {
                        self.realmManager.realm.add(dayCard)
                    }
                }
                
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
}
