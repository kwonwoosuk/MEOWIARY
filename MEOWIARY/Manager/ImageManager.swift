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
    private var imageCache: [String: UIImage] = [:]
    
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
    
    // 원본 이미지 로드
    func loadOriginalImage(from imagePath: String?) -> UIImage? {
           guard let imagePath = imagePath else {
               print("이미지 경로가 nil입니다.")
               return nil
           }
           
           // 캐시에 있으면 캐시에서 반환
           if let cachedImage = imageCache[imagePath] {
               return cachedImage
           }
           
           let fileURL = getOriginalImagesDirectory().appendingPathComponent(imagePath)
           
           print("원본 이미지 로드 시도: \(fileURL.path)")
           
           if FileManager.default.fileExists(atPath: fileURL.path) {
               if let data = try? Data(contentsOf: fileURL) {
                   print("원본 이미지 로드 성공: \(data.count) 바이트")
                   if let image = UIImage(data: data) {
                       // 캐시에 저장
                       imageCache[imagePath] = image
                       return image
                   }
               } else {
                   print("원본 이미지 로드 실패: 데이터를 읽을 수 없음")
                   return nil
               }
           } else {
               print("원본 이미지 로드 실패: 파일이 존재하지 않음 - \(fileURL.path)")
               return nil
           }
           return nil
       }
    
    // 비동기 이미지 로딩 메서드
    func loadOriginalImageAsync(from imagePath: String?) async -> UIImage? {
        guard let imagePath = imagePath else {
            print("이미지 경로가 nil입니다.")
            return nil
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = self.loadOriginalImage(from: imagePath)
                continuation.resume(returning: image)
            }
        }
    }
    
    // 나머지 메서드는 변경 없음
    func saveImage(_ image: UIImage) -> Observable<ImageRecord> {
        return Observable.create { observer in
            let imageID = UUID().uuidString
            print("이미지 저장 시작 - 이미지 ID: \(imageID), 크기: \(image.size), 스케일: \(image.scale)")
            
            let normalizedImage = self.normalizeImageOrientation(image)
            print("이미지 방향 정규화 완료")
            
            if let originalData = normalizedImage.jpegData(compressionQuality: 0.9) {
                let originalImagePath = "\(imageID).jpg"
                let thumbnailImagePath = "\(imageID).jpg"
                
                let originalFileURL = self.getOriginalImagesDirectory().appendingPathComponent(originalImagePath)
                let thumbnailFileURL = self.getThumbnailImagesDirectory().appendingPathComponent(thumbnailImagePath)
                
                print("JPEG 변환 성공: \(originalData.count) 바이트")
                
                do {
                    try originalData.write(to: originalFileURL)
                    print("원본 이미지 저장 성공: \(originalFileURL.path)")
                    
                    if let thumbnail = self.resizeImage(normalizedImage, targetSize: CGSize(width: 200, height: 200)) {
                        if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
                            try thumbnailData.write(to: thumbnailFileURL)
                            print("썸네일 저장 성공: \(thumbnailFileURL.path)")
                            
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
                        
                        if let thumbnail = self.resizeImage(normalizedImage, targetSize: CGSize(width: 200, height: 200)) {
                            if let thumbnailData = thumbnail.pngData() {
                                try thumbnailData.write(to: thumbnailFileURL)
                                print("PNG 썸네일 저장 성공: \(thumbnailFileURL.path)")
                                
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
    
    func loadThumbnailImage(from imagePath: String?) -> UIImage? {
            guard let imagePath = imagePath else { return nil }
            
            // 캐시에 있으면 캐시에서 반환
            if let cachedImage = imageCache[imagePath] {
                return cachedImage
            }
            
            let fileURL = getThumbnailImagesDirectory().appendingPathComponent(imagePath)
            
            print("썸네일 로드 시도: \(fileURL.path)")
            
            if let data = try? Data(contentsOf: fileURL) {
                print("썸네일 로드 성공: \(data.count) 바이트")
                if let image = UIImage(data: data) {
                    // 캐시에 저장
                    imageCache[imagePath] = image
                    return image
                }
            }
            print("썸네일 로드 실패: 파일이 없음")
            return UIImage(systemName: "photo")
        }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
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
    
  func deleteImage(imageRecord: ImageRecord) -> Observable<Void> {
      return Observable.create { observer in
          // 경로 정보를 미리 복사해둠
          let originalPath = imageRecord.originalImagePath
          let thumbnailPath = imageRecord.thumbnailImagePath
          
          // 파일 시스템에서 이미지 파일 삭제
          let fileManager = FileManager.default
          
          // 원본 이미지 파일 삭제
          if let path = originalPath {
              self.deleteImageFile(path: path, isOriginal: true)
          }
          
          // 썸네일 이미지 파일 삭제
          if let path = thumbnailPath {
              self.deleteImageFile(path: path, isOriginal: false)
          }
          
          observer.onNext(())
          observer.onCompleted()
          
          return Disposables.create()
      }
  }
  
  // 이미지 파일 직접 삭제 메서드
    func deleteImageFile(path: String, isOriginal: Bool) {
        // 스레드 안전하게 백그라운드에서 파일 삭제 처리
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            let directory = isOriginal ? self.getOriginalImagesDirectory() : self.getThumbnailImagesDirectory()
            let fileURL = directory.appendingPathComponent(path)
            
            do {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                    
                    // 파일 삭제 후 메인 스레드에서 캐시 제거
                    DispatchQueue.main.async { [weak self] in
                        self?.clearImageCache(for: path)
                    }
                    
                    print("ImageManager: 이미지 파일 삭제 성공 - \(fileURL.path)")
                } else {
                    print("ImageManager: 삭제할 파일이 없음 - \(fileURL.path)")
                }
            } catch {
                print("ImageManager: 파일 삭제 실패 - \(error.localizedDescription)")
            }
        }
    }
    
    func clearImageCache(for path: String?) {
        // 안전하게 처리 - 경로가 nil이거나 빈 문자열이면 무시
        guard let path = path, !path.isEmpty else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.imageCache.removeValue(forKey: path)
            print("ImageManager: 이미지 캐시 제거 - \(path)")
        }
    }

    // 특정 연도/월에 해당하는 모든 이미지 캐시 제거
    func clearAllImageCacheForMonth(year: Int, month: Int) {
        // 스레드 안전하게 메인 스레드에서 캐시 전체 비우기
        DispatchQueue.main.async { [weak self] in
            self?.imageCache.removeAll()
            print("ImageManager: 이미지 캐시를 모두 비웠습니다 - \(year)년 \(month)월")
        }
    }
}
