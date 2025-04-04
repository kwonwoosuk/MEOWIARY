//
//  RealmManager.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/30/25.
//

import UIKit
import RealmSwift
import RxSwift

final class RealmManager {
  
  
  // MARK: - Initialization
  var realm: Realm {
    do {
      return try Realm()
    } catch {
      fatalError("Failed to initialize Realm: \(error)")
    }
  }
  
  // MARK: - CRUD Operations - DayCard
  
  func saveDayCard(_ dayCard: DayCard) {
    do {
      try realm.write {
        realm.add(dayCard, update: .modified)
      }
    } catch {
      print("Failed to save day card: \(error)")
    }
  }
  
  func getDayCard(for date: Date) -> DayCard? {
    let calendar = Calendar.current
    let year = calendar.component(.year, from: date)
    let month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    
    return realm.objects(DayCard.self)
      .filter("year == %@ AND month == %@ AND day == %@", year, month, day)
      .first
  }
  
  func getDayCards(year: Int, month: Int) -> [DayCard] {
    return Array(
      realm.objects(DayCard.self)
        .filter("year == %@ AND month == %@", year, month)
        .sorted(byKeyPath: "day")
    )
  }
  
  func deleteDayCard(_ dayCard: DayCard) {
    do {
      try realm.write {
        realm.delete(dayCard)
      }
    } catch {
      print("Failed to delete day card: \(error)")
    }
  }
  
  // MARK: - CRUD Operations - Symptom
  
  func addSymptom(_ symptom: Symptom, to dayCard: DayCard) {
    do {
      try realm.write {
        dayCard.symptoms.append(symptom)
      }
    } catch {
      print("Failed to add symptom: \(error)")
    }
  }
  
  func removeSymptom(_ symptom: Symptom, from dayCard: DayCard) {
    do {
      try realm.write {
        if let index = dayCard.symptoms.index(of: symptom) {
          dayCard.symptoms.remove(at: index)
        }
      }
    } catch {
      print("Failed to remove symptom: \(error)")
    }
  }
  
  // MARK: - Query Operations
  
  func getSymptomRecords(year: Int, month: Int) -> [Int: [Symptom]] {
    var result: [Int: [Symptom]] = [:]
    
    let dayCards = realm.objects(DayCard.self)
      .filter("year == %@ AND month == %@", year, month)
    
    for dayCard in dayCards {
      if !dayCard.symptoms.isEmpty {
        result[dayCard.day] = Array(dayCard.symptoms)
      }
    }
    
    return result
  }
  
  func getDaysWithSymptoms(year: Int, month: Int) -> [Int] {
    return Array(
      realm.objects(DayCard.self)
        .filter("year == %@ AND month == %@ AND symptoms.@count > 0", year, month)
        .map { $0.day }
    )
  }
  
  // MARK: - Rx Wrapper Methods
  
  func getDayCardsObservable(year: Int, month: Int) -> Observable<[DayCard]> {
    return Observable.create { observer in
      let results = self.realm.objects(DayCard.self)
        .filter("year == %@ AND month == %@", year, month)
        .sorted(byKeyPath: "day")
      
      let notificationToken = results.observe { changes in
        switch changes {
        case .initial(let collection), .update(let collection, _, _, _):
          observer.onNext(Array(collection))
        case .error(let error):
          observer.onError(error)
        }
      }
      
      return Disposables.create {
        notificationToken.invalidate()
      }
    }
  }
  
  func getDaysWithSymptomsObservable(year: Int, month: Int) -> Observable<[Int]> {
    return Observable.create { observer in
      let results = self.realm.objects(DayCard.self)
        .filter("year == %@ AND month == %@ AND symptoms.@count > 0", year, month)
      
      let notificationToken = results.observe { changes in
        switch changes {
        case .initial(let collection), .update(let collection, _, _, _):
          observer.onNext(Array(collection.map { $0.day }))
        case .error(let error):
          observer.onError(error)
        }
      }
      
      return Disposables.create {
        notificationToken.invalidate()
      }
    }
  }
  
  // RealmManager.swift에 추가할 메서드
  
  // 모든 DayCard 가져오기
  func getAllDayCards() -> [DayCard] {
    let results = realm.objects(DayCard.self).sorted(byKeyPath: "date", ascending: false)
    print("Realm에서 조회된 DayCard 수: \(results.count)")
    
    // ImageRecord가 연결된 DayCard만 필터링
    let filteredResults = results.filter { $0.imageRecord != nil }
    print("ImageRecord가 있는 DayCard 수: \(filteredResults.count)")
    
    return Array(filteredResults)
  }
  
  // 이미지 즐겨찾기 설정/해제
  func toggleImageFavorite(imageId: String) {
    guard let imageRecord = realm.object(ofType: ImageRecord.self, forPrimaryKey: imageId) else { return }
    
    do {
      try realm.write {
        imageRecord.isFavorite = !imageRecord.isFavorite
      }
    } catch {
      print("Failed to toggle favorite: \(error)")
    }
  }
  
  // 이미지 레코드 삭제
  func deleteImageRecord(_ imageRecord: ImageRecord) {
    do {
      try realm.write {
        // 연결된 DayCard에서 이미지 레코드 참조 제거
        let dayCards = realm.objects(DayCard.self).filter("imageRecord.id == %@", imageRecord.id)
        for dayCard in dayCards {
          dayCard.imageRecord = nil
        }
        
        // 이미지 레코드 삭제
        realm.delete(imageRecord)
      }
    } catch {
      print("Failed to delete image record: \(error)")
    }
  }
  
  // 특정 날짜의 DayCard 가져오기 (연월일 기준)
  func getDayCardForDate(year: Int, month: Int, day: Int) -> DayCard? {
    return realm.objects(DayCard.self)
      .filter("year == %@ AND month == %@ AND day == %@", year, month, day)
      .first
  }
  
  // 특정 월의 모든 DayCard 데이터 딕셔너리로 가져오기 (일->DayCard 맵핑)
  func getDayCardsMapForMonth(year: Int, month: Int) -> [Int: DayCard] {
    let dayCards = realm.objects(DayCard.self)
      .filter("year == %@ AND month == %@", year, month)
    
    var result: [Int: DayCard] = [:]
    for dayCard in dayCards {
      result[dayCard.day] = dayCard
    }
    
    return result
  }
  
  
  
}

extension RealmManager {
  // RealmManager.swift에 추가할 메서드
  
  // 테스트용 목 데이터 생성
  func createMockData() {
    // 이미 테스트 데이터가 있는지 확인
    let existingData = realm.objects(DayCard.self)
    guard existingData.count < 5 else {
      print("이미 충분한 테스트 데이터가 있습니다.")
      return
    }
    
    print("테스트 데이터 생성 시작...")
    let imageManager = ImageManager.shared
    
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
    
    for image in sampleImages {
      // ImageManager를 사용하여 이미지 저장
      imageManager.saveImage(image)
        .subscribe(onNext: { imageRecord in
          do {
            try self.realm.write {
              self.realm.add(imageRecord)
              imageRecords.append(imageRecord)
              
              // 이미지 레코드를 생성하자마자 랜덤하게 즐겨찾기 설정
              imageRecord.isFavorite = Bool.random()
            }
          } catch {
            print("이미지 레코드 저장 실패: \(error)")
          }
        }, onError: { error in
          print("이미지 저장 실패: \(error)")
        })
        .dispose()
    }
    
    // 이미지 저장 후 약간의 지연 (Observable이 완료될 시간 필요)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.createDayCardsWithImageRecords(imageRecords: imageRecords, currentYear: currentYear, currentMonth: currentMonth)
    }
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
    // 현재 월에 3개의 DayCard 추가
    for i in 0..<3 {
      let day = min(5 + i * 3, 28) // 5, 8, 11일에 데이터 추가
      
      var dateComponents = DateComponents()
      dateComponents.year = currentYear
      dateComponents.month = currentMonth
      dateComponents.day = day
      
      if let date = Calendar.current.date(from: dateComponents), i < imageRecords.count {
        do {
          try realm.write {
            let dayCard = DayCard()
            dayCard.date = date
            dayCard.year = currentYear
            dayCard.month = currentMonth
            dayCard.day = day
            dayCard.notes = "테스트 일기 항목 #\(i+1)"
            
            // 이미지 레코드 연결
            dayCard.imageRecord = imageRecords[i]
            
            // 증상 추가
            let symptom = Symptom()
            symptom.name = "테스트 증상 #\(i+1)"
            symptom.severity = i + 2 // 2, 3, 4 (1-5 스케일)
            symptom.timestamp = date
            dayCard.symptoms.append(symptom)
            
            realm.add(dayCard)
          }
          print("Day Card 추가됨: \(currentYear)년 \(currentMonth)월 \(day)일")
        } catch {
          print("Day Card 저장 실패: \(error)")
        }
      }
    }
    
    // 이전 월에도 2개의 DayCard 추가
    let previousMonth = currentMonth == 1 ? 12 : currentMonth - 1
    let previousMonthYear = currentMonth == 1 ? currentYear - 1 : currentYear
    
    for i in 0..<2 {
      let day = min(10 + i * 5, 28) // 10, 15일에 데이터 추가
      
      var dateComponents = DateComponents()
      dateComponents.year = previousMonthYear
      dateComponents.month = previousMonth
      dateComponents.day = day
      
      if let date = Calendar.current.date(from: dateComponents) {
        let recordIndex = i + 3 // 3, 4번 이미지 사용
        
        if recordIndex < imageRecords.count {
          do {
            try realm.write {
              let dayCard = DayCard()
              dayCard.date = date
              dayCard.year = previousMonthYear
              dayCard.month = previousMonth
              dayCard.day = day
              dayCard.notes = "이전 월 테스트 일기 #\(i+1)"
              
              // 이미지 레코드 연결
              dayCard.imageRecord = imageRecords[recordIndex]
              
              realm.add(dayCard)
            }
            print("이전 월 Day Card 추가됨: \(previousMonthYear)년 \(previousMonth)월 \(day)일")
          } catch {
            print("이전 월 Day Card 저장 실패: \(error)")
          }
        }
      }
    }
    
    print("테스트 데이터 생성 완료!")
  }
}
