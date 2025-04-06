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
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()
  
  private let overlayView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    return view
  }()
  
  private let infoContainer: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    view.layer.cornerRadius = 8
    return view
  }()
  
  private let dateLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.small)
    label.textAlignment = .left
    return label
  }()
  
  private let notesLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
    label.textAlignment = .left
    label.numberOfLines = 6
    return label
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
    dateLabel.text = nil
    notesLabel.text = nil
    disposeBag = DisposeBag()
    favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
  }
  
  // MARK: - Setup
  private func setupUI() {
    // 셀 자체 설정
    contentView.layer.cornerRadius = 12
    contentView.clipsToBounds = true
    contentView.backgroundColor = .white
    contentView.layer.shadowColor = UIColor.black.cgColor
    contentView.layer.shadowOpacity = 0.1
    contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
    contentView.layer.shadowRadius = 4
    
    // 뷰 추가
    contentView.addSubview(imageView)
    contentView.addSubview(overlayView)
    contentView.addSubview(infoContainer)
    infoContainer.addSubview(dateLabel)
    infoContainer.addSubview(notesLabel)
    contentView.addSubview(favoriteButton)
    contentView.addSubview(shareButton)
    
    // 레이아웃 설정
    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    overlayView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    infoContainer.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(8)
      make.leading.equalToSuperview().offset(8)
      make.trailing.equalToSuperview().offset(-8)
    }
    
    dateLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(6)
      make.leading.equalToSuperview().offset(8)
      make.trailing.equalToSuperview().offset(-8)
    }
    
    notesLabel.snp.makeConstraints { make in
      make.top.equalTo(dateLabel.snp.bottom).offset(4)
      make.leading.equalToSuperview().offset(8)
      make.trailing.equalToSuperview().offset(-8)
      make.bottom.equalToSuperview().offset(-6)
    }
    
    favoriteButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-12)
      make.leading.equalToSuperview().offset(12)
      make.width.height.equalTo(32)
    }
    
    shareButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-12)
      make.trailing.equalToSuperview().offset(-12)
      make.width.height.equalTo(32)
    }
    
    // 버튼 액션 바인딩
    favoriteButton.rx.tap
      .bind(to: favoriteButtonTap)
      .disposed(by: disposeBag)
    
    shareButton.rx.tap
      .bind(to: shareButtonTap)
      .disposed(by: disposeBag)
  }
  
  // MARK: - Configuration
  func configure(with imageData: GalleryViewModel.ImageData, imageManager: ImageManager) {
    // 썸네일 이미지 로드
    if let image = imageManager.loadThumbnailImage(from: imageData.thumbnailPath) {
      imageView.image = image
    } else {
      // 기본 이미지 설정
      imageView.image = UIImage(systemName: "photo")
    }
    
    // 즐겨찾기 상태 반영
    updateFavoriteButton(isFavorite: imageData.isFavorite)
    
    // 날짜 포맷
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy.MM.dd"
    dateLabel.text = dateFormatter.string(from: imageData.createdAt)
    
    // 노트 텍스트 설정
    if let notes = imageData.notes, !notes.isEmpty {
      notesLabel.text = notes
      infoContainer.isHidden = false
    } else {
      notesLabel.text = "내용 없음"
      infoContainer.isHidden = false
    }
  }
  
  private func updateFavoriteButton(isFavorite: Bool) {
    let heartImageName = isFavorite ? "heart.fill" : "heart"
    favoriteButton.setImage(UIImage(systemName: heartImageName), for: .normal)
    
    // 즐겨찾기된 경우 버튼 색상 변경
    if isFavorite {
      favoriteButton.tintColor = UIColor.systemPink
    } else {
      favoriteButton.tintColor = .white
    }
  }
}
