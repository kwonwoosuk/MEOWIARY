//
//  CardOptionPopupView.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol CardOptionPopupDelegate: AnyObject {
    func didSelectOption(_ option: CardOptionPopupView.OptionType)
    func didCancelOptionSelection()
}

class CardOptionPopupView: UIView {
    
    enum OptionType {
        case colorCard        // 색상 카드
        case colorSetting     // 색상 설정
        case featureImage     // 대표 이미지
        case selectFeatureImage  // 대표 이미지 직접선택
    }
    
    // MARK: - Properties
    weak var delegate: CardOptionPopupDelegate?
    private let disposeBag = DisposeBag()
    private let month: Int
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.layer.masksToBounds = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let optionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var colorCardButton: UIButton = createOptionButton(title: "색상 카드")
    private lazy var colorSettingButton: UIButton = createOptionButton(title: "색상 설정")
    private lazy var featureImageButton: UIButton = createOptionButton(title: "대표 이미지")
    private lazy var selectFeatureImageButton: UIButton = createOptionButton(title: "대표 이미지 직접선택")
    
    private let buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("완료", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = UIColor(hex: "FF6A6A") // 메인 컬러
        button.layer.cornerRadius = 10
        return button
    }()
    
    // MARK: - Initialization
    init(month: Int) {
        self.month = month
        super.init(frame: .zero)
        self.setupUI()
        self.setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(optionStackView)
        containerView.addSubview(buttonContainerView)
        buttonContainerView.addSubview(cancelButton)
        buttonContainerView.addSubview(selectButton)
        
        // 옵션 버튼 추가
        optionStackView.addArrangedSubview(colorCardButton)
        optionStackView.addArrangedSubview(colorSettingButton)
        optionStackView.addArrangedSubview(featureImageButton)
        optionStackView.addArrangedSubview(selectFeatureImageButton)
        
        // 타이틀 설정
        titleLabel.text = "\(month)월 카드 설정"
        
        // 레이아웃 설정
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(360)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(30)
        }
        
        optionStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        buttonContainerView.snp.makeConstraints { make in
            make.top.equalTo(optionStackView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(50)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
        }
        
        selectButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
        }
        
        // 애니메이션 시작 상태
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
    }
    
    private func createOptionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 10
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }
    
    private func setupActions() {
        // 버튼 액션 설정
        colorCardButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    self.updateSelectedOption(.colorCard) // 실시간 UI 업데이트
                    self.delegate?.didSelectOption(.colorCard)
                })
                .disposed(by: disposeBag)
            
            colorSettingButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    self.updateSelectedOption(.colorSetting) // 실시간 UI 업데이트
                    self.delegate?.didSelectOption(.colorSetting)
                })
                .disposed(by: disposeBag)
            
            featureImageButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    self.updateSelectedOption(.featureImage) // 실시간 UI 업데이트
                    self.delegate?.didSelectOption(.featureImage)
                })
                .disposed(by: disposeBag)
            
            selectFeatureImageButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    self.updateSelectedOption(.selectFeatureImage) // 실시간 UI 업데이트
                    self.delegate?.didSelectOption(.selectFeatureImage)
                })
                .disposed(by: disposeBag)
        
        // 취소 버튼
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismissWithAnimation()
                self?.delegate?.didCancelOptionSelection()
            })
            .disposed(by: disposeBag)
        
        // 선택 버튼 (기본은 취소와 동일하게 동작)
        selectButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismissWithAnimation()
                self?.delegate?.didCancelOptionSelection()
            })
            .disposed(by: disposeBag)
        
        // 배경 탭 시 팝업 닫기
        let tapGesture = UITapGestureRecognizer()
        self.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] recognizer in
                guard let self = self else { return }
                let location = recognizer.location(in: self)
                if !self.containerView.frame.contains(location) {
                    self.dismissWithAnimation()
                    self.delegate?.didCancelOptionSelection()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    func showWithAnimation() {
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func dismissWithAnimation() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    // 버튼 선택 상태 업데이트
    func updateSelectedOption(_ option: OptionType) {
        // 모든 버튼 초기화
        let buttons = [colorCardButton, colorSettingButton, featureImageButton, selectFeatureImageButton]
            buttons.forEach { button in
                button.backgroundColor = UIColor.systemGray6
                button.setTitleColor(.black, for: .normal)
                button.layer.borderWidth = 0 // border 제거
                button.layer.borderColor = nil // border 색상 제거
            }
        
        // 선택된 버튼 강조
        let selectedButton: UIButton
        switch option {
        case .colorCard:
            selectedButton = colorCardButton
        case .colorSetting:
            selectedButton = colorSettingButton
        case .featureImage:
            selectedButton = featureImageButton
        case .selectFeatureImage:
            selectedButton = selectFeatureImageButton
        }
        
        selectedButton.backgroundColor = UIColor(hex: "FF6A6A").withAlphaComponent(0.2)
        selectedButton.setTitleColor(UIColor(hex: "FF6A6A"), for: .normal)
        selectedButton.layer.borderWidth = 1
        selectedButton.layer.borderColor = UIColor(hex: "FF6A6A").cgColor
    }
}
