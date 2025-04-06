//
//  DayCardRepository.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/4/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol DayCardRepositoryProtocol {
    func saveDayCard(_ dayCard: DayCard) -> Observable<DayCard>
    func getDayCard(for date: Date) -> DayCard?
    func getDayCardForDate(year: Int, month: Int, day: Int) -> DayCard?
    func getDayCards(year: Int, month: Int) -> [DayCard]
    func getDaysWithSymptoms(year: Int, month: Int) -> [Int]
    func getSymptomRecords(year: Int, month: Int) -> [Int: [Symptom]]
    func getDayCardsWithImages() -> [DayCard]
    func getAllDayCards() -> [DayCard]
    func getDayCardsMapForMonth(year: Int, month: Int) -> [Int: DayCard]
    func deleteDayCard(_ dayCard: DayCard) -> Observable<Void>
    func addSymptom(_ symptom: Symptom, to dayCard: DayCard) -> Observable<Void>
    func removeSymptom(_ symptom: Symptom, from dayCard: DayCard) -> Observable<Void>
    func getDayCardsObservable(year: Int, month: Int) -> Observable<[DayCard]>
    func getDaysWithSymptomsObservable(year: Int, month: Int) -> Observable<[Int]>
}

class DayCardRepository: DayCardRepositoryProtocol {
    // 속성으로 저장하지 않고 필요할 때마다 새로운 Realm 인스턴스 생성
    private func getRealm() -> Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    init() {
        print("Realm 파일 위치: \(getRealm().configuration.fileURL?.path ?? "알 수 없음")")
    }
    
    func saveDayCard(_ dayCard: DayCard) -> Observable<DayCard> {
        return Observable.create { observer in
            let realm = self.getRealm()
            
            do {
                try realm.write {
                    realm.add(dayCard, update: .modified)
                    print("DayCard 저장 성공: \(dayCard.id)")
                }
                observer.onNext(dayCard)
                observer.onCompleted()
            } catch {
                print("DayCard 저장 실패: \(error)")
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func getDayCard(for date: Date) -> DayCard? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        return getDayCardForDate(year: year, month: month, day: day)
    }
    
    func getDayCardForDate(year: Int, month: Int, day: Int) -> DayCard? {
        let realm = getRealm()
        return realm.objects(DayCard.self)
            .filter("year == %@ AND month == %@ AND day == %@", year, month, day)
            .first
    }
    
    func getDayCards(year: Int, month: Int) -> [DayCard] {
        let realm = getRealm()
        let results = realm.objects(DayCard.self)
            .filter("year == %@ AND month == %@", year, month)
            .sorted(byKeyPath: "day")
        return Array(results)
    }
    
    func getDaysWithSymptoms(year: Int, month: Int) -> [Int] {
        let realm = getRealm()
        let results = realm.objects(DayCard.self)
            .filter("year == %@ AND month == %@ AND symptoms.@count > 0", year, month)
        return Array(results.map { $0.day })
    }
    
    func getSymptomRecords(year: Int, month: Int) -> [Int: [Symptom]] {
        let realm = getRealm()
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
    
  func getDayCardsWithImages() -> [DayCard] {
      let realm = getRealm()
      let results = realm.objects(DayCard.self)
          .filter("imageRecords.@count > 0")
          .sorted(byKeyPath: "date", ascending: false)
      return Array(results)
  }
    
    func getAllDayCards() -> [DayCard] {
        let realm = getRealm()
        let results = realm.objects(DayCard.self).sorted(byKeyPath: "date", ascending: false)
        print("Realm에서 조회된 DayCard 수: \(results.count)")
        return Array(results)
    }
    
    func getDayCardsMapForMonth(year: Int, month: Int) -> [Int: DayCard] {
        let realm = getRealm()
        let dayCards = realm.objects(DayCard.self)
            .filter("year == %@ AND month == %@", year, month)
        
        var result: [Int: DayCard] = [:]
        for dayCard in dayCards {
            result[dayCard.day] = dayCard
        }
        
        return result
    }
    
  
  func deleteDayCardsByIDs(_ ids: [String]) -> Observable<Void> {
      return Observable.create { observer in
          let realm = self.getRealm()
          
          do {
              // 트랜잭션 시작
              try realm.write {
                  // 각 ID에 해당하는 DayCard 찾기 및 삭제 준비
                  for id in ids {
                      guard let dayCard = realm.object(ofType: DayCard.self, forPrimaryKey: id) else {
                          print("DayCardRepository: 경고 - ID \(id)에 해당하는 DayCard를 찾을 수 없음")
                          continue
                      }
                      
                      // 증상 데이터 가져오기 및 삭제
                      let symptoms = Array(dayCard.symptoms)
                      print("DayCardRepository: 증상 삭제 - \(symptoms.count)개")
                      realm.delete(symptoms)
                      
                      // 이미지 레코드 가져오기 및 삭제
                      let imageRecords = Array(dayCard.imageRecords)
                      print("DayCardRepository: 이미지 레코드 개수 - \(imageRecords.count)")
                      
                      // 파일 시스템의 이미지 파일 삭제 (비동기로 처리하지만 삭제는 확실히)
                      let imageManager = ImageManager.shared
                      for imageRecord in imageRecords {
                          // 삭제할 경로 정보 미리 복사
                          let originalPath = imageRecord.originalImagePath
                          let thumbnailPath = imageRecord.thumbnailImagePath
                          
                          // 레코드 자체는 Realm에서 삭제
                          realm.delete(imageRecord)
                          
                          // 파일 시스템의 이미지 파일 삭제 (부가적인 작업으로 실패해도 진행)
                          if originalPath != nil || thumbnailPath != nil {
                              DispatchQueue.global(qos: .background).async {
                                  if let originalPath = originalPath {
                                      imageManager.deleteImageFile(path: originalPath, isOriginal: true)
                                  }
                                  if let thumbnailPath = thumbnailPath {
                                      imageManager.deleteImageFile(path: thumbnailPath, isOriginal: false)
                                  }
                              }
                          }
                      }
                      
                      // DayCard 삭제
                      print("DayCardRepository: DayCard 삭제 시작 - \(id)")
                      realm.delete(dayCard)
                      print("DayCardRepository: DayCard 삭제 완료 - \(id)")
                  }
              }
              
              print("DayCardRepository: 모든 DayCard 삭제 성공")
              observer.onNext(())
              observer.onCompleted()
          } catch {
              print("DayCardRepository: 삭제 실패 - \(error.localizedDescription)")
              observer.onError(error)
          }
          
          return Disposables.create()
      }
  }
  // DayCardRepository.swift의 deleteDayCard 메서드 수정
  func deleteDayCard(_ dayCard: DayCard) -> Observable<Void> {
      return Observable.create { observer in
          let realm = self.getRealm()
          
          // 중요: ID를 먼저 복사해두기
          let dayCardID = dayCard.id
          print("DayCardRepository: 삭제 시도 - ID: \(dayCardID)")
          
          guard let localDayCard = realm.object(ofType: DayCard.self, forPrimaryKey: dayCardID) else {
              print("DayCardRepository: 오류 - 삭제할 DayCard를 찾을 수 없음 (ID: \(dayCardID))")
              observer.onError(NSError(domain: "DayCard not found", code: -1, userInfo: nil))
              return Disposables.create()
          }

          do {
              // 중요: Realm의 삭제 작업을 위해 필요한 데이터를 미리 복사해둡니다
              let symptoms = Array(localDayCard.symptoms)
              print("DayCardRepository: 증상 삭제 - \(symptoms.count)개")
              
              // 이미지 레코드 정보도 미리 복사
              let imageRecords = Array(localDayCard.imageRecords)
              let imageRecordPaths: [(id: String, original: String?, thumbnail: String?)] = imageRecords.map {
                  (id: $0.id, original: $0.originalImagePath, thumbnail: $0.thumbnailImagePath)
              }
              print("DayCardRepository: 이미지 레코드 개수 - \(imageRecords.count)개")
              
              try realm.write {
                  // 증상 데이터 삭제
                  realm.delete(symptoms)
                  
                  // 이미지 레코드 삭제
                  realm.delete(imageRecords)
                  print("DayCardRepository: 이미지 레코드 삭제 - \(imageRecords.count)개")
                  
                  // DayCard 삭제
                  print("DayCardRepository: DayCard 삭제 - \(dayCardID)")
                  realm.delete(localDayCard)
              }
              
              // Realm 트랜잭션 외부에서 이미지 파일 삭제 (복사해둔 경로 정보 사용)
              let imageManager = ImageManager.shared
              for recordInfo in imageRecordPaths {
                  if let originalPath = recordInfo.original {
                      imageManager.deleteImageFile(path: originalPath, isOriginal: true)
                  }
                  if let thumbnailPath = recordInfo.thumbnail {
                      imageManager.deleteImageFile(path: thumbnailPath, isOriginal: false)
                  }
                  print("DayCardRepository: 이미지 파일 삭제 - \(recordInfo.id)")
              }
              
              print("DayCardRepository: 삭제 성공 - \(dayCardID)")
              observer.onNext(())
              observer.onCompleted()
          } catch {
              print("DayCardRepository: 삭제 실패 - \(error.localizedDescription)")
              observer.onError(error)
          }
          
          return Disposables.create()
      }
  }
    
    func addSymptom(_ symptom: Symptom, to dayCard: DayCard) -> Observable<Void> {
        return Observable.create { observer in
            let realm = self.getRealm()
            
            // 현재 스레드의 Realm에서 dayCard 다시 가져오기
            guard let localDayCard = realm.object(ofType: DayCard.self, forPrimaryKey: dayCard.id) else {
                observer.onError(NSError(domain: "DayCard not found", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            do {
                try realm.write {
                    localDayCard.symptoms.append(symptom)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func removeSymptom(_ symptom: Symptom, from dayCard: DayCard) -> Observable<Void> {
        return Observable.create { observer in
            let realm = self.getRealm()
            
            // 현재 스레드의 Realm에서 dayCard와 symptom 다시 가져오기
            guard let localDayCard = realm.object(ofType: DayCard.self, forPrimaryKey: dayCard.id),
                  let localSymptom = realm.object(ofType: Symptom.self, forPrimaryKey: symptom.id) else {
                observer.onError(NSError(domain: "Objects not found", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            do {
                try realm.write {
                    if let index = localDayCard.symptoms.index(of: localSymptom) {
                        localDayCard.symptoms.remove(at: index)
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
    
    func getDayCardsObservable(year: Int, month: Int) -> Observable<[DayCard]> {
        return Observable.create { observer in
            let realm = self.getRealm()
            let results = realm.objects(DayCard.self)
                .filter("year == %@ AND month == %@", year, month)
                .sorted(byKeyPath: "day")
            
            observer.onNext(Array(results))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func getDaysWithSymptomsObservable(year: Int, month: Int) -> Observable<[Int]> {
        return Observable.create { observer in
            let realm = self.getRealm()
            let results = realm.objects(DayCard.self)
                .filter("year == %@ AND month == %@ AND symptoms.@count > 0", year, month)
            
            observer.onNext(results.map { $0.day })
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
  // 이미지 레코드 추가 메서드
  func addImageRecord(_ imageRecords: [ImageRecord], to dayCard: DayCard) -> Observable<Void> {
      return Observable.create { observer in
          let realm = self.getRealm()
          
          guard let localDayCard = realm.object(ofType: DayCard.self, forPrimaryKey: dayCard.id) else {
              observer.onError(NSError(domain: "DayCard not found", code: -1, userInfo: nil))
              return Disposables.create()
          }
          
          do {
              try realm.write {
                  for imageRecord in imageRecords {
                      localDayCard.imageRecords.append(imageRecord)
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
