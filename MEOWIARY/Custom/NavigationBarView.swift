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
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystem.Icon.Navigation.search.toUIImage(), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        return button
    }()
    
    // MARK: - Configuration
    override func configureHierarchy() {
        addSubview(weatherIconView)
        addSubview(dateLabel)
        addSubview(dayOfWeekLabel)
        addSubview(searchButton)
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
        
        searchButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
    }
    
    override func configureView() {
        backgroundColor = .white
        updateDateLabels()
        
        // Search button action
        searchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleSearchTap()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    private func handleSearchTap() {
        // Handle search functionality
        print("Search tapped")
    }
    
    // MARK: - Helper Methods
    private func updateDateLabels() {
        let date = Date()
        let dateFormatter = DateFormatter()
        
        // Format for date label
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        dateLabel.text = dateFormatter.string(from: date)
        
        // Format for day of week
        dateFormatter.dateFormat = "EEEE"
        dayOfWeekLabel.text = dateFormatter.string(from: date)
    }
    
    // MARK: - Public Methods
    func updateWeather(temperature: Int, condition: String) {
        // Update weather icon based on condition
        let weatherIcon: DesignSystem.Icon.Weather
        
        switch condition.lowercased() {
        case "clear", "sunny":
            weatherIcon = .sunny
        case "cloudy", "clouds", "overcast":
            weatherIcon = .cloudy
        case "rain", "rainy":
            weatherIcon = .rainy
        case "snow", "snowy":
            weatherIcon = .snowy
        case "thunderstorm":
            weatherIcon = .thunderstorm
        default:
            weatherIcon = .sunny
        }
        
        weatherIconView.image = weatherIcon.toUIImage()
    }
}
