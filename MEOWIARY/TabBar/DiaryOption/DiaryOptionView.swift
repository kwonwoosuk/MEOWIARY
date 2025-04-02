//
//  DiaryOptionView.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class DiaryOptionView: BaseView {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    let dailyRecordButtonTapped = PublishSubject<Void>()
    let symptomRecordButtonTapped = PublishSubject<Void>()
    
    // MARK: - UI Components
    private let handleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let dailyRecordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("오늘 기록 남기기", for: .normal)
        button.setTitleColor(DesignSystem.Color.Tint.text.inUIColor(), for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
        return button
    }()
    
    private let symptomRecordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("증상 기록하기", for: .normal)
        button.setTitleColor(DesignSystem.Color.Tint.text.inUIColor(), for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
        return button
    }()
    
    private let dailyRecordIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "heart")
        imageView.tintColor = DesignSystem.Color.Tint.main.inUIColor()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let symptomRecordIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "thermometer")
        imageView.tintColor = DesignSystem.Color.Tint.action.inUIColor()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        return view
    }()
    
    // MARK: - Configuration
    override func configureHierarchy() {
        addSubview(handleView)
        addSubview(dailyRecordIcon)
        addSubview(dailyRecordButton)
        addSubview(separatorLine)
        addSubview(symptomRecordIcon)
        addSubview(symptomRecordButton)
    }
    
    override func configureLayout() {
        handleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(5)
        }
        
        dailyRecordIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.top.equalTo(handleView.snp.bottom).offset(30)
            make.width.height.equalTo(24)
        }
        
        dailyRecordButton.snp.makeConstraints { make in
            make.leading.equalTo(dailyRecordIcon.snp.trailing).offset(DesignSystem.Layout.standardMargin)
            make.centerY.equalTo(dailyRecordIcon)
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.height.equalTo(40)
        }
        
        separatorLine.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(dailyRecordButton.snp.bottom).offset(10)
            make.height.equalTo(1)
        }
        
        symptomRecordIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.top.equalTo(separatorLine.snp.bottom).offset(20)
            make.width.height.equalTo(24)
        }
        
        symptomRecordButton.snp.makeConstraints { make in
            make.leading.equalTo(symptomRecordIcon.snp.trailing).offset(DesignSystem.Layout.standardMargin)
            make.centerY.equalTo(symptomRecordIcon)
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    override func configureView() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // 그림자 효과 추가
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: -3)
        layer.shadowRadius = 5
        
        // 버튼 액션 바인딩
        dailyRecordButton.rx.tap
            .bind(to: dailyRecordButtonTapped)
            .disposed(by: disposeBag)
        
        symptomRecordButton.rx.tap
            .bind(to: symptomRecordButtonTapped)
            .disposed(by: disposeBag)
    }
}
