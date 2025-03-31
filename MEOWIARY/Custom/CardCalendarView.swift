//
//  CardCalendarView.swift - 페이징 관련 코드 수정
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
    private var pageWidth: CGFloat = 0
    
    // MARK: - UI Components
    private let cardCollectionView: UICollectionView = {
        // 수평 레이아웃으로 설정
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0 // 카드 간 간격 없음
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
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
        addSubview(pageControl)
    }
    
    override func configureLayout() {
        cardCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        pageControl.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-DesignSystem.Layout.smallMargin)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }
    }
    
    override func configureView() {
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        // CollectionView 설정
        cardCollectionView.register(CardCell.self, forCellWithReuseIdentifier: "CardCell")
        cardCollectionView.delegate = self
        cardCollectionView.dataSource = self
        
        // ✅ 중요: 페이징 활성화 - 정확히 한 페이지씩 스크롤되도록 설정
        cardCollectionView.isPagingEnabled = true
        
        // 초기 스크롤 위치를 메인 스레드에서 설정
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let currentMonth = Calendar.current.component(.month, from: Date()) - 1
            
            // 레이아웃이 완료된 후 페이지 너비 계산
            self.calculatePageWidth()
            
            if currentMonth >= 0 && currentMonth < 12 {
                self.scrollToMonth(month: currentMonth + 1, animated: false)
                self.pageControl.currentPage = currentMonth
            }
            
            // 현재 월이 화면에 표시되도록
            self.updateMonth(month: currentMonth + 1)
        }
    }
    
    // 페이지 너비를 계산하는 메서드
    private func calculatePageWidth() {
        pageWidth = self.frame.width
        
        // 페이지 너비가 계산되었으면 컬렉션 뷰 레이아웃 업데이트
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: pageWidth, height: self.frame.height - 40)
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        
        cardCollectionView.collectionViewLayout = layout
        cardCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: - Public Methods
    
    // 특정 월로 스크롤하는 메서드
    private func scrollToMonth(month: Int, animated: Bool) {
        guard month >= 1 && month <= 12 else { return }
        
        let indexPath = IndexPath(item: month - 1, section: 0)
        
        // 스크롤 전에 레이아웃 업데이트 확인
        cardCollectionView.layoutIfNeeded()
        
        // 정확한 위치로 스크롤
        cardCollectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: animated
        )
        
        // 현재 월 업데이트
        updateMonth(month: month)
        
        // 디버그 로그
        print("스크롤 완료: \(month)월로 이동")
    }
    
    // 레이아웃이 완료된 후 호출하여 UI 강제 업데이트
    func forceUpdateLayout() {
        // 페이지 너비 다시 계산
        calculatePageWidth()
        
        // 월 레이블 텍스트 설정
        monthLabel.text = "\(currentMonth)월"
        
        // 컬렉션뷰 데이터 리로드 및 현재 월로 스크롤
        cardCollectionView.reloadData()
        
        // 현재 월로 스크롤
        scrollToMonth(month: currentMonth, animated: false)
        
        // 레이아웃 갱신
        layoutIfNeeded()
        
        print("CardCalendarView: 강제 레이아웃 업데이트 완료")
    }
    
    // 현재 표시된 카드의 정확한 인덱스를 가져오는 메서드
    private func getCurrentCardIndex() -> Int {
        // 현재 스크롤 위치 기준으로 페이지 인덱스 계산
        let pageWidth = cardCollectionView.frame.width
        let contentOffsetX = cardCollectionView.contentOffset.x
        let currentIndex = Int(contentOffsetX / pageWidth)
        
        // 인덱스 범위 검증
        return min(max(currentIndex, 0), 11) // 0-11 범위 (1월-12월)
    }
    
    private func getCellForIndex(_ index: Int) -> CardCell? {
        let indexPath = IndexPath(item: index, section: 0)
        return cardCollectionView.cellForItem(at: indexPath) as? CardCell
    }
    
    func flipToCalendar() {
        // 현재 중앙에 표시된 카드의 인덱스 가져오기
        let currentIndex = getCurrentCardIndex()
        
        // 해당 셀 가져오기
        guard let currentCell = getCellForIndex(currentIndex) else {
            print("Error: 플립할 셀을 찾을 수 없습니다.")
            return
        }
        
        // 현재 선택된 월 업데이트
        currentMonth = currentIndex + 1
        updateMonth(month: currentMonth)
        
        // 플립 애니메이션 시작
        currentCell.flipToCalendar()
        
        // 플립 애니메이션 중에 페이지컨트롤 숨기기
        UIView.animate(withDuration: 0.3) {
            self.pageControl.alpha = 0
        }
        
        isCalendarMode = true
        
        // 디버그 로그
        print("CardCalendarView: \(currentMonth)월 카드를 캘린더로 플립")
    }

    func flipToCard() {
        // 현재 선택된 월에 해당하는 셀 가져오기
        let currentIndex = currentMonth - 1
        guard let currentCell = getCellForIndex(currentIndex) else {
            print("Error: 플립할 셀을 찾을 수 없습니다.")
            return
        }
        
        // 플립 애니메이션 시작
        currentCell.flipToCard()
        
        // 플립 애니메이션이 끝난 후 페이지컨트롤 다시 표시
        UIView.animate(withDuration: 0.3) {
            self.pageControl.alpha = 1
        }
        
        isCalendarMode = false
        
        // 디버그 로그
        print("CardCalendarView: \(currentMonth)월 카드를 되돌림")
    }

    func updateSymptomView(isShowing: Bool) {
        // 현재 표시된 카드의 증상 표시 업데이트
        let currentIndex = getCurrentCardIndex()
        if let currentCell = getCellForIndex(currentIndex) {
            currentCell.updateSymptomView(isShowing: isShowing)
        }
    }
    
    func updateMonth(month: Int) {
        // 월 레이블 업데이트
        UIView.performWithoutAnimation {
            monthLabel.text = "\(month)월"
            monthLabel.setNeedsDisplay()
            monthLabel.layoutIfNeeded()
        }
        
        print("CardCalendarView - 월 레이블 업데이트: \(month)월")
        
        currentMonth = month
        pageControl.currentPage = month - 1
    }
    
    func updateYear(year: String) {
        print("CardCalendarView - 연도 업데이트: \(year)")
        
        if let yearInt = Int(year) {
            currentYear = yearInt
            cardCollectionView.reloadData()
            
            // 년도 변경 시 현재 월 위치로 다시 스크롤
            scrollToMonth(month: currentMonth, animated: false)
        }
    }
    
    // 뷰 크기가 변경될 때 호출되는 메서드
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 뷰 크기가 변경되면 페이지 너비 다시 계산
        if pageWidth != self.frame.width {
            calculatePageWidth()
            
            // 현재 월로 다시 스크롤 (레이아웃 변경 후)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.scrollToMonth(month: self.currentMonth, animated: false)
            }
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
        cell.configure(forMonth: indexPath.item + 1, year: currentYear)
        
        // 캘린더 모드인 경우 현재 월에 해당하는 셀만 플립
        if isCalendarMode && indexPath.item == currentMonth - 1 {
            cell.flipToCalendar(animated: false)
        }
        
        // 디버깅용 로그
        print("CardCalendarView - 셀 구성: 월 \(indexPath.item + 1)")
        
        return cell
    }
    
    // 각 셀의 크기 설정 - 전체 화면 너비와 동일하게
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 각 카드가 컬렉션 뷰의 너비와 동일하도록 설정 (페이징용)
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height - 40)
    }
    
    // 섹션 인셋 설정 - 상하 여백만 설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
    }
    
    // 셀 간 간격 설정 - 간격 없음
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // 스크롤이 멈춘 후 호출되는 메서드
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 정확한 페이지 인덱스 계산
        let currentIndex = getCurrentCardIndex()
        let month = currentIndex + 1
        
        // 페이지 컨트롤 및 월 업데이트
        pageControl.currentPage = currentIndex
        updateMonth(month: month)
        
        // 디버깅 로그
        print("CardCalendarView - 스크롤 완료: 페이지 \(currentIndex + 1)")
    }
    
    // 스크롤 애니메이션이 끝난 후 호출되는 메서드
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
}
