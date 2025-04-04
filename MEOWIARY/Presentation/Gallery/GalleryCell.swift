//
//  ImageGalleryCell.swift
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
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()
  
  private let overlayView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    view.isHidden = true
    return view
  }()
  
  private let favoriteButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "heart"), for: .normal)
    button.tintColor = .white
    button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    button.layer.cornerRadius = 15
    return button
  }()
  
  private let shareButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
    button.tintColor = .white
    button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    button.layer.cornerRadius = 15
    return button
  }()
  
  private let dateLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
    label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    label.layer.cornerRadius = 8
    label.clipsToBounds = true
    label.textAlignment = .center
    label.isHidden = true
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
    disposeBag = DisposeBag()
    dateLabel.text = nil
  }
  
  // MARK: - Setup
  private func setupUI() {
    contentView.addSubview(imageView)
    contentView.addSubview(overlayView)
    contentView.addSubview(favoriteButton)
    contentView.addSubview(shareButton)
    contentView.addSubview(dateLabel)
    
    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    overlayView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    favoriteButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-8)
      make.leading.equalToSuperview().offset(8)
      make.width.height.equalTo(30)
    }
    
    shareButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-8)
      make.trailing.equalToSuperview().offset(-8)
      make.width.height.equalTo(30)
    }
    
    dateLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(8)
      make.leading.equalToSuperview().offset(8)
      make.height.equalTo(20)
      make.width.equalTo(80)
    }
    
    favoriteButton.rx.tap
      .bind(to: favoriteButtonTap)
      .disposed(by: disposeBag)
    
    shareButton.rx.tap
      .bind(to: shareButtonTap)
      .disposed(by: disposeBag)
    
    // 셀 호버 효과 (터치 시 오버레이 표시)
    let touchDown = UILongPressGestureRecognizer(target: self, action: #selector(handleTouchDown(_:)))
    touchDown.minimumPressDuration = 0.1
    self.addGestureRecognizer(touchDown)
  }
  
  // MARK: - Configuration
  func configure(with imageData: GalleryViewModel.ImageData, imageManager: ImageManager) {
      // 썸네일 이미지 로드
      if let image = imageManager.loadThumbnailImage(from: imageData.thumbnailPath) {
        imageView.image = image
      } else {
        // 기본 이미지 설정
        imageView.image = UIImage(systemName: "photo")
        print("썸네일 로드 실패: \(imageData.thumbnailPath)")
      }
      
      // 즐겨찾기 상태 반영
      let heartImageName = imageData.isFavorite ? "heart.fill" : "heart"
      favoriteButton.setImage(UIImage(systemName: heartImageName), for: .normal)
      
      // 날짜 포맷
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy.MM.dd"
      dateLabel.text = dateFormatter.string(from: imageData.createdAt)
    }
  
  // MARK: - Actions
  @objc private func handleTouchDown(_ gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .began:
      // 터치 시작 - 오버레이 표시
      overlayView.isHidden = false
      dateLabel.isHidden = false
      UIView.animate(withDuration: 0.2) {
        self.favoriteButton.alpha = 1.0
        self.shareButton.alpha = 1.0
        self.dateLabel.alpha = 1.0
      }
    case .ended, .cancelled:
      // 터치 종료 - 오버레이 숨김
      UIView.animate(withDuration: 0.2) {
        self.overlayView.isHidden = true
        self.dateLabel.isHidden = true
      }
    default:
      break
    }
  }
}
