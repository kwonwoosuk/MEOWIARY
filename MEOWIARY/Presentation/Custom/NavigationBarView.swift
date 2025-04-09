//
//  NavigationBarView.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/30/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class NavigationBarView: BaseView {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
  
    // MARK: - UI Components
    private let weatherIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = DesignSystem.Icon.Weather.sunny.toUIImage()
        imageView.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
  
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.regular)
        label.text = "2025년 3월 26일"
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        return label
    }()
  
    private let dayOfWeekLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
        label.text = "수요일"
        label.textColor = .gray
        return label
    }()
  
    // searchButton을 settingButton으로 이름 변경 및 아이콘 변경
    private let settingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystem.Icon.Navigation.settings.toUIImage(), for: .normal) // 설정 아이콘으로 변경
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        return button
    }()
  
    // MARK: - Configuration
    override func configureHierarchy() {
        addSubview(weatherIconView)
        addSubview(dateLabel)
        addSubview(dayOfWeekLabel)
        addSubview(settingButton) // 이름 변경 반영
    }
  
    override func configureLayout() {
        weatherIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
    
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(weatherIconView.snp.trailing).offset(DesignSystem.Layout.smallMargin)
            make.top.equalTo(weatherIconView).offset(-5)
        }
    
        dayOfWeekLabel.snp.makeConstraints { make in
            make.leading.equalTo(weatherIconView.snp.trailing).offset(DesignSystem.Layout.smallMargin)
            make.top.equalTo(dateLabel.snp.bottom).offset(2)
        }
    
        settingButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
    }
  
    override func configureView() {
        backgroundColor = .white
        updateDateLabels()
    
        // Setting button action
        settingButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleSettingTap()
            })
            .disposed(by: disposeBag)
    }
  
    // MARK: - Actions
    private func handleSettingTap() {
        // 설정 화면으로 이동
        guard let viewController = findViewController() else { return }
        let settingVC = SettingViewController()
        let navController = UINavigationController(rootViewController: settingVC)
        navController.modalPresentationStyle = .fullScreen
        viewController.present(navController, animated: true, completion: nil)
    }
  
    // MARK: - Helper Methods
    private func updateDateLabels() {
        let date = Date()
        dateLabel.text = UILabel.createDateLabel(for: date).text
        dayOfWeekLabel.text = UILabel.createDayOfWeekLabel(for: date).text
    }
  
    // MARK: - Public Methods
    func updateWeather(temperature: Int, condition: String) {
        let weatherIcon: DesignSystem.Icon.Weather
    
        switch condition.lowercased() {
        case "clear", "clear sky":
            weatherIcon = .sunny
        case "clouds", "scattered clouds", "broken clouds", "few clouds", "overcast clouds":
            weatherIcon = .cloudy
        case "rain", "shower rain", "light rain", "moderate rain", "heavy intensity rain", "very heavy rain", "extreme rain":
            weatherIcon = .rainy
        case "snow", "light snow", "heavy snow", "sleet", "shower sleet":
            weatherIcon = .snowy
        case "thunderstorm", "thunderstorm with light rain", "thunderstorm with rain", "thunderstorm with heavy rain":
            weatherIcon = .thunderstorm
        default:
            weatherIcon = .sunny
        }
    
        weatherIconView.image = weatherIcon.toUIImage()
        updateDateLabels()
    
        if let existingText = dayOfWeekLabel.text {
            if !existingText.contains("°C") {
                dayOfWeekLabel.text = "\(existingText) · \(temperature)°C"
            }
        }
    }
    
    // 뷰 컨트롤러를 찾는 헬퍼 메서드
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}
