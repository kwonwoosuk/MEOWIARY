//
//  MockDataManager.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/30/25.
//


import Foundation
import UIKit
import RxSwift

class MockDataManager {
  private let imageManager = ImageManager.shared
  private let imageRecordRepository = ImageRecordRepository()
  private let dayCardRepository = DayCardRepository()
  private let disposeBag = DisposeBag()
  
  func createMockData() {
    // 이미 테스트 데이터가 있는지 확인
    let existingData = dayCardRepository.getAllDayCards()
    guard existingData.count < 5 else {
      print("이미 충분한 테스트 데이터가 있습니다.")
      return
    }
    
    print("테스트 데이터 생성 시작...")
    
    // 날짜 설정
    let calendar = Calendar.current
    let currentDate = Date()
    
    // 올해와 지난달 기준으로 설정
    let currentYear = calendar.component(.year, from: currentDate)
    let currentMonth = calendar.component(.month, from: currentDate)
    
    // ImageRecord용 샘플 이미지 생성 (5개)
    let sampleImages = [
      createSampleImage(color: .red, size: CGSize(width: 300, height: 300)),
      createSampleImage(color: .blue, size: CGSize(width: 300, height: 300)),
      createSampleImage(color: .green, size: CGSize(width: 300, height: 300)),
      createSampleImage(color: .orange, size: CGSize(width: 300, height: 300)),
      createSampleImage(color: .purple, size: CGSize(width: 300, height: 300))
    ]
    
    // 이미지 저장 및 ImageRecord 생성
    var imageRecords: [ImageRecord] = []
    
    // 각 이미지를 순차적으로 저장
    Observable.from(sampleImages)
      .concatMap { image -> Observable<ImageRecord> in
        return self.imageManager.saveImage(image)
          .flatMap { imageRecord -> Observable<ImageRecord> in
            return self.imageRecordRepository.saveImageRecord(imageRecord)
              .do(onNext: { savedRecord in
                // 랜덤하게 즐겨찾기 설정
                if Bool.random() {
                  self.imageRecordRepository.toggleFavorite(imageId: savedRecord.id).subscribe().disposed(by: self.disposeBag)
                }
                imageRecords.append(savedRecord)
              })
          }
      }
      .toArray()
      .subscribe(
        onSuccess: { _ in
          // 이미지 저장 완료 후 DayCard 생성
          self.createDayCardsWithImageRecords(imageRecords: imageRecords, currentYear: currentYear, currentMonth: currentMonth)
        },
        onError: { error in
          print("이미지 저장 중 오류 발생: \(error)")
        }
      )
      .disposed(by: disposeBag)
  }
  
  // 샘플 컬러 이미지 생성 헬퍼 메서드
  private func createSampleImage(color: UIColor, size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      let rectangle = CGRect(x: 0, y: 0, width: size.width, height: size.height)
      color.setFill()
      ctx.fill(rectangle)
      
      // 텍스트 추가
      let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 50),
        .foregroundColor: UIColor.white
      ]
      
      let text = "테스트"
      let textSize = text.size(withAttributes: attributes)
      let textRect = CGRect(
        x: (size.width - textSize.width) / 2,
        y: (size.height - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
      )
      
      text.draw(in: textRect, withAttributes: attributes)
    }
  }
  
  // DayCard 생성 헬퍼 메서드
  private func createDayCardsWithImageRecords(imageRecords: [ImageRecord], currentYear: Int, currentMonth: Int) {
    guard !imageRecords.isEmpty else {
      print("이미지 레코드가 없어 DayCard를 생성할 수 없습니다.")
      return
    }
    
    print("DayCard 생성 시작...")
    
    // 현재 월에 3개의 DayCard 추가
    for i in 0..<min(3, imageRecords.count) {
      let day = min(5 + i * 3, 28) // 5, 8, 11일에 데이터 추가
      
      var dateComponents = DateComponents()
      dateComponents.year = currentYear
      dateComponents.month = currentMonth
      dateComponents.day = day
      
      if let date = Calendar.current.date(from: dateComponents) {
        // DayCard 생성
        let dayCard = DayCard(date: date, notes: "테스트 일기 항목 #\(i+1)")
        
        // 이미지 레코드 추가
        dayCard.imageRecords.append(imageRecords[i])
        
        // 증상 추가
        let symptom = Symptom()
        symptom.name = "테스트 증상 #\(i+1)"
        symptom.severity = i + 2 // 2, 3, 4 (1-5 스케일)
        symptom.timestamp = date
        
        dayCardRepository.saveDayCard(dayCard)
          .flatMap { savedDayCard -> Observable<Void> in
            return self.dayCardRepository.addSymptom(symptom, to: savedDayCard)
          }
          .subscribe(
            onNext: { _ in
              print("Day Card 추가됨: \(currentYear)년 \(currentMonth)월 \(day)일")
            },
            onError: { error in
              print("Day Card 저장 실패: \(error)")
            }
          )
          .disposed(by: disposeBag)
      }
    }
    
    // 이전 월에도 2개의 DayCard 추가
    let previousMonth = currentMonth == 1 ? 12 : currentMonth - 1
    let previousMonthYear = currentMonth == 1 ? currentYear - 1 : currentYear
    
    for i in 0..<min(2, imageRecords.count - 3) {
      let day = min(10 + i * 5, 28) // 10, 15일에 데이터 추가
      
      var dateComponents = DateComponents()
      dateComponents.year = previousMonthYear
      dateComponents.month = previousMonth
      dateComponents.day = day
      
      if let date = Calendar.current.date(from: dateComponents) {
        let recordIndex = i + 3 // 3, 4번 이미지 사용
        
        if recordIndex < imageRecords.count {
          // 여기서 DayCard 생성 방식 수정
          let dayCard = DayCard(date: date, notes: "이전 월 테스트 일기 #\(i+1)")
          dayCard.imageRecords.append(imageRecords[recordIndex])
          
          dayCardRepository.saveDayCard(dayCard)
            .subscribe(
              onNext: { _ in
                print("이전 월 Day Card 추가됨: \(previousMonthYear)년 \(previousMonth)월 \(day)일")
              },
              onError: { error in
                print("이전 월 Day Card 저장 실패: \(error)")
              }
            )
            .disposed(by: disposeBag)
        }
      }
    }
    
    print("테스트 데이터 생성 작업 시작됨!")
  }
}
