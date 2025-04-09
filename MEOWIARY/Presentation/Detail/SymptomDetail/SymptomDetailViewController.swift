//
//  SymptomDetailViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/7/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class SymptomDetailViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewModel: SymptomDetailViewModel
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
    
    private let symptomNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
        label.textAlignment = .center
        return label
    }()
    
    private let severityIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let severityLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.small)
        label.textAlignment = .center
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
        self.viewModel = SymptomDetailViewModel(year: year, month: month, day: day, imageManager: imageManager)
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
        view.addSubview(symptomNameLabel)
        view.addSubview(severityIndicator)
        severityIndicator.addSubview(severityLabel)
        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(dateLabel)
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
        
        symptomNameLabel.snp.makeConstraints { make in
            make.top.equalTo(navigationBarView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
            make.height.equalTo(30)
        }
        
        severityIndicator.snp.makeConstraints { make in
            make.top.equalTo(symptomNameLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(24)
        }
        
        severityLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(severityIndicator.snp.bottom).offset(16)
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
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(collectionView)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        navigationBarView.configure(title: "증상 상세", leftButtonType: .back)
    }
    
    // MARK: - Binding
    override func bind() {
        let input = SymptomDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            deleteButtonTap: deleteButton.rx.tap.asObservable(),
            shareButtonTap: shareButton.rx.tap.asObservable(),
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
        
        // 증상 데이터 바인딩
        output.symptoms
            .drive(onNext: { [weak self] symptoms in
                guard let self = self else { return }
                
                if let firstSymptom = symptoms.first {
                    self.symptomNameLabel.text = firstSymptom.name
                    self.updateSeverityIndicator(severity: firstSymptom.severity)
                    
                    // 증상 노트가 있으면 표시
                    if let notes = firstSymptom.notes, !notes.isEmpty {
                        self.notesLabel.text = notes
                        self.notesLabel.isHidden = false
                    } else {
                        self.notesLabel.isHidden = true
                    }
                } else {
                    self.symptomNameLabel.text = "증상 없음"
                    self.updateSeverityIndicator(severity: 0)
                    self.notesLabel.isHidden = true
                }
            })
            .disposed(by: disposeBag)
        
        // 이미지 데이터 바인딩 - 이제 증상에 연결된 SymptomImage들에서 가져옴
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
                        let image = await self.viewModel.imageManager.loadOriginalImageAsync(from: imageRecord.originalImagePath)
                        images.append(image)
                    }
                    
                    // 메인 스레드에서 UI 업데이트
                    await MainActor.run {
                        self.loadedImages = images
                        self.collectionView.reloadData()
                        self.collectionView.isHidden = false
                        self.loadingIndicator.stopAnimating()
                        
                        // 이미지가 없는 경우 처리
                        if images.isEmpty {
                            self.pageControl.isHidden = true
                        } else if images.allSatisfy({ $0 == nil }) && !images.isEmpty {
                            self.showToast(message: "이미지를 로드할 수 없습니다")
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
        
        // 현재 증상 바인딩 (스크롤 이동 시 업데이트)
        output.currentSymptom
            .drive(onNext: { [weak self] symptom in
                if let symptom = symptom {
                    self?.symptomNameLabel.text = symptom.name
                    self?.updateSeverityIndicator(severity: symptom.severity)
                    
                    // 증상 노트 업데이트
                    if let notes = symptom.notes, !notes.isEmpty {
                        self?.notesLabel.text = notes
                        self?.notesLabel.isHidden = false
                    } else {
                        self?.notesLabel.isHidden = true
                    }
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
            .drive(onNext: { [weak self] imagePaths in
                guard let self = self else { return }
                
                // 이미지 캐시 비우기
                for (originalPath, thumbnailPath) in imagePaths {
                    if let path = originalPath {
                        ImageManager.shared.clearImageCache(for: path)
                    }
                    if let path = thumbnailPath {
                        ImageManager.shared.clearImageCache(for: path)
                    }
                }
                
                // 삭제 성공 시 알림 발송
                NotificationCenter.default.post(
                    name: Notification.Name(DayCardDeletedNotification),
                    object: nil,
                    userInfo: [
                        "year": self.viewModel.year,
                        "month": self.viewModel.month,
                        "day": self.viewModel.day,
                        "forceReload": true,
                        "isSymptom": true
                    ]
                )
                
                // 토스트 메시지 표시
                self.showToast(message: "삭제가 완료되었습니다")
                
                // 콜백 호출 및 화면 닫기
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.onDelete?()
                    self.dismiss(animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        // 공유 버튼 액션
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
                    message: "이 증상 기록을 삭제하시겠습니까?",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                
                alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // 삭제 전에 필요한 이미지 경로 정보 먼저 복사
                    let imagePaths = self.viewModel.preparePathsForDeletion()
                    
                    // 로딩 표시 시작
                    self.loadingIndicator.startAnimating()
                    
                    // 삭제 로직 실행
                    output.deleteConfirmed.onNext(())
                })
                
                self.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateSeverityIndicator(severity: Int) {
        switch severity {
        case 1:
            severityIndicator.backgroundColor = DesignSystem.Color.Status.negative1.inUIColor()
            severityLabel.text = "일상적인 증상"
        case 2:
            severityIndicator.backgroundColor = DesignSystem.Color.Status.negative2.inUIColor()
            severityLabel.text = "가벼운 증상"
        case 3:
            severityIndicator.backgroundColor = DesignSystem.Color.Status.negative3.inUIColor()
            severityLabel.text = "중증 증상"
        case 4:
            severityIndicator.backgroundColor = DesignSystem.Color.Status.negative4.inUIColor()
            severityLabel.text = "심한 증상"
        case 5:
            severityIndicator.backgroundColor = DesignSystem.Color.Status.negative5.inUIColor()
            severityLabel.text = "응급 고위험"
        default:
            severityIndicator.backgroundColor = UIColor.lightGray
            severityLabel.text = "없음"
        }
    }
    
    
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension SymptomDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
