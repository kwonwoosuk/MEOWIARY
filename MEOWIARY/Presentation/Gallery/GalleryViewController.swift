//
//  GalleryViewController.swift
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
  private var cachedHeights: [String: CGFloat] = [:]
  
  // MARK: - UI Components
  private let navigationBarView = CustomNavigationBarView()
  
  private lazy var collectionView: UICollectionView = {
    let layout = createLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .white
    collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")
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
  
  // 필터 상태 (즐겨찾기만 표시할지 여부)
  private let isFavoritesOnlyRelay = BehaviorRelay<Bool>(value: false)
  
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
      make.top.equalToSuperview()
      make.centerX.equalToSuperview()
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
    let heartImage = UIImage(systemName: "heart")
    let searchImage = UIImage(systemName: "magnifyingglass")
    navigationBarView.configure(
      title: "사진 모아보기",
      leftButtonType: .custom(image: heartImage!),
      rightButtonImage: searchImage
    )
    
    collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")
  }
  
  // MARK: - Binding
  override func bind() {
    let input = GalleryViewModel.Input(
      viewDidLoad: Observable.just(()),
      toggleFavoriteFilter: isFavoritesOnlyRelay.asObservable(),
      searchQuery: Observable.just("") // 기본 검색어는 빈 문자열
    )
    
    let output = viewModel.transform(input: input)
    
    // 이미지 데이터 바인딩
    output.images
      .drive(collectionView.rx.items(cellIdentifier: "GalleryCell", cellType: GalleryCell.self)) { [weak self] (index, imageData, cell) in
        guard let self = self else { return }
        cell.configure(with: imageData, imageManager: self.viewModel.imageManager)
        
        // 이미지 ID를 키로 사용하여 높이 값을 캐시
        if let notes = imageData.notes, !notes.isEmpty {
          self.estimateTextHeight(for: notes, width: self.view.bounds.width - 32) // 좌우 패딩 고려
          self.cachedHeights[imageData.id] = self.estimateNotesHeight(notes)
        }
        
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
    
    // 이미지 데이터가 변경될 때 레이아웃 업데이트
    output.images
      .drive(onNext: { [weak self] _ in
        self?.updateCollectionViewLayout()
      })
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
    
    // 네비게이션 바 좌측(하트) 버튼 - 즐겨찾기 필터링
    navigationBarView.leftButtonTapObservable
      .subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        let newValue = !self.isFavoritesOnlyRelay.value
        self.isFavoritesOnlyRelay.accept(newValue)
        
        // 버튼 UI 업데이트
        let heartImage = UIImage(systemName: newValue ? "heart.fill" : "heart")
        self.navigationBarView.updateLeftButton(image: heartImage)
        
        // 필터링 상태에 따라 레이블 변경
        if newValue {
          self.emptyLabel.text = "즐겨찾기한 사진이 없습니다."
        } else {
          self.emptyLabel.text = "아직 저장된 사진이 없습니다."
        }
      })
      .disposed(by: disposeBag)
    
    // 네비게이션 바 우측(검색) 버튼
    navigationBarView.rightButtonTapObservable
      .subscribe(onNext: { [weak self] in
        self?.showSearchDialog()
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Helper Methods
  private func createLayout() -> UICollectionViewLayout {
    let layout = UICollectionViewCompositionalLayout { [weak self] (section, layoutEnvironment) -> NSCollectionLayoutSection? in
      guard let self = self else { return nil }
      
      // 1열 레이아웃으로 변경 - 전체 화면 너비 사용
      let itemFractionalWidth: CGFloat = 1.0
      let fractionalWidth = NSCollectionLayoutDimension.fractionalWidth(itemFractionalWidth)
      
      // 아이템 크기 - 높이는 예상 높이에 따라 달라짐
      let itemSize = NSCollectionLayoutSize(
        widthDimension: fractionalWidth,
        heightDimension: .estimated(250) // 초기 높이는 추정값으로 설정
      )
      
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
      
      // 그룹 설정 - 가로로 1개 아이템만 배치
      let groupSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(250) // 동적 높이 지원
      )
      
      let group = NSCollectionLayoutGroup.horizontal(
        layoutSize: groupSize,
        subitems: [item]
      )
      
      // 섹션 설정
      let section = NSCollectionLayoutSection(group: group)
      section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
      
      return section
    }
    
    return layout
  }
  
  private func updateCollectionViewLayout() {
    // 컬렉션 뷰 레이아웃 갱신
    DispatchQueue.main.async { [weak self] in
      self?.collectionView.collectionViewLayout.invalidateLayout()
    }
  }
  
  private func estimateTextHeight(for text: String, width: CGFloat) -> CGFloat {
    let label = UILabel()
    label.text = text
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
    label.numberOfLines = 6
    
    let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
    let boundingBox = text.boundingRect(
      with: constraintRect,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [NSAttributedString.Key.font: label.font!],
      context: nil
    )
    
    return ceil(boundingBox.height)
  }
  
  private func estimateNotesHeight(_ notes: String) -> CGFloat {
    let baseHeight: CGFloat = 150 // 기본 높이 (이미지, 날짜, 버튼 등의 공간)
    
    // 텍스트 높이 계산 (최대 6줄로 제한)
    let textWidth = view.bounds.width - 32 // 화면 너비에서 좌우 패딩 제외
    let textHeight = estimateTextHeight(for: notes, width: textWidth)
    
    // 텍스트 높이에 따라 셀 높이 조정 (최대 6줄까지)
    let maxTextHeight: CGFloat = 120 // 약 6줄 정도의 높이
    let adjustedTextHeight = min(textHeight, maxTextHeight)
    
    return baseHeight + adjustedTextHeight
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
  
  // 검색 다이얼로그 표시
  private func showSearchDialog() {
    let alertController = UIAlertController(
      title: "사진 검색",
      message: "검색어를 입력하세요",
      preferredStyle: .alert
    )
    
    alertController.addTextField { textField in
      textField.placeholder = "제목, 날짜, 메모 등으로 검색"
      textField.returnKeyType = .search
    }
    
    let searchAction = UIAlertAction(title: "검색", style: .default) { [weak self, weak alertController] _ in
      guard let query = alertController?.textFields?.first?.text, !query.isEmpty else {
        return
      }
      
      self?.viewModel.searchImages(query: query)
      // 필터링 UI 업데이트 - 필터링 중임을 표시
      self?.navigationBarView.setTitle("검색 결과: \(query)")
    }
    
    let cancelAction = UIAlertAction(title: "취소", style: .cancel)
    
    alertController.addAction(searchAction)
    alertController.addAction(cancelAction)
    
    present(alertController, animated: true)
  }
}
