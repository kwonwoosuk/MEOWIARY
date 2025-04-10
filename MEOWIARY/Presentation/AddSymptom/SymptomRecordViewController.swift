//
//  SymptomRecordViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import PhotosUI

final class SymptomRecordViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var viewModel: SymptomRecordViewModel
    private var selectedImages: [UIImage] = [] {
        didSet {
            updateImageViews()
        }
    }
    // 수정 모드 관련 프로퍼티
    private var isEditMode = false
    private var editingSymptom: Symptom?
    
    private let selectedImagesRelay = BehaviorRelay<[UIImage]>(value: [])
    private let severityRelay = BehaviorRelay<Int>(value: 1)
    
    // MARK: - UI Components
    private let navigationBarView = CustomNavigationBarView()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let dateLabel = UILabel.createDateLabel()
    private let dayOfWeekLabel = UILabel.createDayOfWeekLabel()
    
    private let symptomNameTextField: UITextField = {
        let textField = UITextField()
        textField.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
        textField.placeholder = "증상명을 입력하세요 (예: 구토, 설사, 기침 등)"
        textField.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
        textField.layer.cornerRadius = DesignSystem.Layout.cornerRadius
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.returnKeyType = .done
        return textField
    }()
    
    private let severityLabel: UILabel = {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.text = "증상 심각도"
        return label
    }()
    
    private let severitySlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 5
        slider.value = 1
        slider.minimumTrackTintColor = DesignSystem.Color.Tint.main.inUIColor()
        slider.thumbTintColor = DesignSystem.Color.Status.negative1.inUIColor()
        return slider
    }()
    
    private let severityValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.text = "1 / 5"
        label.textAlignment = .right
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
        button.setTitle("증상 사진 촬영", for: .normal)
        
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
    
    private let notesTextView: UITextView = {
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
        label.text = "증상에 대한 추가 설명을 입력하세요..."
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        label.numberOfLines = 1
        return label
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("증상 저장하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        button.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
        button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    // MARK: - Initialization
    init() {
        self.viewModel = SymptomRecordViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    // 특정 날짜 지정 생성자
    init(year: Int, month: Int, day: Int) {
        self.viewModel = SymptomRecordViewModel(year: year, month: month, day: day)
        super.init(nibName: nil, bundle: nil)
        if isEditMode {
               loadExistingData()
           }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureForEdit(symptom: Symptom) {
        isEditMode = true
        editingSymptom = symptom
        
        // viewDidLoad 이후에 호출되면 즉시 데이터 로드
        if isViewLoaded {
            loadExistingData()
        }
    }
    
    private func loadExistingData() {
        guard isEditMode, let symptom = editingSymptom else { return }
        
        // 네비게이션 타이틀 변경
        navigationBarView.configure(title: "증상 수정", leftButtonType: .close)
        
        // 저장 버튼 텍스트 변경
        saveButton.setTitle("수정 완료", for: .normal)
        
        // 증상명 설정
        symptomNameTextField.text = symptom.name
        
        // 심각도 설정
        severitySlider.value = Float(symptom.severity)
        severityRelay.accept(symptom.severity)
        
        // 슬라이더 값에 따른 UI 업데이트
        let severityText: String
        switch symptom.severity {
        case 1:
            severityText = "일상적인 증상"
            severitySlider.thumbTintColor = DesignSystem.Color.Status.negative1.inUIColor()
        case 2:
            severityText = "가벼운 증상"
            severitySlider.thumbTintColor = DesignSystem.Color.Status.negative2.inUIColor()
        case 3:
            severityText = "중증 증상"
            severitySlider.thumbTintColor = DesignSystem.Color.Status.negative3.inUIColor()
        case 4:
            severityText = "심한증상"
            severitySlider.thumbTintColor = DesignSystem.Color.Status.negative4.inUIColor()
        case 5:
            severityText = "응급 고위험"
            severitySlider.thumbTintColor = DesignSystem.Color.Status.negative5.inUIColor()
        default:
            severityText = "일상적인 증상"
            severitySlider.thumbTintColor = DesignSystem.Color.Status.negative1.inUIColor()
        }
        severityValueLabel.text = severityText
        
        // 노트 설정
        if let notes = symptom.notes {
            notesTextView.text = notes
            placeholderLabel.isHidden = true
        }
        
        // 이미지 로드
        let symptomImages = Array(symptom.symptomImages)
        if !symptomImages.isEmpty {
            var images: [UIImage] = []
            for symImage in symptomImages {
                if let path = symImage.originalImagePath,
                   let image = ImageManager.shared.loadOriginalImage(from: path) {
                    images.append(image)
                }
            }
            
            if !images.isEmpty {
                selectedImages = images
                selectedImagesRelay.accept(images)
            }
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
        contentView.addSubview(symptomNameTextField)
        contentView.addSubview(severityLabel)
        contentView.addSubview(severitySlider)
        contentView.addSubview(severityValueLabel)
        contentView.addSubview(photoButton)
        contentView.addSubview(photoImageView)
        contentView.addSubview(removePhotoButton)
        contentView.addSubview(photoButtonsStackView)
        contentView.addSubview(imagesCollectionView)
        contentView.addSubview(notesTextView)
        
        photoButtonsStackView.addArrangedSubview(cameraButton)
        photoButtonsStackView.addArrangedSubview(multiplePhotosButton)
        
        notesTextView.addSubview(placeholderLabel)
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
        
        // 증상명 텍스트필드
        symptomNameTextField.snp.makeConstraints { make in
            make.top.equalTo(dayOfWeekLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(50)
        }
        
        // 심각도 라벨
        severityLabel.snp.makeConstraints { make in
            make.top.equalTo(symptomNameTextField.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.equalTo(dateLabel)
        }
        
        // 심각도 값 라벨
        severityValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(severityLabel)
            make.trailing.equalTo(dateLabel)
            make.width.equalTo(120)
        }
        
        // 심각도 슬라이더
        severitySlider.snp.makeConstraints { make in
            make.top.equalTo(severityLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalTo(dateLabel)
        }
        
        // 사진 버튼
        photoButton.snp.makeConstraints { make in
            make.top.equalTo(severitySlider.snp.bottom).offset(DesignSystem.Layout.standardMargin)
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
        
        // 텍스트뷰
        notesTextView.snp.makeConstraints { make in
            make.top.equalTo(photoButtonsStackView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
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
        navigationBarView.configure(title: "증상 기록", leftButtonType: .close)
        
        // 텍스트 뷰 Delegate 설정
        notesTextView.delegate = self
        symptomNameTextField.delegate = self
        
        // 컬렉션뷰 설정
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        
        // 초기 심각도 레이블 설정 (1: 일상적인 증상)
        severityValueLabel.text = "일상적인 증상"
        severityValueLabel.textAlignment = .right
        
        // 슬라이더 초기값 설정
        severitySlider.value = 1
        severitySlider.thumbTintColor = DesignSystem.Color.Status.negative1.inUIColor()
    }
    
    private func updateImageViews() {
        if selectedImages.count > 1 {
            // 여러 이미지가 선택된 경우
            photoImageView.isHidden = true
            photoButton.isHidden = true
            removePhotoButton.isHidden = true
            
            // 선택된 이미지들을 표시하는 컬렉션뷰 표시
            imagesCollectionView.isHidden = false
            imagesCollectionView.reloadData()
            
            // 레이아웃 조정
            imagesCollectionView.snp.remakeConstraints { make in
                make.top.equalTo(photoButtonsStackView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
                make.leading.trailing.equalTo(dateLabel)
                make.height.equalTo(120)
            }
            
            notesTextView.snp.remakeConstraints { make in
                make.top.equalTo(imagesCollectionView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
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
            
            // 원래 레이아웃으로 복원
            restoreOriginalLayout()
        } else {
            // 이미지가 선택되지 않은 경우
            photoImageView.isHidden = true
            photoButton.isHidden = false
            removePhotoButton.isHidden = true
            
            imagesCollectionView.isHidden = true
            
            // 원래 레이아웃으로 복원
            restoreOriginalLayout()
        }
        
        view.layoutIfNeeded()
    }
    
    // 원래 레이아웃을 복원하는 메서드
    private func restoreOriginalLayout() {
        // 기존 레이아웃 복원
        photoButtonsStackView.snp.remakeConstraints { make in
            make.top.equalTo(photoButton.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(50)
        }
        
        notesTextView.snp.remakeConstraints { make in
            make.top.equalTo(photoButtonsStackView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.height.greaterThanOrEqualTo(150)
        }
    }
    
    // MARK: - Binding
    // SymptomRecordViewController.swift 내의 bind() 메서드 부분 수정
    
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
        
        // 다중 이미지 선택 버튼 액션
        multiplePhotosButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentPhotoPicker()
            })
            .disposed(by: disposeBag)
        
        // 사진 제거 버튼
        removePhotoButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.removeSelectedPhoto()
            })
            .disposed(by: disposeBag)
        
        // 슬라이더 값 변경 이벤트 연결
        severitySlider.rx.value.changed
            .map { Int($0.rounded()) }
            .do(onNext: { [weak self] value in
                self?.severityRelay.accept(value)
                
                
                // 심각도에 따른 색상 변경
                let severityText: String
                switch value {
                case 1:
                    severityText = "일상적인 증상"
                    self?.severitySlider.thumbTintColor = DesignSystem.Color.Status.negative1.inUIColor()
                case 2:
                    severityText = "가벼운 증상"
                    self?.severitySlider.thumbTintColor = DesignSystem.Color.Status.negative2.inUIColor()
                case 3:
                    severityText = "중증 증상"
                    self?.severitySlider.thumbTintColor = DesignSystem.Color.Status.negative3.inUIColor()
                case 4:
                    severityText = "심한증상"
                    self?.severitySlider.thumbTintColor = DesignSystem.Color.Status.negative4.inUIColor()
                case 5:
                    severityText = "응급 고위험"
                    self?.severitySlider.thumbTintColor = DesignSystem.Color.Status.negative5.inUIColor()
                default:
                    severityText = "일상적인 증상"
                    self?.severitySlider.thumbTintColor = DesignSystem.Color.Status.negative1.inUIColor()
                }
                
                self?.severityValueLabel.text = severityText
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // ViewModel과 바인딩
        let input = SymptomRecordViewModel.Input(
              viewDidLoad: Observable.just(()),
              saveButtonTap: saveButton.rx.tap.asObservable(),
              symptomName: symptomNameTextField.rx.text.orEmpty.asObservable(),
              severityValue: severityRelay.asObservable(),
              notes: notesTextView.rx.text.orEmpty.asObservable(),
              selectedImages: selectedImagesRelay.asObservable(),
              isEditMode: Observable.just(isEditMode),
              editingSymptom: Observable.just(editingSymptom)
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
                    self?.saveButton.setTitle("증상 저장하기", for: .normal)
                    self?.loadingIndicator.stopAnimating()
                    self?.saveButton.isEnabled = true
                }
            })
            .disposed(by: disposeBag)
        
        // 저장 성공 시 화면 닫기
        output.saveSuccess
            .drive(onNext: { [weak self] in
                self?.showToast(message: "증상이 저장되었습니다.")
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
        
        // 토스트 메시지 구독
        output.toastMessage
            .filter { !$0.isEmpty }
            .drive(onNext: { [weak self] message in
                self?.showToast(message: message)
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
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 무제한
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
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
    
    private func removeSelectedPhoto() {
        selectedImages = []
        selectedImagesRelay.accept([])
        
        photoImageView.image = nil
        photoImageView.isHidden = true
        removePhotoButton.isHidden = true
        photoButton.isHidden = false
        
        imagesCollectionView.isHidden = true
        
        // 원래 레이아웃으로 복원
        restoreOriginalLayout()
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension SymptomRecordViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - UITextFieldDelegate
extension SymptomRecordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate
extension SymptomRecordViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImages = [image]
            selectedImagesRelay.accept(selectedImages)
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension SymptomRecordViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        if results.isEmpty {
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
            self?.selectedImages = images
            self?.selectedImagesRelay.accept(images)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension SymptomRecordViewController: UICollectionViewDataSource, UICollectionViewDelegate {
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
            self.selectedImages = newImages
            self.selectedImagesRelay.accept(newImages)
        }
        
        return cell
    }
}
