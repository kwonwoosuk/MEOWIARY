//
//  HomeViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RealmSwift

final class HomeViewController: BaseViewController {
    
    // MARK: - Properties
    private let viewModel = HomeViewModel()
    private let disposeBag = DisposeBag()
    private let dayCardRepository = DayCardRepository()
    private var isFirstLoad = true
    // MARK: - UI Components
    private let navigationBarView = NavigationBarView()
    
    private let yearSelector: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let prevYearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystem.Icon.Control.prevYear.toUIImage(), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        return button
    }()
    
    private let yearLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
        label.textAlignment = .center
        label.text = "2025"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.lineBreakMode = .byClipping
        return label
    }()
    
    private let nextYearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystem.Icon.Control.nextYear.toUIImage(), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        return button
    }()
    
    private let toggleViewButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
        button.setTitle("증상 기록 보기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
        return button
    }()
    
    private let cardCalendarView = CardCalendarView()
    
    private let bottomActionView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let calendarButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystem.Icon.Navigation.calendar.toUIImage(), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        button.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
        button.layer.cornerRadius = 6
        return button
    }()
    
    private let recent24hButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
        button.setTitle("근처 24시 병원찾기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystem.Icon.Navigation.back.toUIImage(), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        button.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
        button.layer.cornerRadius = 20
        button.isHidden = true
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HomeViewController: viewDidLoad 호출됨")
        print("navigationBarView 설정됨: \(navigationBarView)")
        isFirstLoad = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("HomeViewController: viewDidLayoutSubviews 호출됨, 뷰 크기: \(view.bounds)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 첫 로딩인 경우 특별 처리
            if self.isFirstLoad {
                self.cardCalendarView.forceUpdateLayout()
                
                if self.yearLabel.text?.isEmpty ?? true {
                    self.yearLabel.text = String(Calendar.current.component(.year, from: Date()))
                    self.yearLabel.layoutIfNeeded()
                    print("연도 레이블 보정: \(self.yearLabel.text ?? "nil")")
                }
                
                // 캘린더 모드 확인 및 버튼 상태 동기화
                if self.cardCalendarView.isCalendarMode {
                    self.calendarButton.isHidden = true
                    self.backButton.isHidden = false
                } else {
                    self.calendarButton.isHidden = false
                    self.backButton.isHidden = true
                }
                
                self.isFirstLoad = false
            }
        }
    }
    
    // MARK: - UI Setup
    override func configureHierarchy() {
        // Add subviews
        view.addSubview(navigationBarView)
        view.addSubview(yearSelector)
        yearSelector.addSubview(prevYearButton)
        yearSelector.addSubview(yearLabel)
        yearSelector.addSubview(nextYearButton)
        view.addSubview(toggleViewButton)
        view.addSubview(cardCalendarView)
        view.addSubview(bottomActionView)
        bottomActionView.addSubview(calendarButton)
        bottomActionView.addSubview(recent24hButton)
        bottomActionView.addSubview(backButton)
    }
    
    override func configureLayout() {
        let isSmallScreen = UIScreen.main.bounds.height <= 667
        
        navigationBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        yearSelector.snp.makeConstraints { make in
            make.top.equalTo(navigationBarView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.height.equalTo(40)
            make.width.equalTo(120) // 너비 증가
        }
        
        prevYearButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        yearLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.greaterThanOrEqualTo(60)
        }
        
        nextYearButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        toggleViewButton.snp.makeConstraints { make in
            make.top.equalTo(navigationBarView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.height.equalTo(40)
            make.width.equalTo(isSmallScreen ? 130 : 140)
        }
        
        cardCalendarView.snp.makeConstraints { make in
            make.top.equalTo(toggleViewButton.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomActionView.snp.top).offset(-DesignSystem.Layout.smallMargin)
        }
        
        bottomActionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        calendarButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        recent24hButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
            make.width.equalTo(isSmallScreen ? 150 : 160)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
    }
    
    // MARK: - Binding
    override func bind() {
        let viewDidLoadEvent = PublishSubject<Void>()
        let yearPrevTapEvent = PublishSubject<Void>()
        let yearNextTapEvent = PublishSubject<Void>()
        let toggleViewTapEvent = PublishSubject<Void>()
        
        
        recent24hButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let vc = HospitalSearchViewController()
                vc.modalPresentationStyle = .fullScreen
                self?.present(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        prevYearButton.rx.tap
            .bind(to: yearPrevTapEvent)
            .disposed(by: disposeBag)
        
        nextYearButton.rx.tap
            .bind(to: yearNextTapEvent)
            .disposed(by: disposeBag)
        
        toggleViewButton.rx.tap
              .bind(to: toggleViewTapEvent)
            .disposed(by: disposeBag)
        
        
        calendarButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.flipCardToCalendar()
            })
            .disposed(by: disposeBag)
        
        backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.flipCalendarToCard()
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(DayCardUpdatedNotification))
            .subscribe(onNext: { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let year = userInfo["year"] as? Int,
                      let month = userInfo["month"] as? Int else {
                    return
                }
                
                // CardCalendarView 데이터 갱신
                self.cardCalendarView.updateData(year: year, month: month)
                
                // 현재 모드 확인
                let isShowingSymptoms = self.viewModel.isShowingSymptomsSubject.value
                
                // 필요한 경우 현재 보이는 셀만 명시적으로 업데이트
                if let currentMonth = self.cardCalendarView.getCurrentMonth(),
                   self.viewModel.yearSubject.value == year &&
                   currentMonth == month {
                    if let cell = self.cardCalendarView.getCellForIndex(month - 1) {
                        let dayCardData = self.dayCardRepository.getDayCardsMapForMonth(year: year, month: month)
                        cell.createCalendarGrid(with: dayCardData)
                    }
                }
                
                // 증상 모드였다면 증상 데이터도 새로고침
                if isShowingSymptoms {
                    self.cardCalendarView.updateSymptomView(isShowing: true)
                }
                
                // 토스트 메시지로 사용자에게 알림
                if let symptomFlag = userInfo["isSymptom"] as? Bool, symptomFlag {
                    self.showToast(message: "증상 기록이 업데이트되었습니다")
                } else {
                    self.showToast(message: "일기가 업데이트되었습니다")
                }
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(DayCardDeletedNotification))
            .subscribe(onNext: { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let year = userInfo["year"] as? Int,
                      let month = userInfo["month"] as? Int,
                      let day = userInfo["day"] as? Int else {
                    return
                }
                
                // 이미지 캐시 먼저 제거 (경로 정보 직접 참조 없이)
                ImageManager.shared.clearAllImageCacheForMonth(year: year, month: month)
                
                // 안전하게 UI 업데이트 - 약간 지연시켜 Realm 작업이 완료되도록
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    
                    // CardCalendarView 데이터 갱신
                    self.cardCalendarView.updateData(year: year, month: month)
                    
                    // 현재 보이는 셀만 찾아서 명시적으로 안전하게 업데이트
                    if let currentMonth = self.cardCalendarView.getCurrentMonth() {
                        if let cell = self.cardCalendarView.getCellForIndex(currentMonth - 1) {
                            // 완전히 새로운 데이터를 준비
                            let dayCardData = self.dayCardRepository.getDayCardsMapForMonth(year: year, month: month)
                            
                            // 셀 초기화 후 데이터 갱신
                            DispatchQueue.main.async {
                                cell.prepareForReuse()
                                cell.createCalendarGrid(with: dayCardData)
                            }
                        }
                    }
                    
                    // 변경이 있었던 날짜의 월인 경우만 컬렉션뷰 갱신
                    if month == self.cardCalendarView.getCurrentMonth() {
                        DispatchQueue.main.async {
                            // 컬렉션뷰 갱신 (데이터 소스는 변경되지 않음)
                            self.cardCalendarView.refreshVisibleCells()
                        }
                    }
                    
                    // 증상 모드였다면 증상 데이터도 새로고침
                    if self.viewModel.isShowingSymptomsSubject.value {
                        self.cardCalendarView.updateSymptomView(isShowing: true)
                    }
                }
                
                // 토스트 메시지
                if let symptomFlag = userInfo["isSymptom"] as? Bool, symptomFlag {
                    self.showToast(message: "증상 기록이 삭제되었습니다")
                } else {
                    self.showToast(message: "일기가 삭제되었습니다")
                }
            })
            .disposed(by: disposeBag)
        
        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            yearNavPrev: yearPrevTapEvent.asObservable(),
            yearNavNext: yearNextTapEvent.asObservable(),
            toggleViewTap: toggleViewTapEvent.asObservable()
        )
        
        
        let output = viewModel.transform(input: input)
        
        
        output.currentYear
            .drive(onNext: { [weak self] year in
                guard let self = self else { return }
                
                UIView.performWithoutAnimation {
                    self.yearLabel.text = year
                    self.yearLabel.layoutIfNeeded()
                }
                print("연도 레이블 업데이트: \(year)")
                
                if let yearInt = Int(year) {
                    self.cardCalendarView.updateYear(year: year)
                }
            })
            .disposed(by: disposeBag)
        
        
        output.toggleButtonStyle
            .drive(onNext: { [weak self] style in
                guard let self = self else { return }
                
                
                UIView.performWithoutAnimation {
                    self.toggleViewButton.setTitle(style.title, for: .normal)
                    self.toggleViewButton.backgroundColor = style.backgroundColor
                    self.toggleViewButton.setTitleColor(style.titleColor, for: .normal)
                    self.toggleViewButton.layer.borderWidth = style.borderWidth
                    if let borderColor = style.borderColor {
                        self.toggleViewButton.layer.borderColor = borderColor
                    }
                    self.toggleViewButton.layoutIfNeeded()
                }
                
                
            })
            .disposed(by: disposeBag)
        
        output.weatherInfo
            .drive(onNext: { [weak self] weather in
                if let weather = weather {
                    let temperature = Int(weather.temperature.rounded())
                    self?.navigationBarView.updateWeather(temperature: temperature, condition: weather.condition)
                }
            })
            .disposed(by: disposeBag)
        
        output.isShowingSymptoms
            .drive(cardCalendarView.rx.isShowingSymptoms)
            .disposed(by: disposeBag)
        
        output.currentMonth
            .drive(cardCalendarView.rx.currentMonth)
            .disposed(by: disposeBag)
        
        output.currentYear
            .drive(cardCalendarView.rx.currentYear)
            .disposed(by: disposeBag)
        
        cardCalendarView.dateSelected
            .subscribe(onNext: { [weak self] (year, month, day) in
                guard let self = self else { return }
                
                let isShowingSymptoms = self.viewModel.isShowingSymptomsSubject.value
                
                // 해당 날짜의 DayCard 조회
                let dayCard = self.dayCardRepository.getDayCardForDate(year: year, month: month, day: day)
                
                if isShowingSymptoms {
                    // 증상 모드일 때
                    let symptoms = dayCard?.symptoms.map { $0 } ?? []
                    
                    if !symptoms.isEmpty {
                        // 증상 기록이 있으면 SymptomDetailViewController로 이동
                        let detailVC = SymptomDetailViewController(year: year, month: month, day: day, imageManager: ImageManager.shared)
                        detailVC.modalPresentationStyle = .fullScreen
                        detailVC.onDelete = { [weak self] in
                            // 삭제 후 화면 갱신
                            Task {
                                await self?.viewModel.fetchData()
                            }
                        }
                        self.present(detailVC, animated: true)
                    } else {
                        // 증상 기록이 없으면 새 증상 기록 화면으로 이동
                        let recordVC = SymptomRecordViewController(year: year, month: month, day: day)
                        recordVC.modalPresentationStyle = .fullScreen
                        self.present(recordVC, animated: true)
                    }
                } else {
                    // 일상 기록 모드일 때 - 이제 증상 기록이 있더라도 일상 기록 화면 표시
                    if let dayCard = dayCard, !dayCard.imageRecords.isEmpty {
                        // 일상 기록 이미지가 있으면 상세 화면으로 이동
                        let detailVC = DetailViewController(year: year, month: month, day: day, imageManager: ImageManager.shared)
                        detailVC.modalPresentationStyle = .fullScreen
                        self.present(detailVC, animated: true)
                    } else {
                        // 일상 기록이 없으면 새 기록 화면으로 이동
                        let diaryVC = DailyDiaryViewController(year: year, month: month, day: day)
                        diaryVC.modalPresentationStyle = .fullScreen
                        self.present(diaryVC, animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func flipCardToCalendar() {
        // 월 선택이 정확하도록 카드뷰에 현재 월 정보 전달
        let currentMonth = Calendar.current.component(.month, from: Date())
        cardCalendarView.updateMonth(month: currentMonth)
        
        // 먼저 애니메이션 시작
        cardCalendarView.flipAllToCalendar()
        
        // 애니메이션 도중(약간의 지연 시간)에 버튼 상태 변경
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.2) {
                self.calendarButton.isHidden = true
                self.backButton.isHidden = false
                self.view.layoutIfNeeded()
            }
        }
        
        // 데이터 갱신 - 애니메이션 완료 후 호출
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            
            // 데이터 갱신 명시적으로 재호출
            if let currentMonth = self.cardCalendarView.getCurrentMonth() {
                self.cardCalendarView.updateData(year: self.viewModel.yearSubject.value, month: currentMonth)
            }
        }
        
        print("HomeViewController: 모든 카드를 캘린더로 플립 (애니메이션 적용)")
    }
    
    // 모든 메서드에서 적용할 수 있도록 수정
    // HomeViewController.swift의 flipCalendarToCard() 메서드 수정
    private func flipCalendarToCard() {
        // 애니메이션 적용 전에 상태 저장
        let isCalendarMode = cardCalendarView.isCalendarMode
        
        // 애니메이션이 완료된 후 버튼 상태를 변경하도록 수정
        cardCalendarView.flipAllToCard()
        
        // 애니메이션 완료 후(약간의 지연 시간) 버튼 상태 변경
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.2) {
                self.calendarButton.isHidden = false
                self.backButton.isHidden = true
                self.view.layoutIfNeeded()
            }
        }
        
        print("HomeViewController: 모든 카드를 원래대로 돌림 (애니메이션 적용)")
    }
    
    
    private func scrollToCurrentMonth() {
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        cardCalendarView.updateMonth(month: currentMonth)
        
        
        print("HomeViewController: 현재 월(\(currentMonth)월)로 스크롤")
    }
    
    
}


extension Reactive where Base: CardCalendarView {
    var isShowingSymptoms: Binder<Bool> {
        return Binder(self.base) { view, isShowing in
            view.updateSymptomView(isShowing: isShowing)
        }
    }
    
    var currentMonth: Binder<Int> {
        return Binder(self.base) { view, month in
            view.updateMonth(month: month)
        }
    }
    
    var currentYear: Binder<String> {
        return Binder(self.base) { view, year in
            view.updateYear(year: year)
        }
    }
}
