//
//  CustomNavigationBarView.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

enum NavigationButtonType {
    case back
    case close
    case none
    
    var image: UIImage? {
        switch self {
        case .back:
            return UIImage(systemName: "arrow.left")
        case .close:
            return UIImage(systemName: "xmark")
        case .none:
            return nil
        }
    }
}

final class CustomNavigationBarView: BaseView {
    
    // MARK: - Properties
    private let leftButtonSubject = PublishSubject<Void>()
    var leftButtonTapObservable: Observable<Void> {
        return leftButtonSubject.asObservable()
    }
    
    // MARK: - UI Components
    private let leftButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.textAlignment = .center
        return label
    }()
    
    private let rightButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        button.isHidden = true
        return button
    }()
    
    private let bottomSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        return view
    }()
    
    // MARK: - Configuration
    override func configureHierarchy() {
        addSubview(leftButton)
        addSubview(titleLabel)
        addSubview(rightButton)
        addSubview(bottomSeparator)
    }
    
    override func configureLayout() {
        leftButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(leftButton.snp.trailing).offset(DesignSystem.Layout.smallMargin)
            make.trailing.lessThanOrEqualTo(rightButton.snp.leading).offset(-DesignSystem.Layout.smallMargin)
        }
        
        rightButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        bottomSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    override func configureView() {
        backgroundColor = .white
        
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func leftButtonTapped() {
        leftButtonSubject.onNext(())
    }
    
    @objc private func rightButtonTapped() {
        // gps를 사용할 수 없는 경우 주소 수동 입력... 근데 이거 메인에서도 사용하는데 주소 검색기반 위치 찾는 로직뷰를 하나로 재사용하면 어떨까?
    }
    
    // MARK: - Public Methods
    func configure(title: String, leftButtonType: NavigationButtonType = .back, rightButtonImage: UIImage? = nil) {
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18)
        leftButton.setImage(leftButtonType.image, for: .normal)
        leftButton.isHidden = leftButtonType == .none
        
        if let rightImage = rightButtonImage {
            rightButton.setImage(rightImage, for: .normal)
            rightButton.isHidden = false
        } else {
            rightButton.isHidden = true
        }
    }
}
