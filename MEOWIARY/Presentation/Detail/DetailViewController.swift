//
//  DetailViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//


import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class DetailViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let imageData: GalleryViewModel.ImageData
    private let imageManager: ImageManager
  private let imageRecordRepository = ImageRecordRepository()
    // MARK: - UI Components
    private let navigationBarView = CustomNavigationBarView()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        return label
    }()
    
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.main.inUIColor()
        return button
    }()
    
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.action.inUIColor()
        return button
    }()
    
    // MARK: - Initialization
    init(imageData: GalleryViewModel.ImageData, imageManager: ImageManager) {
        self.imageData = imageData
        self.imageManager = imageManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
      
    }
    
    // MARK: - UI Setup
    override func configureHierarchy() {
        view.addSubview(navigationBarView)
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(dateLabel)
        view.addSubview(favoriteButton)
        view.addSubview(shareButton)
    }
    
    override func configureLayout() {
        navigationBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationBarView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(dateLabel.snp.top).offset(-DesignSystem.Layout.standardMargin)
        }
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
            make.height.equalTo(scrollView.snp.height)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-DesignSystem.Layout.standardMargin)
        }
        
        favoriteButton.snp.makeConstraints { make in
            make.trailing.equalTo(shareButton.snp.leading).offset(-DesignSystem.Layout.standardMargin)
            make.centerY.equalTo(dateLabel)
            make.width.height.equalTo(30)
        }
        
        shareButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.centerY.equalTo(dateLabel)
            make.width.height.equalTo(30)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        
        // 네비게이션 바 설정
        navigationBarView.configure(title: "사진 상세", leftButtonType: .back)
        
        // 스크롤 뷰 델리게이트 설정
        scrollView.delegate = self
        
        // 이미지 로드
        if let image = imageManager.loadOriginalImage(from: imageData.originalPath) {
            imageView.image = image
        }
        
        // 날짜 포맷
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        dateLabel.text = dateFormatter.string(from: imageData.createdAt)
        
    }
    
    // MARK: - Binding
    override func bind() {
        // 네비게이션 바 닫기 버튼
        navigationBarView.leftButtonTapObservable
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // 즐겨찾기 버튼 액션
      imageRecordRepository.toggleFavorite(imageId: self.imageData.id)
          .subscribe()
          .disposed(by: disposeBag)
        
        // 공유 버튼 액션
        shareButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self, let image = self.imageView.image else { return }
                
                let activityViewController = UIActivityViewController(
                    activityItems: [image],
                    applicationActivities: nil
                )
                
                // iPad 호환성
                if let popoverController = activityViewController.popoverPresentationController {
                    popoverController.sourceView = self.shareButton
                    popoverController.sourceRect = self.shareButton.bounds
                }
                
                self.present(activityViewController, animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UIScrollViewDelegate
extension DetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 줌 시 이미지 중앙 정렬
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
