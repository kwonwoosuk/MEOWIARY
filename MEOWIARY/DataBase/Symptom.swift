//
//  Symptom.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/30/25.
//

import Foundation
import RealmSwift

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


