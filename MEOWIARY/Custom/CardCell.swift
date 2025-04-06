//
//  CardCell.swift - UI 및 마진 수정
//  MEOWIARY
//

import UIKit
import RxSwift
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
  var isFlipped = false
  let disposeBag = DisposeBag()
  private var symptomsData: [Int: Bool] = [:]  // Dictionary to track days with symptoms
  let dateTapped = PublishSubject<(year: Int, month: Int, day: Int)>()
  // MARK: - UI Components
  private let containerView: UIView = {
    let view = UIView()
    view.backgroundColor = DesignSystem.Color.Background.card.inUIColor()
    view.layer.cornerRadius = DesignSystem.Layout.largeCornerRadius
    view.clipsToBounds = true
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
  
  // Calendar View (뒷면)
  private let calendarContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = DesignSystem.Layout.largeCornerRadius
    view.isHidden = true
    view.clipsToBounds = true
    return view
  }()
  
  private let calendarMonthLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.7
    return label
  }()
  
  private let calendarView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }()
  
  private let daysStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 0
    return stackView
  }()
  
  private let calendarGridView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }()
  
  private let messageLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.regular)
    label.textAlignment = .center
    label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    label.text = "날짜를 선택해 일기를 작성해세요."
    return label
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
    
    // 플립 상태는 초기화하지 않고 유지
    // isFlipped 상태는 CardCalendarView의 isCalendarMode에 따라 설정됨
    
    // 증상 데이터 초기화
    symptomsData.removeAll()
    
    // 캘린더 그리드 초기화
    for subview in calendarGridView.subviews {
      subview.removeFromSuperview()
    }
  }
  
  private func addImageIndicator(to button: UIButton, imagePath: String?) {
    guard let imagePath = imagePath else { return }
    
    let isSmallScreen = UIScreen.main.bounds.height <= 667
    let indicatorSize: CGFloat = isSmallScreen ? 18 : 22
    
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = indicatorSize / 2
    
    // 썸네일 이미지 로드
    if let thumbnail = ImageManager.shared.loadThumbnailImage(from: imagePath) {
      imageView.image = thumbnail
    } else {
      // 기본 이미지로 대체
      imageView.image = UIImage(systemName: "photo")
      imageView.tintColor = .white
      imageView.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
    }
    
    button.addSubview(imageView)
    imageView.frame = CGRect(
      x: (button.frame.width - indicatorSize) / 2,
      y: (button.frame.height - indicatorSize) / 2,
      width: indicatorSize,
      height: indicatorSize
    )
    
    // 날짜 텍스트를 앞으로 가져와 겹치지 않도록 함
    button.bringSubviewToFront(button.titleLabel!)
  }
  
  // MARK: - Setup
  private func setupUI() {
    // 컨텐츠 뷰 설정
    contentView.clipsToBounds = false
    
    // 그림자 효과 추가
    contentView.layer.shadowColor = UIColor.black.cgColor
    contentView.layer.shadowOpacity = 0.2
    contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
    contentView.layer.shadowRadius = 5
    
    // ✅ 수정: 카드 간 마진 조정을 위한 컨텐츠 뷰 내부 마진 설정
    let horizontalMargin: CGFloat = 20  // 좌우 마진
    
    // Card View (전면)
    contentView.addSubview(containerView)
    containerView.addSubview(backgroundImageView)
    containerView.addSubview(monthLabel)
    containerView.addSubview(pageInfoLabel)
    containerView.addSubview(optionsButton)
    
    // Calendar View (후면)
    contentView.addSubview(calendarContainerView)
    calendarContainerView.addSubview(calendarMonthLabel)
    calendarContainerView.addSubview(calendarView)
    calendarView.addSubview(daysStackView)
    calendarView.addSubview(calendarGridView)
    calendarContainerView.addSubview(messageLabel)
    
    // ✅ 수정: 좌우 마진 추가
    containerView.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.leading.equalToSuperview().offset(horizontalMargin)
      make.trailing.equalToSuperview().offset(-horizontalMargin)
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
    
    // ✅ 수정: 캘린더 뷰 좌우 마진 추가
    calendarContainerView.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.leading.equalToSuperview().offset(horizontalMargin)
      make.trailing.equalToSuperview().offset(-horizontalMargin)
    }
    
    let isSmallScreen = UIScreen.main.bounds.height <= 667 // iPhone SE, iPhone 8
    
    calendarMonthLabel.snp.makeConstraints { make in
      if isSmallScreen {
        make.top.equalToSuperview().offset(DesignSystem.Layout.smallMargin)
      } else {
        make.top.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
      }
      make.centerX.equalToSuperview()
      make.height.equalTo(30)
      make.width.greaterThanOrEqualTo(60) // 최소 너비 설정
    }
    
    calendarView.snp.makeConstraints { make in
      if isSmallScreen {
        make.top.equalTo(calendarMonthLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin/2)
      } else {
        make.top.equalTo(calendarMonthLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
      }
      make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
      make.height.equalTo(isSmallScreen ? 250 : 300)
    }
    
    daysStackView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.height.equalTo(30)
    }
    
    calendarGridView.snp.makeConstraints { make in
      make.top.equalTo(daysStackView.snp.bottom).offset(DesignSystem.Layout.smallMargin/2)
      make.leading.trailing.bottom.equalToSuperview()
    }
    
    messageLabel.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
      make.centerX.equalToSuperview()
      make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
    }
    
    // 초기 설정 - 캘린더 뷰는 숨김
    calendarContainerView.isHidden = true
    createCalendarUI()
  }
  
  // MARK: - Configuration
  func configure(forMonth month: Int, year: Int = Calendar.current.component(.year, from: Date()), dayCardData: [Int: DayCard] = [:]) {
      // 셀 태그 설정 (검색용)
      self.tag = month
      
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
          calendarMonthLabel.text = monthNames[month - 1]
          monthLabel.layoutIfNeeded()
          calendarMonthLabel.layoutIfNeeded()
      }
      
      // Set page info
      let totalDaysInMonth = daysInMonth(month: month, year: year)
      pageInfoLabel.text = "1 / \(totalDaysInMonth)"
      
      // 월별 고정 색상 설정
      setMonthColor(month: month)
      
      // 디버그 로그
      print("월 셀 구성 완료: \(year)년 \(month)월, 태그: \(self.tag), 상태: \(isFlipped ? "캘린더" : "카드")")
      
      // 배경 이미지 로드
      loadMonthBackgroundImage(month: month)
      
      // 캘린더 그리드 업데이트 (플립 상태인 경우만)
    createCalendarGrid(with: dayCardData)
      
  }
  
  // 월별로 다른 색상 적용
  private func setMonthColor(month: Int) {
    // 월별 고정 색상 설정 // 추후 이미지 없을때 사용자가 배경 고를 수 있도록
    let colors = [
      UIColor(hex: "D9D9D9"), // 1월 - 주황
      UIColor(hex: "D9D9D9"), // 2월 - 빨강
      UIColor(hex: "D9D9D9"), // 3월 - 보라
      UIColor(hex: "D9D9D9"), // 4월 - 파랑
      UIColor(hex: "D9D9D9"), // 5월 - 민트
      UIColor(hex: "D9D9D9"), // 6월 - 초록
      UIColor(hex: "D9D9D9"), // 7월 - 노랑
      UIColor(hex: "D9D9D9"), // 8월 - 주황
      UIColor(hex: "D9D9D9"), // 9월 - 빨강
      UIColor(hex: "D9D9D9"), // 10월 - 보라
      UIColor(hex: "D9D9D9"), // 11월 - 파랑
      UIColor(hex: "D9D9D9")  // 12월 - 초록
    ]
    
    if month >= 1 && month <= 12 {
      containerView.backgroundColor = colors[month - 1]
    } else {
      containerView.backgroundColor = DesignSystem.Color.Background.card.inUIColor()
    }
  }
  
  @objc private func dayButtonTapped(_ sender: UIButton) {
          let day = sender.tag
          print("Day \(day) selected in \(month)월 \(year)년")
          
          // 날짜 선택 이벤트 방출
          dateTapped.onNext((year: year, month: month, day: day))
      }
  
  // MARK: - Calendar UI Creation
  private func createCalendarUI() {
    
    daysStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    
    // Add day labels (일, 월, 화, 수, 목, 금, 토)
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    for (index, day) in days.enumerated() {
      let label = UILabel()
      label.text = day
      label.textAlignment = .center
      label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
      
      // 일요일과 토요일에 색상 적용
      switch index {
      case 0: // 일요일
        label.textColor = UIColor(hex: "F44336") // 붉은색
      case 6: // 토요일
        label.textColor = UIColor(hex: "42A5F5") // 푸른색
      default:
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
      }
      
      daysStackView.addArrangedSubview(label)
    }
  }
  
  func createCalendarGrid(with dayCardData: [Int: DayCard] = [:]) {
      // 그리드 변경 전에 확인
//      if calendarGridView.bounds.width <= 0 {
//          // 레이아웃이 아직 계산되지 않았으므로 지연 실행
//          DispatchQueue.main.async { [weak self] in
//              self?.createCalendarGrid(with: dayCardData)
//          }
//          return
//      }
      
      // Remove previous calendar grid
//      for subview in calendarGridView.subviews {
//          subview.removeFromSuperview()
//      }
      
      // 년도와 월 설정
      let calendar = Calendar.current
      
      // Get first day of month and number of days
      var components = DateComponents()
      components.year = year
      components.month = month
      components.day = 1
      
      guard let firstDayOfMonth = calendar.date(from: components) else { return }
      
      // 첫 번째 요일 (1: 일요일, 2: 월요일, ..., 7: 토요일)
      let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
      let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
      
      let isSmallScreen = UIScreen.main.bounds.height <= 667 // iPhone SE, iPhone 8
      
      // 그리드 생성을 위한 크기 계산
      let gridWidth = calendarGridView.bounds.width
      let buttonWidth = gridWidth / 7.0
      let buttonHeight = isSmallScreen ? buttonWidth * 0.9 : buttonWidth
      
      // 첫 번째 요일 조정 (0-based: 0 = 일요일, ..., 6 = 토요일)
      let firstWeekdayIndex = firstWeekday - 1
      
      // 각 날짜별 버튼 생성
      for day in 1...numberOfDaysInMonth {
          // 요일 계산 (0: 일요일, 1: 월요일, ..., 6: 토요일)
          let components = DateComponents(year: year, month: month, day: day)
          guard let date = calendar.date(from: components) else { continue }
          let weekday = calendar.component(.weekday, from: date) - 1 // 0-based for array indexing
          
          // 주차 계산 (0: 첫째 주, 1: 둘째 주, ...)
          let weekOfMonth = (day + firstWeekdayIndex - 1) / 7
          
          // 버튼 생성
          let dayButton = createDayButton(day: day, weekday: weekday)
          
          // 버튼 위치 계산
          let xPosition = CGFloat(weekday) * buttonWidth
          let yPosition = CGFloat(weekOfMonth) * buttonHeight
          
          // 버튼 크기 설정
          dayButton.frame = CGRect(
              x: xPosition,
              y: yPosition,
              width: buttonWidth,
              height: buttonHeight
          )
          
          // 그리드에 추가
          calendarGridView.addSubview(dayButton)
          
          // 오늘 날짜에 검정 바 추가
          if day == Calendar.current.component(.day, from: Date()) &&
             month == Calendar.current.component(.month, from: Date()) &&
             year == Calendar.current.component(.year, from: Date()) {
              addTodayIndicator(to: dayButton)
          }
          
          // 일기 이미지 표시
        if let dayCard = dayCardData[day], !dayCard.imageRecords.isEmpty,
               let imageRecord = dayCard.imageRecords.first,
               let thumbnailPath = imageRecord.thumbnailImagePath {
                addImageIndicator(to: dayButton, imagePath: thumbnailPath)
            }
          
          // 증상 표시
          if let hasSymptom = symptomsData[day], hasSymptom {
              addSymptomIndicator(to: dayButton)
          }
      }
  }
  
  
  private func createDayButton(day: Int, weekday: Int) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(String(day), for: .normal)
    
    let isSmallScreen = UIScreen.main.bounds.height <= 667
    button.titleLabel?.font = DesignSystem.Font.Weight.regular(
      size: isSmallScreen ? DesignSystem.Font.Size.small : DesignSystem.Font.Size.medium
    )
    
    // 일요일(0)이면 빨간색, 토요일(6)이면 파란색
    if weekday == 0 {
      button.setTitleColor(UIColor(hex: "F44336"), for: .normal) // 붉은색
    } else if weekday == 6 {
      button.setTitleColor(UIColor(hex: "42A5F5"), for: .normal) // 푸른색
    } else {
      button.setTitleColor(DesignSystem.Color.Tint.darkGray.inUIColor(), for: .normal)
    }
    
    button.tag = day
    button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
    return button
  }
  
  private func addTodayIndicator(to button: UIButton) {
    let indicatorHeight: CGFloat = 2
    let indicatorWidth: CGFloat = button.frame.width * 0.6
    
    let indicator = UIView()
    indicator.backgroundColor = DesignSystem.Color.Tint.text.inUIColor() // 검정색
    
    button.addSubview(indicator)
    
    indicator.frame = CGRect(
      x: (button.frame.width - indicatorWidth) / 2,
      y: button.frame.height - indicatorHeight - 2, // 하단에서 약간 위
      width: indicatorWidth,
      height: indicatorHeight
    )
  }
  
  private func addSymptomIndicator(to button: UIButton) {
    let isSmallScreen = UIScreen.main.bounds.height <= 667
    let indicatorSize: CGFloat = isSmallScreen ? 16 : 20
    
    let indicator = UIView()
    indicator.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
    indicator.layer.cornerRadius = indicatorSize / 2
    
    button.addSubview(indicator)
    indicator.center = CGPoint(x: button.frame.width / 2, y: button.frame.height / 2)
    indicator.frame.size = CGSize(width: indicatorSize, height: indicatorSize)
    
    // Bring the text to front
    button.bringSubviewToFront(button.titleLabel!)
  }
  
  // MARK: - Flipping Methods
  func flipToCalendar(animated: Bool = true) {
    // 이미 뒤집힌 상태면 그리드만 업데이트하고 종료
    if isFlipped {
      createCalendarGrid()
      return
    }
    
    if animated {
      // 더 뚜렷한 애니메이션 효과를 위해 속성 조정
      UIView.transition(
        with: self.contentView,
        duration: 0.4,
        options: [.transitionFlipFromLeft, .allowUserInteraction],
        animations: {
          self.containerView.isHidden = true
          self.calendarContainerView.isHidden = false
        },
        completion: { _ in
          self.isFlipped = true
          self.createCalendarGrid() // 그리드 다시 생성
          print("CardCell: \(self.month)월 카드 뒤집기 애니메이션 완료")
        }
      )
    } else {
      // 애니메이션 없이 즉시 상태 변경
      containerView.isHidden = true
      calendarContainerView.isHidden = false
      isFlipped = true
      createCalendarGrid()
    }
    
    // 디버그 로그
    if animated {
      print("CardCell: \(month)월 카드를 캘린더로 플립 시작 (태그: \(self.tag))")
    }
  }
  
  // 뒤로 플립 애니메이션 개선
  func flipToCard(animated: Bool = true) {
    // 이미 카드 상태면 무시
    if !isFlipped {
      return
    }
    
    if animated {
      UIView.transition(
        with: self.contentView,
        duration: 0.4,
        options: [.transitionFlipFromRight, .allowUserInteraction],
        animations: {
          self.calendarContainerView.isHidden = true
          self.containerView.isHidden = false
        },
        completion: { _ in
          self.isFlipped = false
          print("CardCell: \(self.month)월 카드 되돌리기 애니메이션 완료")
        }
      )
    } else {
      // 애니메이션 없이 즉시 상태 변경
      calendarContainerView.isHidden = true
      containerView.isHidden = false
      isFlipped = false
    }
    
    // 디버그 로그
    if animated {
      print("CardCell: \(month)월 카드를 원래대로 되돌리기 시작 (태그: \(self.tag))")
    }
  }
  // MARK: - Helper Methods
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
  
  private func loadMonthBackgroundImage(month: Int) {
    // 실제 앱에서는 월별 이미지를 로드
    // 현재는 플레이스홀더 사용
    backgroundImageView.image = UIImage(named: "placeholder_image")
  }
  
  // MARK: - Public Methods
  func updateSymptomView(isShowing: Bool) {
    // 애니메이션 없이 텍스트 즉시 변경
    UIView.performWithoutAnimation {
      if isShowing {
        messageLabel.text = "선택한 날짜의 증상 사진을 조회할 수 있습니다"
      } else {
        messageLabel.text = "날짜를 선택해 일기를 작성해세요."
      }
      messageLabel.setNeedsDisplay()
      messageLabel.layoutIfNeeded()
    }
    
    if isShowing {
      updateCalendarWithSymptoms()
    } else {
      resetCalendarSymptoms()
    }
  }
  
  private func updateCalendarWithSymptoms() {
    // Sample data - this would come from your ViewModel
    symptomsData = [5: true, 18: true, 24: true]
    createCalendarGrid()
  }
  
  private func resetCalendarSymptoms() {
    // Clear symptom data
    symptomsData.removeAll()
    createCalendarGrid()
  }
}
