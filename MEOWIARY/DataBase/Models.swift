//
//  Models.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/30/25.
//

import Foundation
import RealmSwift

// MARK: - DayCard Model
class DayCard: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var date: Date
    @Persisted var imageUrl: String?
    @Persisted var notes: String?
    @Persisted var symptoms: List<Symptom>
    @Persisted var year: Int
    @Persisted var month: Int
    @Persisted var day: Int
    
    convenience init(date: Date, imageUrl: String? = nil, notes: String? = nil) {
        self.init()
        self.date = date
        self.imageUrl = imageUrl
        self.notes = notes
        
        let calendar = Calendar.current
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
        self.day = calendar.component(.day, from: date)
    }
}

// MARK: - Symptom Model
class Symptom: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String
    
    @Persisted var severity: Int // 1-5 scale
    @Persisted var imageUrl: String?
    @Persisted var timestamp: Date
    
    convenience init(name: String, description: String? = nil, severity: Int = 1, imageUrl: String? = nil) {
        self.init()
        self.name = name
        
        self.severity = max(1, min(5, severity)) // Ensure severity is between 1-5
        self.imageUrl = imageUrl
        self.timestamp = Date()
    }
}


