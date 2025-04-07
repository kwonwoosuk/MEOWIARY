//
//  SymptomRepository.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/7/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol SymptomRepositoryProtocol {
    func saveSymptom(_ symptom: Symptom, for date: Date) -> Observable<Symptom>
    func getSymptoms(for date: Date) -> [Symptom]
    func getSymptoms(year: Int, month: Int, day: Int) -> [Symptom]
    func getSymptomsByMonth(year: Int, month: Int) -> [Int: [Symptom]]
    func getSymptomDays(year: Int, month: Int) -> [Int]
    func deleteSymptom(_ symptom: Symptom) -> Observable<Void>
    func updateSymptom(_ symptom: Symptom) -> Observable<Symptom>
}

class SymptomRepository: SymptomRepositoryProtocol {
    
    let dayCardRepository = DayCardRepository()
    
    // 속성으로 저장하지 않고 필요할 때마다 새로운 Realm 인스턴스 생성
    private func getRealm() -> Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    init() {
        print("SymptomRepository 초기화 완료")
    }
    
    // 증상 저장 (DayCard에 연결)
    func saveSymptom(_ symptom: Symptom, for date: Date) -> Observable<Symptom> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "SymptomRepository", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            let calendar = Calendar.current
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            
            // 해당 날짜의 DayCard 가져오기 또는 생성
            var dayCard = self.dayCardRepository.getDayCardForDate(year: year, month: month, day: day)
            
            if dayCard == nil {
                dayCard = DayCard(date: date)
                // 새로운 DayCard를 생성한 경우, 저장해야 함
                self.dayCardRepository.saveDayCard(dayCard!)
                    .subscribe(
                        onNext: { savedDayCard in
                            // 저장된 DayCard로 교체
                            dayCard = savedDayCard
                        },
                        onError: { error in
                            observer.onError(error)
                        }
                    )
                    .disposed(by: DisposeBag())
            }
            
            guard let dayCard = dayCard else {
                observer.onError(NSError(domain: "SymptomRepository", code: -2, userInfo: nil))
                return Disposables.create()
            }
            
            // DayCard에 증상 추가
            self.dayCardRepository.addSymptom(symptom, to: dayCard)
                .subscribe(
                    onNext: {
                        observer.onNext(symptom)
                        
                        // 변경 알림 발송
                        NotificationCenter.default.post(
                            name: Notification.Name(DayCardUpdatedNotification),
                            object: nil,
                            userInfo: ["year": year, "month": month, "day": day]
                        )
                        
                        observer.onCompleted()
                    },
                    onError: { error in
                        observer.onError(error)
                    }
                )
                .disposed(by: DisposeBag())
            
            return Disposables.create()
        }
    }
    // 특정 날짜의 증상 목록 조회
    func getSymptoms(for date: Date) -> [Symptom] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        return getSymptoms(year: year, month: month, day: day)
    }
    
    // 연/월/일로 증상 목록 조회
    func getSymptoms(year: Int, month: Int, day: Int) -> [Symptom] {
        if let dayCard = dayCardRepository.getDayCardForDate(year: year, month: month, day: day) {
            return Array(dayCard.symptoms)
        }
        return []
    }
    
    // 특정 월의 모든 증상 조회 (일별로 그룹화)
    func getSymptomsByMonth(year: Int, month: Int) -> [Int: [Symptom]] {
        let dayCards = dayCardRepository.getDayCards(year: year, month: month)
        var result: [Int: [Symptom]] = [:]
        
        for dayCard in dayCards where !dayCard.symptoms.isEmpty {
            result[dayCard.day] = Array(dayCard.symptoms)
        }
        
        return result
    }
    
    // 증상이 기록된 날짜 목록 조회
    func getSymptomDays(year: Int, month: Int) -> [Int] {
        return dayCardRepository.getDaysWithSymptoms(year: year, month: month)
    }
    
    // 증상 삭제
    func deleteSymptom(_ symptom: Symptom) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "SymptomRepository", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            let realm = self.getRealm()
            
            guard let localSymptom = realm.object(ofType: Symptom.self, forPrimaryKey: symptom.id) else {
                observer.onError(NSError(domain: "SymptomRepository", code: -3, userInfo: [NSLocalizedDescriptionKey: "해당 증상을 찾을 수 없습니다"]))
                return Disposables.create()
            }
            
            // 증상이 속한 DayCard 찾기
            let dayCards = realm.objects(DayCard.self).filter("ANY symptoms.id == %@", symptom.id)
            var year = 0, month = 0, day = 0
            
            do {
                try realm.write {
                    // DayCard에서 증상 참조 제거
                    for dayCard in dayCards {
                        year = dayCard.year
                        month = dayCard.month
                        day = dayCard.day
                        
                        if let index = dayCard.symptoms.firstIndex(where: { $0.id == symptom.id }) {
                            dayCard.symptoms.remove(at: index)
                        }
                    }
                    
                    // 증상 자체 삭제
                    realm.delete(localSymptom)
                }
                
                // 변경 알림 발송
                if year > 0 {
                    NotificationCenter.default.post(
                        name: Notification.Name(DayCardUpdatedNotification),
                        object: nil,
                        userInfo: ["year": year, "month": month, "day": day]
                    )
                }
                
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    // 증상 업데이트
    func updateSymptom(_ symptom: Symptom) -> Observable<Symptom> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "SymptomRepository", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            let realm = self.getRealm()
            
            do {
                try realm.write {
                    realm.add(symptom, update: .modified)
                }
                
                // DayCard 찾기
                let dayCards = realm.objects(DayCard.self).filter("ANY symptoms.id == %@", symptom.id)
                
                // 변경 알림 발송
                if let dayCard = dayCards.first {
                    NotificationCenter.default.post(
                        name: Notification.Name(DayCardUpdatedNotification),
                        object: nil,
                        userInfo: ["year": dayCard.year, "month": dayCard.month, "day": dayCard.day]
                    )
                }
                
                observer.onNext(symptom)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
}
