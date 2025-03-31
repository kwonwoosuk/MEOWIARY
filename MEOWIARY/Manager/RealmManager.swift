//
//  RealmManager.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/30/25.
//

import Foundation
import RealmSwift
import RxSwift

final class RealmManager {
    
    // MARK: - Properties
    
    
    // MARK: - Initialization
    private var realm: Realm {
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
}
