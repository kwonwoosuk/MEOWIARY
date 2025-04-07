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
  private let viewModel: DetailViewModel
  private var loadedImages: [UIImage?] = [] // 로드된 이미지를 저장
  var onDelete: (() -> Void)?
  
  // MARK: - UI Components
  private let navigationBarView = CustomNavigationBarView()
  
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.isPagingEnabled = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.backgroundColor = .white
    return collectionView
  }()
  
  private let pageControl: UIPageControl = {
    let pageControl = UIPageControl()
    pageControl.currentPageIndicatorTintColor = .white
    pageControl.pageIndicatorTintColor = .white.withAlphaComponent(0.5)
    return pageControl
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
  
  private let deleteButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "trash"), for: .normal)
    button.tintColor = .systemRed
    return button
  }()
  
  private let notesLabel: UILabel = {
    let label = UILabel()
    label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    label.numberOfLines = 0
    label.isHidden = true
    return label
  }()
  
  private let loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.color = .gray
    indicator.hidesWhenStopped = true
    return indicator
  }()
  
  // MARK: - Initialization
  init(year: Int, month: Int, day: Int, imageManager: ImageManager) {
    self.viewModel = DetailViewModel(year: year, month: month, day: day, imageManager: imageManager)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.register(DetailCell.self, forCellWithReuseIdentifier: "DetailCell")
    collectionView.delegate = self
    collectionView.dataSource = self
  }
  
  // MARK: - UI Setup
  override func configureHierarchy() {
    view.addSubview(navigationBarView)
    view.addSubview(collectionView)
    view.addSubview(pageControl)
    view.addSubview(dateLabel)
    view.addSubview(favoriteButton)
    view.addSubview(shareButton)
    view.addSubview(deleteButton)
    view.addSubview(notesLabel)
    view.addSubview(loadingIndicator)
  }
  
  override func configureLayout() {
    navigationBarView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(50)
    }
    
    collectionView.snp.makeConstraints { make in
      make.top.equalTo(navigationBarView.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(view.snp.width) // 정사각형 비율 유지
    }
    
    pageControl.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(collectionView.snp.bottom).offset(8)
    }
    
    notesLabel.snp.makeConstraints { make in
      make.top.equalTo(pageControl.snp.bottom).offset(DesignSystem.Layout.standardMargin)
      make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
      make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
    }
    
    dateLabel.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-DesignSystem.Layout.standardMargin)
    }
    
    deleteButton.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
      make.centerY.equalTo(dateLabel)
      make.width.height.equalTo(30)
    }
    
    shareButton.snp.makeConstraints { make in
      make.trailing.equalTo(deleteButton.snp.leading).offset(-DesignSystem.Layout.standardMargin)
      make.centerY.equalTo(dateLabel)
      make.width.height.equalTo(30)
    }
    
    favoriteButton.snp.makeConstraints { make in
      make.trailing.equalTo(shareButton.snp.leading).offset(-DesignSystem.Layout.standardMargin)
      make.centerY.equalTo(dateLabel)
      make.width.height.equalTo(30)
    }
    
    loadingIndicator.snp.makeConstraints { make in
      make.center.equalTo(collectionView)
    }
  }
  
  override func configureView() {
    view.backgroundColor = .white
    navigationBarView.configure(title: "사진 상세", leftButtonType: .back)
  }
  
  // MARK: - Binding
    // DetailViewController.swift의 바인딩 메서드 수정

    override func bind() {
        let input = DetailViewModel.Input(
          viewDidLoad: Observable.just(()),
          favoriteButtonTap: favoriteButton.rx.tap.asObservable(),
          shareButtonTap: shareButton.rx.tap.asObservable(),
          deleteButtonTap: deleteButton.rx.tap.asObservable(),
          currentIndex: collectionView.rx.didEndDecelerating
            .map { [weak self] _ -> Int in
              guard let self = self else { return 0 }
              let offsetX = self.collectionView.contentOffset.x
              let width = self.collectionView.frame.width
              return Int(round(offsetX / width))
            }
            .startWith(0)
        )
        
        let output = viewModel.transform(input: input)
        
        // 이미지 데이터 바인딩
        output.imageRecords
          .drive(onNext: { [weak self] imageRecords in
            guard let self = self else { return }
            // 로딩 시작 전 UI 업데이트
            DispatchQueue.main.async {
              self.loadedImages = [] // 초기화
              self.collectionView.reloadData() // 데이터 초기화
              self.pageControl.numberOfPages = imageRecords.count
              self.pageControl.currentPage = 0
              self.pageControl.isHidden = imageRecords.isEmpty
              self.collectionView.isHidden = true
              self.loadingIndicator.startAnimating()
            }
            
            // Task를 사용하여 모든 이미지를 비동기적으로 로드
            Task {
              var images: [UIImage?] = []
              for imageRecord in imageRecords {
                print("이미지 경로: \(String(describing: imageRecord.originalImagePath))")
                let image = await self.viewModel.imageManager.loadOriginalImageAsync(from: imageRecord.originalImagePath)
                if image == nil {
                  print("이미지 로드 실패: \(String(describing: imageRecord.originalImagePath))")
                }
                images.append(image)
              }
              
              // 메인 스레드에서 UI 업데이트
              await MainActor.run {
                self.loadedImages = images
                self.collectionView.reloadData()
                self.collectionView.isHidden = false
                self.loadingIndicator.stopAnimating()
                
                // 이미지가 없는 경우 알림 표시
                if images.allSatisfy({ $0 == nil }) && !images.isEmpty {
                  let alert = UIAlertController(title: "오류", message: "이미지를 로드할 수 없습니다.", preferredStyle: .alert)
                  alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                  self.present(alert, animated: true)
                }
              }
            }
          })
          .disposed(by: disposeBag)
        
        // 페이지 컨트롤 업데이트
        collectionView.rx.contentOffset
          .map { [weak self] offset -> Int in
            guard let self = self, self.collectionView.frame.width > 0 else { return 0 }
            return Int(round(offset.x / self.collectionView.frame.width))
          }
          .bind(to: pageControl.rx.currentPage)
          .disposed(by: disposeBag)
        
        // 날짜 바인딩
        output.dateText
          .drive(dateLabel.rx.text)
          .disposed(by: disposeBag)
        
        // 즐겨찾기 상태 바인딩
        output.isFavorite
          .drive(onNext: { [weak self] isFavorite in
            self?.updateFavoriteButtonUI(isFavorite: isFavorite)
          })
          .disposed(by: disposeBag)
        
        // 노트 텍스트 바인딩
        output.notesText
          .drive(onNext: { [weak self] notes in
            if let notes = notes, !notes.isEmpty {
              self?.notesLabel.text = notes
              self?.notesLabel.isHidden = false
            } else {
              self?.notesLabel.isHidden = true
            }
          })
          .disposed(by: disposeBag)
        
        // 뒤로가기 버튼
        navigationBarView.leftButtonTapObservable
          .subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true)
          })
          .disposed(by: disposeBag)
        
        // 삭제 성공 후 닫기
        output.deleteSuccess
          .drive(onNext: { [weak self] in
            // 삭제 성공 시 알림 발송
            NotificationCenter.default.post(
              name: Notification.Name(DayCardDeletedNotification),
              object: nil,
              userInfo: ["year": self?.viewModel.year ?? 0,
                         "month": self?.viewModel.month ?? 0,
                         "day": self?.viewModel.day ?? 0]
            )
            
            // 콜백 호출 및 화면 닫기
            self?.onDelete?()
            self?.dismiss(animated: true)
          })
          .disposed(by: disposeBag)
        
        
        // 공유 버튼 액션 - 문법 수정
        shareButton.rx.tap
          .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
            let currentPage = self.pageControl.currentPage
            if currentPage < self.loadedImages.count,
               let image = self.loadedImages[currentPage] {
              // 공유 시트 표시
              let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
              
              // iPad 지원
              if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = self.shareButton
                popoverController.sourceRect = self.shareButton.bounds
              }
              
              self.present(activityVC, animated: true)
            } else {
              self.showToast(message: "공유할 이미지를 불러올 수 없습니다")
            }
          })
          .disposed(by: disposeBag)
        // 삭제 버튼 탭 - Alert 표시 및 확인 후 ViewModel의 로직 실행
        deleteButton.rx.tap
          .subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(
              title: "삭제 확인",
              message: "이 날짜의 모든 데이터를 삭제하시겠습니까?",
              preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
              guard let self = self else { return }
              
              // 로딩 표시 시작
              self.loadingIndicator.startAnimating()
              
              // ViewModel의 삭제 로직 실행
              output.deleteConfirmed.onNext(())
            })
            
            self.present(alert, animated: true)
          })
          .disposed(by: disposeBag)
      }
  
  private func updateFavoriteButtonUI(isFavorite: Bool) {
    let imageName = isFavorite ? "heart.fill" : "heart"
    favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
    favoriteButton.tintColor = isFavorite ? UIColor.systemPink : DesignSystem.Color.Tint.main.inUIColor()
  }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension DetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return loadedImages.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DetailCell", for: indexPath) as! DetailCell
    let image = loadedImages[indexPath.row]
    if let image = image {
      cell.imageView.image = image
    } else {
      cell.imageView.image = UIImage(systemName: "photo")
      cell.imageView.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    }
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: view.frame.width, height: collectionView.frame.height)
  }
}


