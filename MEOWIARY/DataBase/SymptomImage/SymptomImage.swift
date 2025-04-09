//
//  SymptomImage.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/9/25.
//

import Foundation
import RealmSwift

class SymptomImage: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var originalImagePath: String?  // 원본 이미지
    @Persisted var thumbnailImagePath: String? // 썸네일 이미지
    @Persisted var createdAt: Date = Date() // 생성일
    
    convenience init(originalImagePath: String, thumbnailImagePath: String) {
        self.init()
        self.originalImagePath = originalImagePath
        self.thumbnailImagePath = thumbnailImagePath
    }
}

