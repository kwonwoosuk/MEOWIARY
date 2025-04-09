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
    @Persisted var name: String // 증상명
    @Persisted var severity: Int // 1-5 scale 증상 심각도
    //    @Persisted var imageUrl: String?
    @Persisted var timestamp: Date
    @Persisted var notes: String? // 증상설명
    @Persisted var symptomImages: List<SymptomImage> = List<SymptomImage>() //  증상이미지를 저장할 별개의 이미지 리스트
    
    convenience init(name: String, description: String? = nil, severity: Int = 1) {
        self.init()
        self.name = name
        self.notes = description
        self.severity = max(1, min(5, severity)) // Ensure severity is between 1-5
        //               self.imageUrl = imageUrl
        self.timestamp = Date()
    }
}


