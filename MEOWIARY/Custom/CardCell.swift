//
//  CardCell.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import UIKit
import SnapKit
import Kingfisher

final class CardCell: UICollectionViewCell {
    
    // MARK: - Properties
    private var monthImages: [String] = [
        "jan_image", "feb_image", "mar_image", "apr_image",
        "may_image", "jun_image", "jul_image", "aug_image",
        "sep_image", "oct_image", "nov_image", "dec_image"
    ]
    private var year: Int = Calendar.current.component(.year, from: Date())
    private var month: Int = 1
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystem.Color.Background.card.inUIColor()
        view.layer.cornerRadius = DesignSystem.Layout.largeCornerRadius
        return view
    }()
    
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.extraLarge)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.3
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let pageInfoLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystem.Icon.Control.options.toUIImage(), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.image = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(backgroundImageView)
        containerView.addSubview(monthLabel)
        containerView.addSubview(pageInfoLabel)
        containerView.addSubview(optionsButton)
        
        // Set constraints
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(DesignSystem.Layout.smallMargin)
        }
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        monthLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(50)
            make.width.greaterThanOrEqualTo(80) // 최소 너비 설정
        }
        
        pageInfoLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.centerX.equalToSuperview()
        }
        
        optionsButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(24)
        }
    }
    
    // MARK: - Configuration
    func configure(forMonth month: Int, year: Int = Calendar.current.component(.year, from: Date())) {
        // 확실히 레이아웃 갱신
        self.layoutIfNeeded()
        
        // 현재 년도와 월 저장
        self.year = year
        self.month = month
        
        // Set month name (1-based index)
        let monthNames = ["1월", "2월", "3월", "4월", "5월", "6월",
                          "7월", "8월", "9월", "10월", "11월", "12월"]
        
        // Month label 텍스트 설정 및 강제 갱신
        UIView.performWithoutAnimation {
            monthLabel.text = monthNames[month - 1]
            monthLabel.layoutIfNeeded()
        }
        
        // Set page info
        let totalDaysInMonth = daysInMonth(month: month, year: year)
        pageInfoLabel.text = "1 / \(totalDaysInMonth)"
        
        // Load background image
        // In a real app, you'd load from a real source - here we're just setting a color
        if month == 3 {
            // March - blue background as shown in screenshots
            containerView.backgroundColor = DesignSystem.Color.Background.card.inUIColor()
        } else {
            // Random pastel color for other months
            containerView.backgroundColor = getRandomPastelColor()
        }
        
        // 로그 출력
        print("월 셀 구성 완료: \(year)년 \(month)월, 텍스트: \(monthLabel.text ?? "nil")")
        
        // Load a random image for the background
        loadRandomBackgroundImage()
    }
    
    private func daysInMonth(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        
        if let date = calendar.date(from: dateComponents),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        
        return 30 // Default fallback
    }
    
    private func getRandomPastelColor() -> UIColor {
        let hue = CGFloat.random(in: 0...1)
        return UIColor(hue: hue, saturation: 0.5, brightness: 0.9, alpha: 1.0)
    }
    
    private func loadRandomBackgroundImage() {
        // In a real app, this would load actual images from your database
        // For now, we'll simulate this with a placeholder
        
        // This simulates loading a random image using Kingfisher
        // In a real app, you'd use a URL like:
        // let url = URL(string: "https://example.com/images/random.jpg")
        // backgroundImageView.kf.setImage(with: url)
        
        // Instead, we'll just set the image to nil to simulate a placeholder
        backgroundImageView.image = UIImage(named: "placeholder_image")
    }
    
    // 뷰 크기가 변경된 후에도 콘텐츠가 올바르게 표시되도록 함
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 컨테이너 뷰 코너 반경 업데이트
        containerView.layer.cornerRadius = DesignSystem.Layout.largeCornerRadius
        
        // 컨텐츠 레이아웃 갱신
        monthLabel.layoutIfNeeded()
        pageInfoLabel.layoutIfNeeded()
    }
}
