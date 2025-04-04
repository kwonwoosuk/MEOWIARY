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
  private var selectedImage: UIImage?
  private let selectedImageRelay = BehaviorRelay<UIImage?>(value: nil)
  
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
  
  private let photoImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
    imageView.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    imageView.isHidden = true
    return imageView
  }()
  
  private let photoButton: UIButton = {
    let button = UIButton(type: .system)
    button.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
    button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    
    // 카메라 아이콘 설정
    let cameraImage = UIImage(systemName: "camera")
    button.setImage(cameraImage, for: .normal)
    button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
    
    return button
  }()
  
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
  
  private let photoLibraryButton: UIButton = {
    let button = UIButton(type: .system)
    button.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
    button.setTitle("앨범", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    return button
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

  // 뷰가 사라질 때 옵저버 제거
  deinit {
      NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - UI Setup
  override func configureHierarchy() {
    view.addSubview(navigationBarView)
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    
    contentView.addSubview(dateLabel)
    contentView.addSubview(dayOfWeekLabel)
    contentView.addSubview(photoButton)
    contentView.addSubview(photoImageView)
    contentView.addSubview(removePhotoButton)
    contentView.addSubview(photoButtonsStackView)
    
    photoButtonsStackView.addArrangedSubview(cameraButton)
    photoButtonsStackView.addArrangedSubview(photoLibraryButton)
    
    contentView.addSubview(inputTextView)
    inputTextView.addSubview(placeholderLabel)
    view.addSubview(saveButton)
    saveButton.addSubview(loadingIndicator)
  }
  
  override func configureLayout() {
      // 네비게이션 바 설정
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
      
      // 스크롤뷰 설정
      scrollView.snp.makeConstraints { make in
          make.top.equalTo(navigationBarView.snp.bottom)
          make.leading.trailing.equalToSuperview()
          make.bottom.equalTo(saveButton.snp.top)
      }
      
      // 컨텐츠뷰 설정 - 스크롤뷰와 동일한 너비, 필요시 더 높게
      contentView.snp.makeConstraints { make in
          make.top.leading.trailing.bottom.equalToSuperview()
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
      
      // 텍스트뷰 설정 - 키 포인트!
      inputTextView.snp.makeConstraints { make in
          make.top.equalTo(photoButtonsStackView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
          make.leading.trailing.equalTo(dateLabel)
          // 중요: 텍스트뷰가 컨텐츠뷰의 하단까지 확장되도록 설정
          make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
          // 최소 높이만 설정하고 실제 높이는 컨텐츠에 맞게 조정
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
    
    // 앨범 버튼 액션
    photoLibraryButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.presentPhotoLibrary()
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
    
    // 선택된 이미지 반응형 바인딩
    let selectedImageObservable = Observable<UIImage?>.create { [weak self] observer in
      observer.onNext(self?.selectedImage)
      return Disposables.create()
    }
    
    
    
    // ViewModel과 바인딩
    let input = DailyDiaryViewModel.Input(
      viewDidLoad: Observable.just(()),
      saveButtonTap: saveButton.rx.tap.asObservable(),
      diaryText: diaryTextObservable,
      selectedImage: selectedImageRelay.asObservable()
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
  
  private func removeSelectedPhoto() {
    selectedImage = nil
    photoImageView.image = nil
    photoImageView.isHidden = true
    removePhotoButton.isHidden = true
    photoButton.isHidden = false
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
  
  
  
  private func presentImagePicker() {
      let imagePicker = UIImagePickerController()
      imagePicker.sourceType = .photoLibrary
      imagePicker.delegate = self
      present(imagePicker, animated: true)
  }
  
  private func setupForEditing() {
      // 텍스트 뷰 편집 시 스크롤 조정
      DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          
          // 텍스트뷰의 현재 커서 위치가 보이도록 스크롤
          let selectedRange = self.inputTextView.selectedRange
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
      selectedImage = image
      selectedImageRelay.accept(image)
      
      selectedImageRelay.accept(image)
      photoImageView.image = image
      photoImageView.isHidden = false
      removePhotoButton.isHidden = false
      photoButton.isHidden = true
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
    
    guard let result = results.first else { return }
    
    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
      if let error = error {
        print("Photo picker error: \(error)")
        return
      }
      
      guard let image = object as? UIImage else { return }
      
      DispatchQueue.main.async {
        self?.setSelectedImage(image)
      }
    }
  }
  
  private func setSelectedImage(_ image: UIImage) {
      selectedImage = image
      selectedImageRelay.accept(image)
      photoImageView.image = image
      photoImageView.isHidden = false
      removePhotoButton.isHidden = false
      photoButton.isHidden = true
      photoButtonsStackView.isHidden = true
  }
}

