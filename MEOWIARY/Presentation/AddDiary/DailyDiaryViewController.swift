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

final class DailyDiaryViewController: BaseViewController {
    
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
        contentView.addSubview(photoButton)
        contentView.addSubview(inputTextView)
        inputTextView.addSubview(placeholderLabel)
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
        
        photoButton.snp.makeConstraints { make in
            make.top.equalTo(dayOfWeekLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(180)
        }
        
        inputTextView.snp.makeConstraints { make in
            make.top.equalTo(photoButton.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(200)
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(inputTextView.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalTo(dateLabel)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        
        // 네비게이션 바 설정
        navigationBarView.configure(title: "기록 하기", leftButtonType: .close)
        
        // 텍스트 뷰 Delegate 설정
        inputTextView.delegate = self
        
        // 버튼 액션 바인딩
        photoButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentImagePicker()
            })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveDiary()
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
    
    private func saveDiary() {
        // 임시 저장 로직
        print("일기 저장하기: \(inputTextView.text ?? "")")
        dismiss(animated: true)
    }
}

// MARK: - UITextViewDelegate
extension DailyDiaryViewController: UITextViewDelegate {
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
