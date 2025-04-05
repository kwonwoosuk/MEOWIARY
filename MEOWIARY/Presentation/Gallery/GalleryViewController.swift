//
//  ImageGalleryViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//


import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class GalleryViewController: BaseViewController {
  
  // MARK: - Properties
  private let viewModel = GalleryViewModel()
  private let disposeBag = DisposeBag()
  
  // MARK: - UI Components
  private let navigationBarView = CustomNavigationBarView()
  
  private lazy var collectionView: UICollectionView = {
    let layout = createLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .white
    collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "ImageGalleryCell")
    return collectionView
  }()
  
  private let emptyView: UIView = {
    let view = UIView()
    view.isHidden = true
    return view
  }()
  
  private let emptyImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "photo")
    imageView.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  private let emptyLabel: UILabel = {
    let label = UILabel()
    label.text = "아직 저장된 사진이 없습니다."
    label.textAlignment = .center
    label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    return label
  }()
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      viewModel.refreshData()
  }
  
  // MARK: - UI Setup
  override func configureHierarchy() {
    view.addSubview(navigationBarView)
    view.addSubview(collectionView)
    view.addSubview(emptyView)
    emptyView.addSubview(emptyImageView)
    emptyView.addSubview(emptyLabel)
  }
  
  override func configureLayout() {
    navigationBarView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(50)
    }
    
    collectionView.snp.makeConstraints { make in
      make.top.equalTo(navigationBarView.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }
    
    emptyView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.equalTo(200)
      make.height.equalTo(150)
    }
    
    emptyImageView.snp.makeConstraints { make in
      make.top.centerX.equalToSuperview()
      make.width.height.equalTo(60)
    }
    
    emptyLabel.snp.makeConstraints { make in
      make.top.equalTo(emptyImageView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
      make.leading.trailing.equalToSuperview()
      make.centerX.equalToSuperview()
    }
  }
  
  override func configureView() {
    view.backgroundColor = .white
    
    // 네비게이션 바 설정
    navigationBarView.configure(title: "사진 모아보기", leftButtonType: .none)
    collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")
  }
  
  // MARK: - Binding
  override func bind() {
    let input = GalleryViewModel.Input(
      viewDidLoad: Observable.just(())
    )
    
    let output = viewModel.transform(input: input)
    
    // 이미지 데이터 바인딩
    output.images
          .do(onNext: { images in
            print("화면에 표시할 이미지 수: \(images.count)")
          })
          .drive(collectionView.rx.items(cellIdentifier: "GalleryCell", cellType: GalleryCell.self)) { [weak self] (index, imageData, cell) in
            guard let self = self else { return }
            print("셀 구성: \(index), ID: \(imageData.id)")
            cell.configure(with: imageData, imageManager: self.viewModel.imageManager)
            
            // 즐겨찾기 버튼 액션
            cell.favoriteButtonTap
              .subscribe(onNext: { [weak self] in
                self?.viewModel.toggleFavorite(imageId: imageData.id)
              })
              .disposed(by: cell.disposeBag)
            
            // 공유 버튼 액션
            cell.shareButtonTap
              .subscribe(onNext: { [weak self] in
                self?.shareImage(imageData: imageData)
              })
              .disposed(by: cell.disposeBag)
          }
          .disposed(by: disposeBag)
    // 빈 상태 표시
    output.isEmpty
      .drive(emptyView.rx.isHidden.mapObserver { !$0 })
      .disposed(by: disposeBag)
    
    // 셀 선택 시 상세 보기
    collectionView.rx.modelSelected(GalleryViewModel.ImageData.self)
      .subscribe(onNext: { [weak self] imageData in
        self?.showImageDetail(imageData: imageData)
      })
      .disposed(by: disposeBag)
    
    // 네비게이션 바 뒤로가기 버튼
    navigationBarView.leftButtonTapObservable
      .subscribe(onNext: { [weak self] in
        self?.dismiss(animated: true)
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Helper Methods
  private func createLayout() -> UICollectionViewLayout {
    let layout = UICollectionViewCompositionalLayout { (sectionIndex, _) -> NSCollectionLayoutSection? in
      // Item 크기 (기본 정사각형)
      let itemSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .fractionalHeight(1.0)
      )
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
      
      // 다양한 그룹 패턴 생성 (Pinterest 스타일)
      let groupHeight: NSCollectionLayoutDimension
      let groupWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
      
      let pattern = sectionIndex % 3
      if pattern == 0 {
        // 2개 열 패턴
        let groupSize = NSCollectionLayoutSize(
          widthDimension: groupWidth,
          heightDimension: .fractionalWidth(0.5)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
          layoutSize: groupSize,
          subitem: item,
          count: 2
        )
        
        let section = NSCollectionLayoutSection(group: group)
        return section
        
      } else if pattern == 1 {
        // 3개 열 패턴
        let groupSize = NSCollectionLayoutSize(
          widthDimension: groupWidth,
          heightDimension: .fractionalWidth(0.33)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
          layoutSize: groupSize,
          subitem: item,
          count: 3
        )
        
        let section = NSCollectionLayoutSection(group: group)
        return section
        
      } else {
        // 혼합 패턴: 큰 이미지 하나 + 작은 이미지 2개
        // 큰 이미지
        let bigItemSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(2/3),
          heightDimension: .fractionalHeight(1.0)
        )
        let bigItem = NSCollectionLayoutItem(layoutSize: bigItemSize)
        bigItem.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        // 작은 이미지 2개 수직 배치
        let smallItemSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .fractionalHeight(0.5)
        )
        let smallItem = NSCollectionLayoutItem(layoutSize: smallItemSize)
        smallItem.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        let verticalGroupSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1/3),
          heightDimension: .fractionalHeight(1.0)
        )
        let verticalGroup = NSCollectionLayoutGroup.vertical(
          layoutSize: verticalGroupSize,
          subitem: smallItem,
          count: 2
        )
        
        // 전체 그룹: 큰 이미지 + 수직 그룹
        let groupSize = NSCollectionLayoutSize(
          widthDimension: groupWidth,
          heightDimension: .fractionalWidth(0.5)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
          layoutSize: groupSize,
          subitems: [bigItem, verticalGroup]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        return section
      }
    }
    
    return layout
  }
  
  private func shareImage(imageData: GalleryViewModel.ImageData) {
    guard let image = viewModel.imageManager.loadOriginalImage(from: imageData.originalPath) else { return }
    
    let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
    
    // iPad 호환성
    if let popoverController = activityViewController.popoverPresentationController {
      popoverController.sourceView = self.view
      popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }
    
    present(activityViewController, animated: true)
  }
  
  private func showImageDetail(imageData: GalleryViewModel.ImageData) {
    let detailVC = DetailViewController(imageData: imageData, imageManager: viewModel.imageManager)
    detailVC.modalPresentationStyle = .fullScreen
    present(detailVC, animated: true)
  }
}
