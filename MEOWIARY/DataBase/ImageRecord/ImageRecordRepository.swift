//
//  ImageRecordRepository.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/4/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol ImageRecordRepositoryProtocol {
    func saveImageRecord(_ imageRecord: ImageRecord) -> Observable<ImageRecord>
    func getImageRecord(id: String) -> ImageRecord?
    func getAllImageRecords() -> [ImageRecord]
    func getFavoriteImageRecords() -> [ImageRecord]
    func toggleFavorite(imageId: String) -> Observable<Void>
    func deleteImageRecord(_ imageRecord: ImageRecord) -> Observable<Void>
}

class ImageRecordRepository: ImageRecordRepositoryProtocol {
    // 속성으로 저장하지 않고 필요할 때마다 새로운 Realm 인스턴스 생성
    private func getRealm() -> Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    func saveImageRecord(_ imageRecord: ImageRecord) -> Observable<ImageRecord> {
        return Observable.create { observer in
            // 현재 스레드에 맞는 Realm 인스턴스 생성
            let realm = self.getRealm()
            
            do {
                try realm.write {
                    realm.add(imageRecord, update: .modified)
                    print("ImageRecord 저장 성공: \(imageRecord.id)")
                }
                observer.onNext(imageRecord)
                observer.onCompleted()
            } catch {
                print("ImageRecord 저장 실패: \(error)")
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func getImageRecord(id: String) -> ImageRecord? {
        let realm = getRealm()
        return realm.object(ofType: ImageRecord.self, forPrimaryKey: id)
    }
    
    func getAllImageRecords() -> [ImageRecord] {
        let realm = getRealm()
        let results = realm.objects(ImageRecord.self).sorted(byKeyPath: "createdAt", ascending: false)
        return Array(results)  // Realm 결과를 배열로 변환
    }
    
    func getFavoriteImageRecords() -> [ImageRecord] {
        let realm = getRealm()
        let results = realm.objects(ImageRecord.self)
            .filter("isFavorite == true")
            .sorted(byKeyPath: "createdAt", ascending: false)
        return Array(results)  // Realm 결과를 배열로 변환
    }
    
    func toggleFavorite(imageId: String) -> Observable<Void> {
        return Observable.create { observer in
            let realm = self.getRealm()
            
            guard let imageRecord = realm.object(ofType: ImageRecord.self, forPrimaryKey: imageId) else {
                observer.onError(NSError(domain: "ImageRecord not found", code: -1, userInfo: nil))
                return Disposables.create()
            }
            
            do {
                try realm.write {
                    imageRecord.isFavorite = !imageRecord.isFavorite
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func deleteImageRecord(_ imageRecord: ImageRecord) -> Observable<Void> {
        return Observable.create { observer in
            let realm = self.getRealm()
            
            do {
                try realm.write {
                    // 연결된 DayCard에서 이미지 레코드 참조 제거
                    let dayCards = realm.objects(DayCard.self).filter("imageRecord.id == %@", imageRecord.id)
                    for dayCard in dayCards {
                        dayCard.imageRecord = nil
                    }
                    
                    // 이미지 레코드 삭제
                    realm.delete(imageRecord)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    // RxSwift를 활용한 Observable 메서드 추가
    func getAllImageRecordsObservable() -> Observable<[ImageRecord]> {
        return Observable.create { observer in
            let realm = self.getRealm()
            let results = realm.objects(ImageRecord.self).sorted(byKeyPath: "createdAt", ascending: false)
            
            observer.onNext(Array(results))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func getFavoriteImageRecordsObservable() -> Observable<[ImageRecord]> {
        return Observable.create { observer in
            let realm = self.getRealm()
            let results = realm.objects(ImageRecord.self)
                .filter("isFavorite == true")
                .sorted(byKeyPath: "createdAt", ascending: false)
            
            observer.onNext(Array(results))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
