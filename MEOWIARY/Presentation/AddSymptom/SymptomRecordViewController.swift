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

final class SymptomRecordViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
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
        slider.value = 3
        slider.minimumTrackTintColor = DesignSystem.Color.Tint.main.inUIColor()
        slider.thumbTintColor = DesignSystem.Color.Tint.action.inUIColor()
        return slider
    }()
    
    private let severityValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.text = "3 / 5"
        label.textAlignment = .right
        return label
    }()
    
    private let photoButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
        button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
        
        // 카메라 아이콘 설정
        let cameraImage = UIImage(systemName: "camera")
        button.setImage(cameraImage, for: .normal)
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        button.imageView?.contentMode = .scaleAspectFit
        
        // 텍스트 설정
        button.setTitle("  증상 사진 촬영", for: .normal)
        button.setTitleColor(DesignSystem.Color.Tint.text.inUIColor(), for: .normal)
        
        return button
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - UI Setup
    override func configureHierarchy() {
        view.addSubview(navigationBarView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(dateLabel)
        contentView.addSubview(dayOfWeekLabel)
        contentView.addSubview(symptomNameTextField)
        contentView.addSubview(severityLabel)
        contentView.addSubview(severitySlider)
        contentView.addSubview(severityValueLabel)
        contentView.addSubview(photoButton)
        contentView.addSubview(notesTextView)
        notesTextView.addSubview(placeholderLabel)
        contentView.addSubview(saveButton)
    }
    
    override func configureLayout() {
        navigationBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationBarView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
            make.height.greaterThanOrEqualTo(view.frame.height - 50 - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
        }
        
        dayOfWeekLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(5)
            make.leading.trailing.equalTo(dateLabel)
        }
        
        symptomNameTextField.snp.makeConstraints { make in
            make.top.equalTo(dayOfWeekLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(50)
        }
        
        severityLabel.snp.makeConstraints { make in
            make.top.equalTo(symptomNameTextField.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.equalTo(dateLabel)
        }
        
        severityValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(severityLabel)
            make.trailing.equalTo(dateLabel)
            make.width.equalTo(40)
        }
        
        severitySlider.snp.makeConstraints { make in
            make.top.equalTo(severityLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalTo(dateLabel)
        }
        
        photoButton.snp.makeConstraints { make in
            make.top.equalTo(severitySlider.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(180)
        }
        
        notesTextView.snp.makeConstraints { make in
            make.top.equalTo(photoButton.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(150)
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(notesTextView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        
        // 네비게이션 바 설정
        navigationBarView.configure(title: "증상 기록", leftButtonType: .close)
        
        // 텍스트 뷰 Delegate 설정
        notesTextView.delegate = self
        symptomNameTextField.delegate = self
        
        // 슬라이더 값 변경 이벤트 연결
        severitySlider.rx.value.changed
            .map { Int($0.rounded()) }
            .subscribe(onNext: { [weak self] value in
                self?.severityValueLabel.text = "\(value) / 5"
            })
            .disposed(by: disposeBag)
        
        // 버튼 액션 바인딩
        photoButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentImagePicker()
            })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveSymptom()
            })
            .disposed(by: disposeBag)
        
        // 네비게이션 바 닫기 버튼 바인딩
        navigationBarView.leftButtonTapObservable
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    private func presentImagePicker() {
        // 실제 구현에서는 UIImagePickerController 사용
        print("카메라/앨범 선택 화면 표시하기")
    }
    
    private func saveSymptom() {
        // 입력 유효성 검증
        guard let symptomName = symptomNameTextField.text, !symptomName.isEmpty else {
            // 알림 표시
            print("증상명을 입력해주세요")
            return
        }
        
        // 증상 저장 로직
        let severity = Int(severitySlider.value.rounded())
        let notes = notesTextView.text ?? ""
        
        print("증상 저장하기: \(symptomName), 심각도: \(severity), 설명: \(notes)")
        
        // 저장 후 화면 닫기
        dismiss(animated: true)
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
