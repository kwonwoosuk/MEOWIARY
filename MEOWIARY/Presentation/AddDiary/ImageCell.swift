//
//  ImageCell.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/5/25.
//

import UIKit
import AVFoundation
import UniformTypeIdentifiers

class ImageCell: UICollectionViewCell {
 
 var deleteAction: (() -> Void)?
 
 private let imageView: UIImageView = {
   let imageView = UIImageView()
   imageView.contentMode = .scaleAspectFill
   imageView.clipsToBounds = true
   imageView.layer.cornerRadius = 8
   return imageView
 }()
 
 private let deleteButton: UIButton = {
   let button = UIButton(type: .system)
   button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
   button.tintColor = .white
   button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
   button.layer.cornerRadius = 12
   return button
 }()
 
 override init(frame: CGRect) {
   super.init(frame: frame)
   setupUI()
 }
 
 required init?(coder: NSCoder) {
   fatalError("init(coder:) has not been implemented")
 }
 
 private func setupUI() {
   contentView.addSubview(imageView)
   contentView.addSubview(deleteButton)
   
   imageView.snp.makeConstraints { make in
     make.edges.equalToSuperview()
   }
   
   deleteButton.snp.makeConstraints { make in
     make.top.trailing.equalToSuperview().inset(4)
     make.width.height.equalTo(24)
   }
   
   deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
 }
 
 func configure(with image: UIImage) {
   imageView.image = image
 }
 
 @objc private func deleteButtonTapped() {
   deleteAction?()
 }
}

// MARK: - 미디어 생성 클래스
class MediaGenerator {
 
 // GIF 생성
 static func createGIF(from images: [UIImage], duration: TimeInterval = 2.0) -> URL? {
   let fileProperties: [String: Any] = [
     kCGImagePropertyGIFDictionary as String: [
       kCGImagePropertyGIFLoopCount as String: 0 // 무한 반복
     ]
   ]
   
   let frameProperties: [String: Any] = [
     kCGImagePropertyGIFDictionary as String: [
       kCGImagePropertyGIFDelayTime as String: duration / Double(images.count)
     ]
   ]
   
   // 임시 파일 URL 생성
   let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
   let gifFileName = "generated_gif_\(Date().timeIntervalSince1970).gif"
   let fileURL = documentsDirectory.appendingPathComponent(gifFileName)
   
   // 기존 파일 삭제
   try? FileManager.default.removeItem(at: fileURL)
   
   // GIF 생성
   guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.gif.identifier as CFString, images.count, nil) else {
          return nil
      }
   
   CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
   
   for image in images {
     if let cgImage = image.cgImage {
       CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
     }
   }
   
   if CGImageDestinationFinalize(destination) {
     return fileURL
   }
   
   return nil
 }
 
 // 동영상 생성
 static func createVideo(from images: [UIImage], duration: TimeInterval = 3.0, completion: @escaping (URL?) -> Void) {
   let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
   let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("generated_video_\(Date().timeIntervalSince1970).mp4"))
   
   // 기존 파일 삭제
   try? FileManager.default.removeItem(at: videoOutputURL)
   
   guard let firstImage = images.first else {
     completion(nil)
     return
   }
   
   let videoSize = firstImage.size
   let framePerSecond: Int32 = 30
   
   // 비디오 설정
   let settings: [String: Any] = [
     AVVideoCodecKey: AVVideoCodecType.h264,
     AVVideoWidthKey: videoSize.width,
     AVVideoHeightKey: videoSize.height
   ]
   
   // AVAssetWriter 생성
   guard let assetWriter = try? AVAssetWriter(outputURL: videoOutputURL, fileType: .mp4) else {
     completion(nil)
     return
   }
   
   let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
   writerInput.expectsMediaDataInRealTime = true
   
   let adaptorAttributes: [String: Any] = [
     kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
     kCVPixelBufferWidthKey as String: videoSize.width,
     kCVPixelBufferHeightKey as String: videoSize.height
   ]
   
   let adaptor = AVAssetWriterInputPixelBufferAdaptor(
     assetWriterInput: writerInput,
     sourcePixelBufferAttributes: adaptorAttributes
   )
   
   if assetWriter.canAdd(writerInput) {
     assetWriter.add(writerInput)
   } else {
     completion(nil)
     return
   }
   
   // 비디오 생성 시작
   assetWriter.startWriting()
   assetWriter.startSession(atSourceTime: .zero)
   
   // 각 프레임 사이 시간 간격
   let frameTime = duration / Double(images.count)
   var frameCount: Int64 = 0
   
   // 각 이미지를 프레임으로 추가
   let queue = DispatchQueue(label: "mediaGenerator.createVideo")
   writerInput.requestMediaDataWhenReady(on: queue) {
     for image in images {
       if !writerInput.isReadyForMoreMediaData {
         continue
       }
       
       let presentationTime = CMTime(value: frameCount, timescale: framePerSecond)
       
       if let buffer = MediaGenerator.pixelBufferFromImage(image: image, size: videoSize),
          adaptor.append(buffer, withPresentationTime: presentationTime) {
         frameCount += Int64(frameTime * Double(framePerSecond))
       }
     }
     
     writerInput.markAsFinished()
     assetWriter.finishWriting {
       DispatchQueue.main.async {
         completion(videoOutputURL)
       }
     }
   }
 }
 
 // 이미지를 픽셀 버퍼로 변환
 private static func pixelBufferFromImage(image: UIImage, size: CGSize) -> CVPixelBuffer? {
   var pixelBuffer: CVPixelBuffer?
   let options: [String: Any] = [
     kCVPixelBufferCGImageCompatibilityKey as String: true,
     kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
   ]
   
   let status = CVPixelBufferCreate(
     kCFAllocatorDefault,
     Int(size.width),
     Int(size.height),
     kCVPixelFormatType_32ARGB,
     options as CFDictionary,
     &pixelBuffer
   )
   
   guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
     return nil
   }
   
   CVPixelBufferLockBaseAddress(buffer, [])
   
   let context = CGContext(
     data: CVPixelBufferGetBaseAddress(buffer),
     width: Int(size.width),
     height: Int(size.height),
     bitsPerComponent: 8,
     bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
     space: CGColorSpaceCreateDeviceRGB(),
     bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
   )
   
   if let cgImage = image.cgImage, let context = context {
     let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
     context.draw(cgImage, in: rect)
   }
   
   CVPixelBufferUnlockBaseAddress(buffer, [])
   
   return buffer
 }
}
