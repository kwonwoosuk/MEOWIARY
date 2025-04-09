//
//  FeatureImageSelectViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/10/25.
//

// 대표 이미지 선택화면

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class FeatureImageSelectViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let year: Int
    private let month: Int
    private let imageRecords: [ImageRecord]
    private let imageManager = ImageManager.shared
    
    // 선택된 이미지 콜백
    var onImageSelected: ((UIImage?) -> Void)?
    
    // MARK: - UI Components
    private let navigationBarView = CustomNavigationBarView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.textAlignment = .center
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "아래 이미지 중 하나를 선택하면 대표 이미지로 설정됩니다."
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        let screenWidth = UIScreen.main.bounds.width
        let itemsPerRow: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 3
        let padding: CGFloat = DesignSystem.Layout.standardMargin * 2 + ((itemsPerRow - 1) * 10)
        let itemWidth = (screenWidth - padding) / itemsPerRow
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(ImageSelectCell.self, forCellWithReuseIdentifier: "ImageSelectCell")
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        return collectionView
    }()
    
    // MARK: - Initialization
    init(year: Int, month: Int, imageRecords: [ImageRecord]) {
        self.year = year
        self.month = month
        self.imageRecords = imageRecords
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func configureHierarchy() {
        view.addSubview(navigationBarView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(collectionView)
    }
    
    override func configureLayout() {
        navigationBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(navigationBarView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        
        // 네비게이션 바 설정
        navigationBarView.configure(title: "대표 이미지 선택", leftButtonType: .close)
        
        // 월 이름으로 타이틀 설정
        let monthNames = ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"]
        let monthName = monthNames[month - 1]
        titleLabel.text = "\(year)년 \(monthName) 대표 이미지 선택"
        
        // 컬렉션 뷰 설정
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func bind() {
        // 닫기 버튼 액션
        navigationBarView.leftButtonTapObservable
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDataSource
extension FeatureImageSelectViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageRecords.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageSelectCell", for: indexPath) as? ImageSelectCell else {
            return UICollectionViewCell()
        }
        
        let imageRecord = imageRecords[indexPath.item]
        
        // 썸네일 이미지 로드
        if let thumbnailPath = imageRecord.thumbnailImagePath,
           let thumbnail = imageManager.loadThumbnailImage(from: thumbnailPath) {
            cell.configure(with: thumbnail)
        } else {
            cell.configure(with: nil)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FeatureImageSelectViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageRecord = imageRecords[indexPath.item]
        
        // 원본 이미지 로드
        if let originalPath = imageRecord.originalImagePath,
           let originalImage = imageManager.loadOriginalImage(from: originalPath) {
            
            // 선택 완료 처리
            onImageSelected?(originalImage)
            dismiss(animated: true)
        } else {
            // 이미지 로드 실패
            let alert = UIAlertController(
                title: "이미지 로드 실패",
                message: "선택한 이미지를 불러올 수 없습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - ImageSelectCell
class ImageSelectCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
        return imageView
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 그림자 효과
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.masksToBounds = false
    }
    
    // MARK: - Configuration
    func configure(with image: UIImage?) {
        imageView.image = image ?? UIImage(systemName: "photo")
        
        if image == nil {
            imageView.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
