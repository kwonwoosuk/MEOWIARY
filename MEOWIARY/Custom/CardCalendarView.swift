//
//  CardCalendarView.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class CardCalendarView: BaseView {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var isCalendarMode = false
    private var currentYear = Calendar.current.component(.year, from: Date())
    private var currentMonth = Calendar.current.component(.month, from: Date())
    private var currentDay = Calendar.current.component(.day, from: Date())
    private var symptomsData: [Int: Bool] = [:]  // Dictionary to track days with symptoms
    
    // MARK: - UI Components
    private let cardCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        return collectionView
    }()
    
    private let calendarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = DesignSystem.Layout.largeCornerRadius
        view.isHidden = true
        return view
    }()
    
    let monthLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
        label.textAlignment = .center
        label.text = "3월"
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
    
    let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        pageControl.numberOfPages = 12
        return pageControl
    }()
    
    // MARK: - Configuration
    override func configureHierarchy() {
        addSubview(cardCollectionView)
        addSubview(calendarContainerView)
        calendarContainerView.addSubview(monthLabel)
        calendarContainerView.addSubview(calendarView)
        calendarView.addSubview(daysStackView)
        calendarView.addSubview(calendarGridView)
        calendarContainerView.addSubview(messageLabel)
        addSubview(pageControl)
    }
    
    override func configureLayout() {
        let isSmallScreen = UIScreen.main.bounds.height <= 667 // iPhone SE, iPhone 8
        
        cardCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        calendarContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
            if isSmallScreen {
                make.height.equalTo(calendarContainerView.snp.width).multipliedBy(1.2)
            } else {
                make.height.equalTo(calendarContainerView.snp.width).multipliedBy(1.4)
            }
        }
        
        monthLabel.snp.makeConstraints { make in
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
                make.top.equalTo(monthLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin/2)
            } else {
                make.top.equalTo(monthLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
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
        
        pageControl.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-DesignSystem.Layout.smallMargin)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }
    }
    
    override func configureView() {
        setupCollectionView()
        createCalendarUI()
    }
    
    private func setupCollectionView() {
        cardCollectionView.register(CardCell.self, forCellWithReuseIdentifier: "CardCell")
        cardCollectionView.delegate = self
        cardCollectionView.dataSource = self
        
        // 초기 스크롤 위치를 메인 스레드에서 설정
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let currentMonth = Calendar.current.component(.month, from: Date()) - 1
            
            if currentMonth >= 0 && currentMonth < 12 {
                self.cardCollectionView.scrollToItem(
                    at: IndexPath(item: currentMonth, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
                self.pageControl.currentPage = currentMonth
            }
            
            // 현재 월이 화면에 표시되도록
            self.updateMonth(month: currentMonth + 1)
        }
    }
    
    // MARK: - Calendar UI Creation
    private func createCalendarUI() {
        // 기존 day 라벨 제거
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
        
        // Create calendar grid
        createCalendarGrid()
    }
    
    private func createCalendarGrid() {
        // 그리드 변경 전에 확인
        if calendarGridView.bounds.width <= 0 {
            // 레이아웃이 아직 계산되지 않았으므로 지연 실행
            DispatchQueue.main.async { [weak self] in
                self?.createCalendarGrid()
            }
            return
        }
        
        // Remove previous calendar grid
        for subview in calendarGridView.subviews {
            subview.removeFromSuperview()
        }
        
        // 년도와 월 설정
        let calendar = Calendar.current
        
        // Get first day of month and number of days
        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
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
        
        // 각 날짜별 버튼 생성
        for day in 1...numberOfDaysInMonth {
            // 요일 계산 (0: 일요일, 1: 월요일, ..., 6: 토요일)
            let components = DateComponents(year: currentYear, month: currentMonth, day: day)
            guard let date = calendar.date(from: components) else { continue }
            let weekday = calendar.component(.weekday, from: date) - 1 // 0-based for array indexing
            
            // 주차 계산 (0: 첫째 주, 1: 둘째 주, ...)
            let weekOfMonth = calendar.component(.weekOfMonth, from: date) - 1
            
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
            if day == currentDay &&
               currentMonth == Calendar.current.component(.month, from: Date()) &&
               currentYear == Calendar.current.component(.year, from: Date()) {
                addTodayIndicator(to: dayButton)
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
        // 현재 날짜 강조 표시
        button.layer.borderWidth = 2
        button.layer.borderColor = DesignSystem.Color.Tint.text.inUIColor().cgColor
        
        // 검정 바 추가
        let indicatorHeight: CGFloat = 2
        let indicatorWidth: CGFloat = button.frame.width * 0.6
        
        let indicator = UIView()
        indicator.backgroundColor = DesignSystem.Color.Tint.text.inUIColor() // 검정색
        
        button.addSubview(indicator)
        
        // 검정 바 위치 (날짜 아래)
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
    
    // MARK: - Actions
    @objc private func dayButtonTapped(_ sender: UIButton) {
        // Handle day selection
        print("Day \(sender.tag) selected")
    }
    
    // MARK: - Public Methods
    
    // 레이아웃이 완료된 후 호출하여 UI 강제 업데이트
    func forceUpdateLayout() {
        // 월 레이블 텍스트 설정
        monthLabel.text = "\(currentMonth)월"
        
        // 컬렉션뷰 데이터 리로드 및 현재 월로 스크롤
        cardCollectionView.reloadData()
        
        if !isCalendarMode {
            let currentMonthIndex = currentMonth - 1
            if currentMonthIndex >= 0 && currentMonthIndex < 12 {
                cardCollectionView.scrollToItem(
                    at: IndexPath(item: currentMonthIndex, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
                pageControl.currentPage = currentMonthIndex
            }
        }
        
        // 캘린더 그리드 재생성
        createCalendarGrid()
        
        // 레이아웃 갱신
        layoutIfNeeded()
        
        print("CardCalendarView: 강제 레이아웃 업데이트 완료")
    }
    
    func flipToCalendar() {
        // 현재 컬렉션뷰의 페이지 인덱스 기반으로 월 가져오기
        let visibleCells = cardCollectionView.visibleCells
        if let firstCell = visibleCells.first,
           let indexPath = cardCollectionView.indexPath(for: firstCell) {
            currentMonth = indexPath.item + 1
        }
        
        // 플립하기 전에 월 레이블이 보이도록 설정
        monthLabel.text = "\(currentMonth)월"
        monthLabel.setNeedsDisplay()
        
        // 화면 크기를 고려한 애니메이션 적용
        let isSmallScreen = UIScreen.main.bounds.height <= 667 // iPhone SE, iPhone 8 크기 기준
        
        // 작은 화면에서는 위치 조정을 위한 추가 처리
        if isSmallScreen {
            // 캘린더 컨테이너 뷰의 위치 조정
            calendarContainerView.snp.updateConstraints { make in
                make.width.equalToSuperview().multipliedBy(0.85)
                make.height.equalTo(calendarContainerView.snp.width).multipliedBy(1.2) // 높이 비율 축소
            }
            
            // 월 라벨 위치 조정
            monthLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(DesignSystem.Layout.smallMargin) // 상단 여백 축소
            }
            
            // 캘린더 그리드 위치 조정
            calendarView.snp.updateConstraints { make in
                make.top.equalTo(monthLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin/2)
                make.height.equalTo(250) // 작은 화면용 높이 조정
            }
        }
        
        // 플립 애니메이션 적용
        UIView.transition(with: self, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            self.cardCollectionView.isHidden = true
            self.calendarContainerView.isHidden = false
            self.pageControl.isHidden = true
        }, completion: { _ in
            self.isCalendarMode = true
            self.createCalendarGrid() // 그리드 다시 생성
            self.layoutIfNeeded() // 레이아웃 즉시 적용
        })
    }

    func flipToCard() {
        // 플립 애니메이션 적용
        UIView.transition(with: self, duration: 0.5, options: .transitionFlipFromRight, animations: {
            self.calendarContainerView.isHidden = true
            self.cardCollectionView.isHidden = false
            self.pageControl.isHidden = false
        }, completion: { _ in
            self.isCalendarMode = false
            
            // 캘린더 모드에서 선택된 월로 스크롤
            let targetMonthIndex = self.currentMonth - 1
            if targetMonthIndex >= 0 && targetMonthIndex < 12 {
                self.cardCollectionView.scrollToItem(
                    at: IndexPath(item: targetMonthIndex, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
                self.pageControl.currentPage = targetMonthIndex
            }
            
            let isSmallScreen = UIScreen.main.bounds.height <= 667
            
            // 다시 원래 크기로 복구
            self.calendarContainerView.snp.updateConstraints { make in
                make.width.equalToSuperview().multipliedBy(0.85)
                if isSmallScreen {
                    make.height.equalTo(self.calendarContainerView.snp.width).multipliedBy(1.2)
                } else {
                    make.height.equalTo(self.calendarContainerView.snp.width).multipliedBy(1.4)
                }
            }
            
            self.monthLabel.snp.updateConstraints { make in
                if isSmallScreen {
                    make.top.equalToSuperview().offset(DesignSystem.Layout.smallMargin)
                } else {
                    make.top.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
                }
            }
            
            self.calendarView.snp.updateConstraints { make in
                if isSmallScreen {
                    make.top.equalTo(self.monthLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin/2)
                    make.height.equalTo(250)
                } else {
                    make.top.equalTo(self.monthLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
                    make.height.equalTo(300)
                }
            }
            
            self.layoutIfNeeded() // 레이아웃 즉시 적용
        })
    }

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
    
    func updateMonth(month: Int) {
        // 명시적으로 텍스트를 업데이트하고 레이아웃 새로고침
        UIView.performWithoutAnimation {
            monthLabel.text = "\(month)월"
            monthLabel.setNeedsDisplay()
            monthLabel.layoutIfNeeded()
        }
        
        print("CardCalendarView - 월 레이블 업데이트: \(month)월")
        
        // Update calendar grid for the new month
        createCalendarGrid()
    }
    
    func updateYear(year: String) {
        print("CardCalendarView - 연도 업데이트: \(year)")
        
        // Update calendar grid for the new year
        createCalendarGrid()
    }
    
    // MARK: - Private Helper Methods
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
    
    // 뷰 크기가 변경된 후 레이아웃 조정
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 이미 레이아웃이 계산된 후에만 그리드 생성
        if calendarGridView.bounds.width > 0 && !calendarGridView.subviews.isEmpty {
            createCalendarGrid()
        }
    }
}

// MARK: - CardCalendarView Collection View Extensions
extension CardCalendarView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12 // 12 months
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as? CardCell else {
            return UICollectionViewCell()
        }
        
        // 셀 구성
        cell.configure(forMonth: indexPath.item + 1)
        
        // 디버깅용 로그
        print("CardCalendarView - 셀 구성: 월 \(indexPath.item + 1)")
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Make cells fill the collection view with some padding
        let width = collectionView.frame.width - 40
        let height = collectionView.frame.height - 40
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Center cells in the collection view
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Update page control when scrolling ends
        let pageWidth = scrollView.frame.width
        let currentPage = Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        pageControl.currentPage = currentPage
        
        // 디버깅 로그
        print("CardCalendarView - 스크롤 완료: 페이지 \(currentPage + 1)")
    }
}
