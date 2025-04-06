//
//  GalleryCell.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class GalleryCell: UICollectionViewCell {
  
  // MARK: - Properties
  var disposeBag = DisposeBag()
  let favoriteButtonTap = PublishSubject<Void>()
  let shareButtonTap = PublishSubject<Void>()
  
  // MARK: - UI Components
  // 날짜 컨테이너
  private let dateContainer: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 12
    view.clipsToBounds = true
    return view
  }()
  
  // 날짜 레이블 (일)
  private let dayLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.bold(size: 46)
    label.textColor = DesignSystem.Color.Tint.main.inUIColor()
    label.textAlignment = .center
    return label
  }()
  
  // 요일 레이블
  private let weekdayLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
    label.textColor = DesignSystem.Color.Tint.main.inUIColor()
    label.textAlignment = .center
    return label
  }()
  
  // 이미지 컨테이너
  private let imageContainer: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 12
    view.clipsToBounds = true
    return view
  }()
  
  // 이미지 뷰
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()
  
  // 일기 내용 오버레이 (이미지 위에 텍스트 표시)
  private let textOverlay: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    view.isHidden = true
    return view
  }()
  
  // 메모 텍스트 레이블
  private let notesLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    label.textColor = .white
    label.numberOfLines = 3
    label.textAlignment = .center
    return label
  }()
  
  // MARK: - Initialization
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
    notesLabel.text = nil
    dayLabel.text = nil
    weekdayLabel.text = nil
    disposeBag = DisposeBag()
    textOverlay.isHidden = true
  }
  
  // MARK: - Setup
  private func setupUI() {
    // 셀 자체 설정
    contentView.backgroundColor = UIColor(hex: "F9F9F9")
    contentView.layer.cornerRadius = 16
    contentView.clipsToBounds = true
    
    // 뷰 계층 구조 설정
    contentView.addSubview(dateContainer)
    dateContainer.addSubview(dayLabel)
    dateContainer.addSubview(weekdayLabel)
    
    contentView.addSubview(imageContainer)
    imageContainer.addSubview(imageView)
    imageContainer.addSubview(textOverlay)
    textOverlay.addSubview(notesLabel)
    
    // 레이아웃 설정
    dateContainer.snp.makeConstraints { make in
      make.leading.top.bottom.equalToSuperview().inset(8)
      make.width.equalTo(120)
    }
    
    dayLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(20)
    }
    
    weekdayLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(dayLabel.snp.bottom).offset(2)
      make.bottom.lessThanOrEqualToSuperview().offset(-8)
    }
    
    imageContainer.snp.makeConstraints { make in
      make.leading.equalTo(dateContainer.snp.trailing).offset(8)
      make.top.trailing.bottom.equalToSuperview().inset(8)
    }
    
    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    textOverlay.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    notesLabel.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.leading.trailing.equalToSuperview().inset(12)
    }
    
    // 버튼 액션 바인딩
    let tapGesture = UITapGestureRecognizer()
    tapGesture.numberOfTapsRequired = 2
    imageContainer.addGestureRecognizer(tapGesture)
    
    tapGesture.rx.event
        .subscribe(onNext: { [weak self] _ in
            self?.favoriteButtonTap.onNext(())
        })
        .disposed(by: disposeBag)
  }
  
  // MARK: - Configuration
  func configure(with imageData: GalleryViewModel.ImageData, imageManager: ImageManager) {
    // 날짜 포맷팅 (일)
    dayLabel.text = "\(imageData.day)"
    
    // 요일 설정
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "E"
    weekdayLabel.text = "\(dateFormatter.string(from: imageData.createdAt))"
    
    // 이미지 로드
    if let image = imageManager.loadThumbnailImage(from: imageData.thumbnailPath) {
      imageView.image = image
      
      // 노트가 있는 경우 텍스트 오버레이 표시
      if let notes = imageData.notes, !notes.isEmpty {
        textOverlay.isHidden = false
        notesLabel.text = notes
      } else {
        textOverlay.isHidden = true
      }
    } else {
      // 이미지가 없는 경우 기본 이미지 설정
      imageView.image = UIImage(systemName: "photo")
      imageView.contentMode = .scaleAspectFit
      imageView.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
      textOverlay.isHidden = true
    }
  }
}
