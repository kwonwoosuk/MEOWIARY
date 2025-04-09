//
//  SymptomImageRepository.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/9/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol SymptomImageRepositoryProtocol {
    func saveSymptomImage(_ symptomImage: SymptomImage) -> Observable<SymptomImage>
    func getSymptomImage(id: String) -> SymptomImage?
    func getAllSymptomImages() -> [SymptomImage]
    func deleteSymptomImage(_ symptomImage: SymptomImage) -> Observable<Void>
}

class SymptomImageRepository: SymptomImageRepositoryProtocol {
    // 속성으로 저장하지 않고 필요할 때마다 새로운 Realm 인스턴스 생성
    private func getRealm() -> Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    func saveSymptomImage(_ symptomImage: SymptomImage) -> Observable<SymptomImage> {
        return Observable.create { observer in
            let realm = self.getRealm()
            
            do {
                try realm.write {
                    realm.add(symptomImage, update: .modified)
                    print("SymptomImage 저장 성공: \(symptomImage.id)")
                }
                observer.onNext(symptomImage)
                observer.onCompleted()
            } catch {
                print("SymptomImage 저장 실패: \(error)")
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func getSymptomImage(id: String) -> SymptomImage? {
        let realm = getRealm()
        return realm.object(ofType: SymptomImage.self, forPrimaryKey: id)
    }
    
    func getAllSymptomImages() -> [SymptomImage] {
        let realm = getRealm()
        let results = realm.objects(SymptomImage.self).sorted(byKeyPath: "createdAt", ascending: false)
        return Array(results)
    }
    
    func deleteSymptomImage(_ symptomImage: SymptomImage) -> Observable<Void> {
        return Observable.create { observer in
            let realm = self.getRealm()
            
            // 파일 경로 정보 미리 저장
            let originalPath = symptomImage.originalImagePath
            let thumbnailPath = symptomImage.thumbnailImagePath
            
            do {
                try realm.write {
                    realm.delete(symptomImage)
                }
                
                // 파일 시스템에서 이미지 파일 삭제
                if let path = originalPath {
                    ImageManager.shared.deleteImageFile(path: path, isOriginal: true)
                }
                if let path = thumbnailPath {
                    ImageManager.shared.deleteImageFile(path: path, isOriginal: false)
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
