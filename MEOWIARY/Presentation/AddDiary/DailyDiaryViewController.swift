//
//  DailyDiaryViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import PhotosUI

final class DailyDiaryViewController: BaseViewController {
  
  // MARK: - Properties
  private let viewModel = DailyDiaryViewModel()
  private let disposeBag = DisposeBag()
  private var selectedImages: [UIImage] = [] {
    didSet {
      updateImageViews()
    }
  }
  private let selectedImagesRelay = BehaviorRelay<[UIImage]>(value: [])
  
  // MARK: - UI Components
  private let navigationBarView = CustomNavigationBarView()
  
  private let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.showsVerticalScrollIndicator = false
    scrollView.contentInsetAdjustmentBehavior = .never
    return scrollView
  }()
  
  private let contentView = UIView()
  
  private let dateLabel: UILabel = {
    let label = UILabel()
    label.textColor = DesignSystem.Color.Tint.text.inUIColor()
    label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
    
    // 오늘 날짜 표시
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy년 M월 d일"
    dateFormatter.locale = Locale(identifier: "ko_KR")
    label.text = dateFormatter.string(from: Date())
    
    return label
  }()
  
  private let dayOfWeekLabel: UILabel = {
    let label = UILabel()
    label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    
    // 요일 표시
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE"
    dateFormatter.locale = Locale(identifier: "ko_KR")
    label.text = dateFormatter.string(from: Date())
    
    return label
  }()
  
  // 단일 이미지 선택 관련
  private let photoButton: UIButton = {
    let button = UIButton(type: .system)
    button.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
    button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    
    // 카메라 아이콘 설정
    let cameraImage = UIImage(systemName: "camera")
    button.setImage(cameraImage, for: .normal)
    button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
    button.setTitle("사진을 추가 하려면 클릭하세요!", for: .normal)
    
    return button
  }()
  
  private let photoImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
    imageView.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    imageView.isHidden = true
    return imageView
  }()
  
  private let removePhotoButton: UIButton = {
    let button = UIButton(type: .system)
    button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
    button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    button.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    button.layer.cornerRadius = 15
    button.isHidden = true
    return button
  }()
  
  // 이미지 옵션 관련
  private let photoButtonsStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.spacing = 10
    stackView.distribution = .fillEqually
    stackView.isHidden = true
    return stackView
  }()
  
  private let cameraButton: UIButton = {
    let button = UIButton(type: .system)
    button.backgroundColor = DesignSystem.Color.Tint.action.inUIColor()
    button.setTitle("카메라", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    return button
  }()

  // 다중 이미지 선택 관련
  private let multiplePhotosButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "photo.stack"), for: .normal)
    button.setTitle("사진선택", for: .normal)
    button.tintColor = DesignSystem.Color.Background.main.inUIColor()
    button.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
    button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    return button
  }()
  
  private let imagesCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 10
    layout.itemSize = CGSize(width: 100, height: 100)
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.isHidden = true
    return collectionView
  }()
  
  // 미디어 생성 버튼
  private let createMediaButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("GIF/동영상 생성", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
    button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    button.isHidden = true
    return button
  }()
  
  // 텍스트 입력
  private let inputTextView: UITextView = {
    let textView = UITextView()
    textView.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    textView.textColor = DesignSystem.Color.Tint.text.inUIColor()
    textView.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
    textView.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
    return textView
  }()
  
  private let placeholderLabel: UILabel = {
    let label = UILabel()
    label.text = "오늘 하루 반려묘와 있었던 일을 기록해보세요..."
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    label.numberOfLines = 1
    return label
  }()
  
  // 저장 관련
  private let saveButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("저장하기", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
    button.backgroundColor = DesignSystem.Color.Tint.action.inUIColor()
    button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    return button
  }()
  
  private let loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    indicator.color = .white
    return indicator
  }()
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  private func updateImageViews() {
    if selectedImages.count > 1 {
      // 여러 이미지가 선택된 경우
      photoImageView.isHidden = true
      photoButton.isHidden = true
      removePhotoButton.isHidden = true
      photoButtonsStackView.isHidden = true
      
      // 선택된 이미지들을 표시하는 컬렉션뷰 표시
      imagesCollectionView.isHidden = false
      imagesCollectionView.reloadData()
      createMediaButton.isHidden = false
      
      // 레이아웃 조정
      imagesCollectionView.snp.remakeConstraints { make in
        make.top.equalTo(dayOfWeekLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
        make.leading.trailing.equalTo(dateLabel)
        make.height.equalTo(120)
      }
      
      createMediaButton.snp.remakeConstraints { make in
        make.top.equalTo(imagesCollectionView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
        make.leading.trailing.equalTo(dateLabel)
        make.height.equalTo(44)
      }
      
    
      photoButtonsStackView.snp.remakeConstraints { make in
        make.top.equalTo(createMediaButton.snp.bottom).offset(DesignSystem.Layout.smallMargin)
        make.leading.trailing.equalTo(dateLabel)
        make.height.equalTo(50)
      }
      
      inputTextView.snp.remakeConstraints { make in
        make.top.equalTo(photoButtonsStackView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
        make.leading.trailing.equalTo(dateLabel)
        make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
        make.height.greaterThanOrEqualTo(150)
      }
    } else if selectedImages.count == 1 {
      // 단일 이미지가 선택된 경우
      photoImageView.isHidden = false
      photoImageView.image = selectedImages.first
      photoButton.isHidden = true
      removePhotoButton.isHidden = false
      
      imagesCollectionView.isHidden = true
      createMediaButton.isHidden = true
      
      // 원래 레이아웃으로 복원
      restoreOriginalLayout()
    } else {
      // 이미지가 선택되지 않은 경우
      photoImageView.isHidden = true
      photoButton.isHidden = false
      removePhotoButton.isHidden = true
      
      imagesCollectionView.isHidden = true
      createMediaButton.isHidden = true
      
      // 원래 레이아웃으로 복원
      restoreOriginalLayout()
    }
    
    view.layoutIfNeeded()
  }
  
  // 원래 레이아웃을 복원하는 메서드 추가
  private func restoreOriginalLayout() {
    
    // 기존 레이아웃 복원
    photoButtonsStackView.snp.remakeConstraints { make in
      make.top.equalTo(photoButton.snp.bottom).offset(DesignSystem.Layout.smallMargin)
      make.leading.trailing.equalTo(dateLabel)
      make.height.equalTo(50)
    }
    
    inputTextView.snp.remakeConstraints { make in
      make.top.equalTo(photoButtonsStackView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
      make.leading.trailing.equalTo(dateLabel)
      make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
      make.height.greaterThanOrEqualTo(150)
    }
  }
  // MARK: - UI Setup
  override func configureHierarchy() {
    view.addSubview(navigationBarView)
    view.addSubview(scrollView)
    view.addSubview(saveButton)
    
    scrollView.addSubview(contentView)
    
    contentView.addSubview(dateLabel)
    contentView.addSubview(dayOfWeekLabel)
    contentView.addSubview(photoButton)
    contentView.addSubview(photoImageView)
    contentView.addSubview(removePhotoButton)
    contentView.addSubview(photoButtonsStackView)
    contentView.addSubview(imagesCollectionView)
    contentView.addSubview(createMediaButton)
    contentView.addSubview(inputTextView)
    
    photoButtonsStackView.addArrangedSubview(cameraButton)
    photoButtonsStackView.addArrangedSubview(multiplePhotosButton)
    
    inputTextView.addSubview(placeholderLabel)
    saveButton.addSubview(loadingIndicator)
  }
  
  override func configureLayout() {
    // 네비게이션 바
    navigationBarView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(50)
    }
    
    // 저장 버튼 - 화면 하단에 고정
    saveButton.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-DesignSystem.Layout.standardMargin)
      make.height.equalTo(50)
    }
    
    // 스크롤뷰
    scrollView.snp.makeConstraints { make in
      make.top.equalTo(navigationBarView.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(saveButton.snp.top).offset(-DesignSystem.Layout.smallMargin)
    }
    
    // 컨텐츠뷰
    contentView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
      make.width.equalTo(scrollView)
    }
    
    // 날짜 라벨
    dateLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
      make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
    }
    
    // 요일 라벨
    dayOfWeekLabel.snp.makeConstraints { make in
      make.top.equalTo(dateLabel.snp.bottom).offset(5)
      make.leading.trailing.equalTo(dateLabel)
    }
    
    // 사진 버튼
    photoButton.snp.makeConstraints { make in
      make.top.equalTo(dayOfWeekLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
      make.leading.trailing.equalTo(dateLabel)
      make.height.equalTo(180)
    }
    
    // 사진 이미지뷰
    photoImageView.snp.makeConstraints { make in
      make.edges.equalTo(photoButton)
    }
    
    // 사진 제거 버튼
    removePhotoButton.snp.makeConstraints { make in
      make.top.equalTo(photoImageView).offset(10)
      make.trailing.equalTo(photoImageView).offset(-10)
      make.width.height.equalTo(30)
    }
    
    // 사진 선택 버튼 스택뷰
    photoButtonsStackView.snp.makeConstraints { make in
      make.top.equalTo(photoButton.snp.bottom).offset(DesignSystem.Layout.smallMargin)
      make.leading.trailing.equalTo(dateLabel)
      make.height.equalTo(50)
    }
    
    // 이미지 컬렉션뷰
    imagesCollectionView.snp.makeConstraints { make in
      make.top.equalTo(photoButtonsStackView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
      make.leading.trailing.equalTo(dateLabel)
      make.height.equalTo(120)
    }
    
    // 미디어 생성 버튼
    createMediaButton.snp.makeConstraints { make in
      make.top.equalTo(imagesCollectionView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
      make.leading.trailing.equalTo(dateLabel)
      make.height.equalTo(44)
    }
    
    // 텍스트뷰
    inputTextView.snp.makeConstraints { make in
      make.top.equalTo(createMediaButton.snp.bottom).offset(DesignSystem.Layout.standardMargin)
      make.leading.trailing.equalTo(dateLabel)
      make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
      make.height.greaterThanOrEqualTo(150)
    }
    
    // 플레이스홀더 라벨
    placeholderLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(12)
      make.leading.equalToSuperview().offset(15)
      make.trailing.equalToSuperview().offset(-15)
    }
    
    // 로딩 인디케이터
    loadingIndicator.snp.makeConstraints { make in
      make.center.equalTo(saveButton)
    }
  }
  
  override func configureView() {
    view.backgroundColor = .white
    
    // 네비게이션 바 설정
    navigationBarView.configure(title: "기록 하기", leftButtonType: .close)
    
    // 텍스트 뷰 Delegate 설정
    inputTextView.delegate = self
    
    // 컬렉션뷰 설정
    imagesCollectionView.delegate = self
    imagesCollectionView.dataSource = self
    
    // 다중 이미지 선택 버튼 액션
    multiplePhotosButton.addTarget(self, action: #selector(multiplePhotosButtonTapped), for: .touchUpInside)
    
    // 미디어 생성 버튼 액션
    createMediaButton.addTarget(self, action: #selector(createMediaButtonTapped), for: .touchUpInside)
    
    multiplePhotosButton.tag = 999
    
    // 포토 버튼 스택뷰 구성 변경 - 앨범 버튼 중앙에 배치
    photoButtonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    photoButtonsStackView.addArrangedSubview(cameraButton)
    photoButtonsStackView.addArrangedSubview(multiplePhotosButton)
  }
  
  private func removeSelectedPhoto() {
    selectedImages = []
    selectedImagesRelay.accept([])
    
    photoImageView.image = nil
    photoImageView.isHidden = true
    removePhotoButton.isHidden = true
    photoButton.isHidden = false
    
    imagesCollectionView.isHidden = true
    createMediaButton.isHidden = true
    
    // 원래 레이아웃으로 복원
    restoreOriginalLayout()
  }
  override func bind() {
    // 네비게이션 바 닫기 버튼 바인딩
    navigationBarView.leftButtonTapObservable
      .subscribe(onNext: { [weak self] in
        self?.dismiss(animated: true)
      })
      .disposed(by: disposeBag)
    
    // 사진 버튼 클릭 시 카메라/앨범 버튼 표시
    photoButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.togglePhotoButtonsStackView()
      })
      .disposed(by: disposeBag)
    
    // 카메라 버튼 액션
    cameraButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.presentCamera()
      })
      .disposed(by: disposeBag)
    
    
    // 사진 제거 버튼
    removePhotoButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.removeSelectedPhoto()
      })
      .disposed(by: disposeBag)
    
    // 입력 텍스트 반응형 바인딩
    let diaryTextObservable = inputTextView.rx.text.orEmpty.asObservable()
    
    // ViewModel과 바인딩
    let input = DailyDiaryViewModel.Input(
      viewDidLoad: Observable.just(()),
      saveButtonTap: saveButton.rx.tap.asObservable(),
      diaryText: diaryTextObservable,
      selectedImages: selectedImagesRelay.asObservable()
    )
    
    let output = viewModel.transform(input: input)
    
    // 날짜 라벨에 바인딩
    output.currentDateText
      .drive(dateLabel.rx.text)
      .disposed(by: disposeBag)
    
    output.dayOfWeekText
      .drive(dayOfWeekLabel.rx.text)
      .disposed(by: disposeBag)
    
    // 로딩 상태 바인딩
    output.isLoading
      .drive(onNext: { [weak self] isLoading in
        if isLoading {
          self?.saveButton.setTitle("", for: .normal)
          self?.loadingIndicator.startAnimating()
          self?.saveButton.isEnabled = false
        } else {
          self?.saveButton.setTitle("저장하기", for: .normal)
          self?.loadingIndicator.stopAnimating()
          self?.saveButton.isEnabled = true
        }
      })
      .disposed(by: disposeBag)
    
    // 저장 성공 시 화면 닫기
    output.saveSuccess
      .drive(onNext: { [weak self] in
        self?.showToast(message: "일기가 저장되었습니다.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          self?.dismiss(animated: true)
        }
      })
      .disposed(by: disposeBag)
    
    // 저장 에러 처리
    output.saveError
      .drive(onNext: { [weak self] error in
        self?.showAlert(title: "저장 실패", message: error.localizedDescription)
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Actions
  private func togglePhotoButtonsStackView() {
    photoButtonsStackView.isHidden.toggle()
  }
  
  @objc private func multiplePhotosButtonTapped() {
    var config = PHPickerConfiguration()
    config.selectionLimit = 0 // 무제한
    config.filter = .images
    
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    present(picker, animated: true)
  }
  
  @objc private func createMediaButtonTapped() {
    let alert = UIAlertController(title: "미디어 생성", message: "생성할 미디어 유형을 선택하세요", preferredStyle: .actionSheet)
    
    alert.addAction(UIAlertAction(title: "GIF 생성", style: .default) { [weak self] _ in
      self?.createGIF()
    })
    
    alert.addAction(UIAlertAction(title: "동영상 생성", style: .default) { [weak self] _ in
      self?.createVideo()
    })
    
    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
    
    present(alert, animated: true)
  }
  
  private func presentCamera() {
    AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
      DispatchQueue.main.async {
        guard let self = self else { return }
        
        if granted {
          if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true)
          } else {
            self.showAlert(title: "카메라 사용 불가", message: "이 기기에서는 카메라를 사용할 수 없습니다.")
          }
        } else {
          self.showCameraPermissionAlert()
        }
      }
    }
  }
  
  private func presentPhotoLibrary() {
    var configuration = PHPickerConfiguration()
    configuration.selectionLimit = 1
    configuration.filter = .images
    
    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = self
    present(picker, animated: true)
  }
  
  
  
  private func showCameraPermissionAlert() {
    let alert = UIAlertController(
      title: "카메라 접근 권한이 필요합니다",
      message: "설정 앱에서 MEOWIARY의 카메라 접근을 허용해주세요.",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
    alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
      if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsURL)
      }
    })
    
    present(alert, animated: true)
  }
  
  private func setupForEditing() {
    // 텍스트 뷰 편집 시 스크롤 조정
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      // 텍스트뷰의 현재 커서 위치가 보이도록 스크롤
      let cursorRect = self.inputTextView.caretRect(for: self.inputTextView.selectedTextRange?.end ?? self.inputTextView.endOfDocument)
      
      // 커서 주변 영역이 보이도록 스크롤
      let visibleRect = CGRect(
        x: cursorRect.origin.x,
        y: cursorRect.origin.y,
        width: cursorRect.width,
        height: cursorRect.height + 80 // 약간의 여유 공간
      )
      
      self.inputTextView.scrollRectToVisible(visibleRect, animated: true)
      
      // 스크롤 뷰도 해당 위치로 스크롤
      let convertedRect = self.inputTextView.convert(visibleRect, to: self.scrollView)
      self.scrollView.scrollRectToVisible(convertedRect, animated: true)
    }
  }
  
  // 이미지 처리 메소드
  private func updateSelectedImages(_ images: [UIImage]) {
    selectedImages = images
    selectedImagesRelay.accept(images)
    
    // UI 업데이트
    if images.isEmpty {
      // 이미지가 없는 경우
      imagesCollectionView.isHidden = true
      createMediaButton.isHidden = true
      photoButton.isHidden = false
      photoImageView.isHidden = true
      removePhotoButton.isHidden = true
    } else if images.count == 1 {
      // 단일 이미지인 경우
      imagesCollectionView.isHidden = true
      createMediaButton.isHidden = true
      photoButton.isHidden = true
      photoImageView.isHidden = false
      photoImageView.image = images.first
      removePhotoButton.isHidden = false
    } else {
      // 다중 이미지인 경우
      imagesCollectionView.isHidden = false
      createMediaButton.isHidden = false
      photoButton.isHidden = true
      photoImageView.isHidden = true
      removePhotoButton.isHidden = false
      imagesCollectionView.reloadData()
    }
  }
  
  // 미디어 생성 메소드
  private func createGIF() {
    guard selectedImages.count >= 2 else { return }
    
    // 로딩 표시
    loadingIndicator.startAnimating()
    saveButton.isEnabled = false
    
    // 백그라운드에서 GIF 생성
    DispatchQueue.global().async { [weak self] in
      guard let self = self else { return }
      
      if let gifURL = MediaGenerator.createGIF(from: self.selectedImages) {
        DispatchQueue.main.async {
          self.loadingIndicator.stopAnimating()
          self.saveButton.isEnabled = true
          self.shareMedia(url: gifURL, type: "GIF")
        }
      } else {
        DispatchQueue.main.async {
          self.loadingIndicator.stopAnimating()
          self.saveButton.isEnabled = true
          self.showToast(message: "GIF 생성에 실패했습니다.")
        }
      }
    }
  }
  
  private func createVideo() {
    guard selectedImages.count >= 2 else { return }
    
    // 로딩 표시
    loadingIndicator.startAnimating()
    saveButton.isEnabled = false
    
    MediaGenerator.createVideo(from: selectedImages) { [weak self] videoURL in
      DispatchQueue.main.async {
        guard let self = self else { return }
        
        self.loadingIndicator.stopAnimating()
        self.saveButton.isEnabled = true
        
        if let videoURL = videoURL {
          self.shareMedia(url: videoURL, type: "동영상")
        } else {
          self.showToast(message: "동영상 생성에 실패했습니다.")
        }
      }
    }
  }
  
  private func shareMedia(url: URL, type: String) {
    // 생성된 미디어 공유
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    activityVC.completionWithItemsHandler = { [weak self] (_, completed, _, _) in
      if completed {
        self?.showToast(message: "\(type)를 저장했습니다.")
      }
    }
    
    present(activityVC, animated: true)
  }
  
  // MARK: - 키보드 처리
  @objc private func keyboardWillShow(_ notification: Notification) {
    if inputTextView.isFirstResponder {
      // 텍스트뷰가 편집 중일 때만 스크롤 조정
      let userInfo = notification.userInfo
      let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
      
      // 스크롤뷰 컨텐츠 인셋 조정
      let contentInsets = UIEdgeInsets(
        top: 0,
        left: 0,
        bottom: keyboardFrame.height,
        right: 0
      )
      
      // 애니메이션과 함께 텍스트뷰가 보이도록 스크롤
      UIView.animate(withDuration: 0.3) {
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        // 텍스트뷰가 키보드에 가려지지 않도록 스크롤 조정
        let rect = self.inputTextView.convert(self.inputTextView.bounds, to: self.scrollView)
        self.scrollView.scrollRectToVisible(rect, animated: false)
      }
    }
  }
  
  // MARK: - Helper Methods
  private func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "확인", style: .default))
    present(alert, animated: true)
  }
}

// MARK: - UITextViewDelegate
extension DailyDiaryViewController: UITextViewDelegate {
  func textViewDidBeginEditing(_ textView: UITextView) {
    placeholderLabel.isHidden = true
    setupForEditing()
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    placeholderLabel.isHidden = !textView.text.isEmpty
  }
  
  func textViewDidChange(_ textView: UITextView) {
    placeholderLabel.isHidden = !textView.text.isEmpty
  }
}

// MARK: - UIImagePickerControllerDelegate
extension DailyDiaryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let image = info[.originalImage] as? UIImage {
      updateSelectedImages([image])
    }
    
    dismiss(animated: true)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true)
  }
}

// MARK: - PHPickerViewControllerDelegate
extension DailyDiaryViewController: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    dismiss(animated: true)
    
    if results.isEmpty {
      return
    }
    
    // 단일 이미지 선택인 경우
    if picker.configuration.selectionLimit == 1, let result = results.first {
      result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
        if let error = error {
          print("Photo picker error: \(error)")
          return
        }
        
        guard let image = object as? UIImage else { return }
        
        DispatchQueue.main.async {
          self?.updateSelectedImages([image])
        }
      }
      return
    }
    
    // 다중 이미지 선택인 경우
    var images: [UIImage] = []
    let group = DispatchGroup()
    
    for result in results {
      group.enter()
      
      result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
        defer { group.leave() }
        
        if let error = error {
          print("Photo picker error: \(error)")
          return
        }
        
        if let image = object as? UIImage {
          images.append(image)
        }
      }
    }
    
    group.notify(queue: .main) { [weak self] in
      self?.updateSelectedImages(images)
    }
  }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension DailyDiaryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return selectedImages.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell else {
      return UICollectionViewCell()
    }
    
    cell.configure(with: selectedImages[indexPath.item])
    
    cell.deleteAction = { [weak self] in
      guard let self = self else { return }
      
      // 이미지 삭제
      var newImages = self.selectedImages
      newImages.remove(at: indexPath.item)
      self.updateSelectedImages(newImages)
    }
    
    return cell
  }
}
