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

final class HomeViewController: BaseViewController {
    
    // MARK: - Properties
    private let viewModel = HomeViewModel()
    private let disposeBag = DisposeBag()
    
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
        
        // 확실하게 년도 표시
        yearLabel.text = String(Calendar.current.component(.year, from: Date()))
        print("연도 레이블 초기값 설정: \(yearLabel.text ?? "nil")")
    }
    
    // 뷰가 나타날 때 현재 월로 스크롤 - viewDidAppear 수정
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 뷰가 나타난 후 카드/캘린더 상태 갱신
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 카드컬렉션뷰 레이아웃 강제 갱신
            self.cardCalendarView.forceUpdateLayout()
            
            // 연도 레이블 확인 및 업데이트
            if self.yearLabel.text?.isEmpty ?? true {
                self.yearLabel.text = String(Calendar.current.component(.year, from: Date()))
                self.yearLabel.layoutIfNeeded()
                print("연도 레이블 보정: \(self.yearLabel.text ?? "nil")")
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
        // 디바이스 크기 확인 (iPhone SE 대응)
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
            make.width.greaterThanOrEqualTo(60) // 최소 너비 설정
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
            make.width.equalTo(isSmallScreen ? 130 : 140) // 작은 화면에서 버튼 크기 조정
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
            make.width.equalTo(isSmallScreen ? 150 : 160) // 작은 화면에서 버튼 크기 조정
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        
       
    }
    
    // MARK: - Binding
    override func bind() {
        // ViewModel 입력 정의를 위한 Subject/Relay 생성
        let viewDidLoadEvent = PublishSubject<Void>()
        let yearPrevTapEvent = PublishSubject<Void>()
        let yearNextTapEvent = PublishSubject<Void>()
        let toggleViewTapEvent = PublishSubject<Void>()
        
        // 버튼 액션 바인딩
        prevYearButton.rx.tap
            .bind(to: yearPrevTapEvent)
            .disposed(by: disposeBag)
        
        nextYearButton.rx.tap
            .bind(to: yearNextTapEvent)
            .disposed(by: disposeBag)
        
        toggleViewButton.rx.tap
            .bind(to: toggleViewTapEvent)
            .disposed(by: disposeBag)
        
        // 추가적인 UI 이벤트 바인딩
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
        
        // ViewModel Input 생성
        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            yearNavPrev: yearPrevTapEvent.asObservable(),
            yearNavNext: yearNextTapEvent.asObservable(),
            toggleViewTap: toggleViewTapEvent.asObservable()
        )
        
        // ViewModel Output 가져오기
        let output = viewModel.transform(input: input)
        
        // Output 바인딩 (애니메이션 없이 즉시 적용)
        output.currentYear
            .drive(onNext: { [weak self] year in
                guard let self = self else { return }
                // 명시적으로 텍스트 설정 및 레이아웃 갱신
                UIView.performWithoutAnimation {
                    self.yearLabel.text = year
                    self.yearLabel.layoutIfNeeded()
                }
                print("연도 레이블 업데이트: \(year)")
                
                // CardCalendarView에도 년도 전달
                if let yearInt = Int(year) {
                    self.cardCalendarView.updateYear(year: year)
                }
            })
            .disposed(by: disposeBag)
        
        // 텍스트 변경을 애니메이션 없이 즉시 적용하기 위한 처리
        output.toggleButtonStyle
            .drive(onNext: { [weak self] style in
                guard let self = self else { return }
                
                // 애니메이션 없이 즉시 적용
                UIView.performWithoutAnimation {
                    self.toggleViewButton.setTitle(style.title, for: .normal)
                    self.toggleViewButton.backgroundColor = style.backgroundColor
                    self.toggleViewButton.setTitleColor(style.titleColor, for: .normal)
                    self.toggleViewButton.layer.borderWidth = style.borderWidth
                    if let borderColor = style.borderColor {
                        self.toggleViewButton.layer.borderColor = borderColor
                    }
                    // 레이아웃 즉시 갱신
                    self.toggleViewButton.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        // 증상 보기 상태 업데이트 (애니메이션 없이 즉시 적용)
        output.isShowingSymptoms
            .drive(cardCalendarView.rx.isShowingSymptoms)
            .disposed(by: disposeBag)
            
        output.currentMonth
            .drive(cardCalendarView.rx.currentMonth)
            .disposed(by: disposeBag)
            
        output.currentYear
            .drive(cardCalendarView.rx.currentYear)
            .disposed(by: disposeBag)
    }
    
    private func flipCardToCalendar() {
        // 월 선택이 정확하도록 카드뷰에 현재 월 정보 전달
        let currentMonth = Calendar.current.component(.month, from: Date())
        cardCalendarView.updateMonth(month: currentMonth)
        
        // 카드 뒤집기 실행
        cardCalendarView.flipToCalendar()
        
        // 애니메이션 없이 버튼 상태 변경
        UIView.performWithoutAnimation {
            calendarButton.isHidden = true
            backButton.isHidden = false
            self.view.layoutIfNeeded()
        }
        
        // 디버그 로그
        print("HomeViewController: 카드에서 캘린더로 플립")
    }

    private func flipCalendarToCard() {
        // 카드 상태로 되돌리기
        cardCalendarView.flipToCard()
        
        // 애니메이션 없이 버튼 상태 변경
        UIView.performWithoutAnimation {
            calendarButton.isHidden = false
            backButton.isHidden = true
            self.view.layoutIfNeeded()
        }
        
        // 디버그 로그
        print("HomeViewController: 캘린더에서 카드로 플립")
    }

    // 선택된 월 카드로 스크롤 하기 위한 메서드 추가
    private func scrollToCurrentMonth() {
        // 현재 월로 스크롤
        let currentMonth = Calendar.current.component(.month, from: Date())
        cardCalendarView.updateMonth(month: currentMonth)
        
        // 디버그 로그
        print("HomeViewController: 현재 월(\(currentMonth)월)로 스크롤")
    }

    
    }

// MARK: - Rx Custom Binder for CardCalendarView
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
