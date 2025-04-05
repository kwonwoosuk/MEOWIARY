//
//  DayCard.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import Foundation
import RealmSwift

// DayCard.swift
class DayCard: Object {
  @Persisted(primaryKey: true) var id: String = UUID().uuidString
  @Persisted var date: Date
  @Persisted var imageRecords: List<ImageRecord> = List<ImageRecord>()
  @Persisted var notes: String?
  @Persisted var symptoms: List<Symptom>
  @Persisted var year: Int
  @Persisted var month: Int
  @Persisted var day: Int
  
  convenience init(date: Date, notes: String? = nil) {
    self.init()
    self.date = date
    self.notes = notes
    
    let calendar = Calendar.current
    self.year = calendar.component(.year, from: date)
    self.month = calendar.component(.month, from: date)
    self.day = calendar.component(.day, from: date)
  }
}
