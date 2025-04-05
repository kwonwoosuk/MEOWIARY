//
//  ImageManager.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import UIKit
import RxSwift

class ImageManager {
    static let shared = ImageManager()
    
    private init() {
        createDirectoriesIfNeeded()
    }
    
    // 디렉토리 생성
    private func createDirectoriesIfNeeded() {
        let fileManager = FileManager.default
        let paths = [getOriginalImagesDirectory(), getThumbnailImagesDirectory()]
        
        for path in paths {
            if !fileManager.fileExists(atPath: path.path) {
                do {
                    try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
                    print("디렉토리 생성 성공: \(path.path)")
                } catch {
                    print("Failed to create directory: \(error)")
                }
            }
        }
    }
    
    // 원본 이미지 디렉토리
    private func getOriginalImagesDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("original_images")
    }
    
    // 썸네일 이미지 디렉토리
    private func getThumbnailImagesDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("thumbnail_images")
    }
    
    // 파일 존재 여부 확인 메서드
    func checkImageFileExists(path: String) -> Bool {
        let originalURL = getOriginalImagesDirectory().appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: originalURL.path)
    }
    
    // 이미지 저장 (원본, 썸네일 생성 후 저장)
    func saveImage(_ image: UIImage) -> Observable<ImageRecord> {
        return Observable.create { observer in
            let imageID = UUID().uuidString
            print("이미지 저장 시작 - 이미지 ID: \(imageID), 크기: \(image.size), 스케일: \(image.scale)")
            
            // 정규화된 이미지 생성 - 방향 보정
            let normalizedImage = self.normalizeImageOrientation(image)
            print("이미지 방향 정규화 완료")
            
            // JPEG으로 시도
            if let originalData = normalizedImage.jpegData(compressionQuality: 0.9) {
                let originalImagePath = "\(imageID).jpg"
                let thumbnailImagePath = "\(imageID).jpg"
                
                let originalFileURL = self.getOriginalImagesDirectory().appendingPathComponent(originalImagePath)
                let thumbnailFileURL = self.getThumbnailImagesDirectory().appendingPathComponent(thumbnailImagePath)
                
                print("JPEG 변환 성공: \(originalData.count) 바이트")
                
                do {
                    try originalData.write(to: originalFileURL)
                    print("원본 이미지 저장 성공: \(originalFileURL.path)")
                    
                    // 썸네일 생성 및 저장
                    if let thumbnail = self.resizeImage(normalizedImage, targetSize: CGSize(width: 200, height: 200)) {
                        if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
                            try thumbnailData.write(to: thumbnailFileURL)
                            print("썸네일 저장 성공: \(thumbnailFileURL.path)")
                            
                            // 이미지 레코드 생성
                            let imageRecord = ImageRecord(originalImagePath: originalImagePath, thumbnailImagePath: thumbnailImagePath)
                            
                            observer.onNext(imageRecord)
                            observer.onCompleted()
                        } else {
                            print("썸네일 JPEG 변환 실패")
                            observer.onError(NSError(domain: "com.meowiary.imagemanager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create thumbnail data"]))
                        }
                    } else {
                        print("썸네일 생성 실패")
                        observer.onError(NSError(domain: "com.meowiary.imagemanager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create thumbnail"]))
                    }
                } catch {
                    print("이미지 저장 실패: \(error.localizedDescription)")
                    observer.onError(error)
                }
            } else {
                // JPEG 실패 시 PNG로 시도
                print("JPEG 변환 실패, PNG로 시도")
                if let originalData = normalizedImage.pngData() {
                    let originalImagePath = "\(imageID).png"
                    let thumbnailImagePath = "\(imageID).png"
                    
                    let originalFileURL = self.getOriginalImagesDirectory().appendingPathComponent(originalImagePath)
                    let thumbnailFileURL = self.getThumbnailImagesDirectory().appendingPathComponent(thumbnailImagePath)
                    
                    print("PNG 변환 성공: \(originalData.count) 바이트")
                    
                    do {
                        try originalData.write(to: originalFileURL)
                        print("PNG 원본 이미지 저장 성공: \(originalFileURL.path)")
                        
                        // 썸네일 생성 및 저장
                        if let thumbnail = self.resizeImage(normalizedImage, targetSize: CGSize(width: 200, height: 200)) {
                            if let thumbnailData = thumbnail.pngData() {
                                try thumbnailData.write(to: thumbnailFileURL)
                                print("PNG 썸네일 저장 성공: \(thumbnailFileURL.path)")
                                
                                // 이미지 레코드 생성
                                let imageRecord = ImageRecord(originalImagePath: originalImagePath, thumbnailImagePath: thumbnailImagePath)
                                
                                observer.onNext(imageRecord)
                                observer.onCompleted()
                            } else {
                                print("PNG 썸네일 변환 실패")
                                observer.onError(NSError(domain: "com.meowiary.imagemanager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG thumbnail data"]))
                            }
                        } else {
                            print("PNG 썸네일 생성 실패")
                            observer.onError(NSError(domain: "com.meowiary.imagemanager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create thumbnail for PNG"]))
                        }
                    } catch {
                        print("PNG 이미지 저장 실패: \(error.localizedDescription)")
                        observer.onError(error)
                    }
                } else {
                    print("JPEG 및 PNG 변환 모두 실패")
                    observer.onError(NSError(domain: "com.meowiary.imagemanager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create image data (both JPEG and PNG)"]))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // 썸네일 이미지 로드
    func loadThumbnailImage(from imagePath: String?) -> UIImage? {
        guard let imagePath = imagePath else { return nil }
        let fileURL = getThumbnailImagesDirectory().appendingPathComponent(imagePath)
        
        print("썸네일 로드 시도: \(fileURL.path)")
        
        if let data = try? Data(contentsOf: fileURL) {
            print("썸네일 로드 성공: \(data.count) 바이트")
            return UIImage(data: data)
        }
        print("썸네일 로드 실패: 파일이 없음")
        return UIImage(systemName: "photo")
    }
    
    // 원본 이미지 로드
    func loadOriginalImage(from imagePath: String?) -> UIImage? {
        guard let imagePath = imagePath else { return nil }
        let fileURL = getOriginalImagesDirectory().appendingPathComponent(imagePath)
        
        print("원본 이미지 로드 시도: \(fileURL.path)")
        
        if let data = try? Data(contentsOf: fileURL) {
            print("원본 이미지 로드 성공: \(data.count) 바이트")
            return UIImage(data: data)
        }
        print("원본 이미지 로드 실패: 파일이 없음")
        return nil
    }
    
    // 이미지 리사이징
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // 이미지 비율 유지를 위한 스케일 계산
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let scaledImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        
        return scaledImage
    }
    
    // 이미지 방향 정규화 (올바른 방향으로 회전)
    func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
    
    // 이미지 삭제
    func deleteImage(imageRecord: ImageRecord?) -> Observable<Void> {
        return Observable.create { observer in
            guard let imageRecord = imageRecord else {
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }
            
            let fileManager = FileManager.default
            
            if let originalPath = imageRecord.originalImagePath {
                let originalURL = self.getOriginalImagesDirectory().appendingPathComponent(originalPath)
                do {
                    try fileManager.removeItem(at: originalURL)
                    print("원본 이미지 삭제 성공: \(originalURL.path)")
                } catch {
                    print("원본 이미지 삭제 실패: \(error.localizedDescription)")
                }
            }
            
            if let thumbnailPath = imageRecord.thumbnailImagePath {
                let thumbnailURL = self.getThumbnailImagesDirectory().appendingPathComponent(thumbnailPath)
                do {
                    try fileManager.removeItem(at: thumbnailURL)
                    print("썸네일 이미지 삭제 성공: \(thumbnailURL.path)")
                } catch {
                    print("썸네일 이미지 삭제 실패: \(error.localizedDescription)")
                }
            }
            
            observer.onNext(())
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
