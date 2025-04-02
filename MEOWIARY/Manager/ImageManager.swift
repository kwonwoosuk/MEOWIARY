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
    
    // 이미지 저장 (원본, 썸네일 생성 후 저장)
    func saveImage(_ image: UIImage) -> Observable<ImageRecord> {
        return Observable.create { observer in
            let imageID = UUID().uuidString
            let originalImagePath = self.getOriginalImagesDirectory().appendingPathComponent("\(imageID).jpg")
            let thumbnailImagePath = self.getThumbnailImagesDirectory().appendingPathComponent("\(imageID).jpg")
            
            // 원본 이미지 저장
            if let originalData = image.jpegData(compressionQuality: 0.9) {
                do {
                    try originalData.write(to: originalImagePath)
                    
                    // 썸네일 생성 및 저장
                    if let thumbnail = self.resizeImage(image, targetSize: CGSize(width: 200, height: 200)) {
                        if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
                            try thumbnailData.write(to: thumbnailImagePath)
                            
                            // 이미지 레코드 생성
                            let imageRecord = ImageRecord(
                                originalImagePath: originalImagePath.lastPathComponent,
                                thumbnailImagePath: thumbnailImagePath.lastPathComponent
                            )
                            
                            observer.onNext(imageRecord)
                            observer.onCompleted()
                        } else {
                            observer.onError(NSError(domain: "com.meowiary.imagemanager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create thumbnail data"]))
                        }
                    } else {
                        observer.onError(NSError(domain: "com.meowiary.imagemanager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create thumbnail"]))
                    }
                } catch {
                    observer.onError(error)
                }
            } else {
                observer.onError(NSError(domain: "com.meowiary.imagemanager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create image data"]))
            }
            
            return Disposables.create()
        }
    }
    
    // 썸네일 이미지 로드
    func loadThumbnailImage(from imagePath: String?) -> UIImage? {
        guard let imagePath = imagePath else { return nil }
        let fileURL = getThumbnailImagesDirectory().appendingPathComponent(imagePath)
        
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return UIImage(systemName: "photo")
    }
    
    // 원본 이미지 로드
    func loadOriginalImage(from imagePath: String?) -> UIImage? {
        guard let imagePath = imagePath else { return nil }
        let fileURL = getOriginalImagesDirectory().appendingPathComponent(imagePath)
        
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
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
                try? fileManager.removeItem(at: originalURL)
            }
            
            if let thumbnailPath = imageRecord.thumbnailImagePath {
                let thumbnailURL = self.getThumbnailImagesDirectory().appendingPathComponent(thumbnailPath)
                try? fileManager.removeItem(at: thumbnailURL)
            }
            
            observer.onNext(())
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
