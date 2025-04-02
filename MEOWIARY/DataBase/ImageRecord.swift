//
//  ImageRecord.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import Foundation
import RealmSwift

// 이미지 저장 모델
class ImageRecord: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var originalImagePath: String?     // 원본 이미지 경로
    @Persisted var thumbnailImagePath: String?    // 썸네일 이미지 경로
    @Persisted var createdAt: Date = Date()       // 생성 시간
    @Persisted var isFavorite: Bool = false       // 즐겨찾기 여부
    
    convenience init(originalImagePath: String, thumbnailImagePath: String) {
        self.init()
        self.originalImagePath = originalImagePath
        self.thumbnailImagePath = thumbnailImagePath
    }
}
