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
  private var currentYear = Calendar.current.component(.year, from: Date())
  private var currentMonth = Calendar.current.component(.month, from: Date())
  private var currentDay = Calendar.current.component(.day, from: Date())
  private var symptomsData: [Int: Bool] = [:]  // Dictionary to track days with symptoms
  private var pageWidth: CGFloat = 0
  private var dayCardData: [Int: DayCard] = [:]
  private let dayCardRepository = DayCardRepository()
  
  public var isCalendarMode = false {
    didSet {
      print("CardCalendarView: 캘린더 모드 변경: \(isCalendarMode)")
      // 모드 변경 시 컬렉션 뷰 리로드
      
    }
  }
  
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
  
  
  // MARK: - Configuration
  override func configureHierarchy() {
    addSubview(cardCollectionView)
  }
  
  override func configureLayout() {
    cardCollectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
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
        
      }
      
      // 현재 월이 화면에 표시되도록
      self.updateMonth(month: currentMonth + 1)
    }
  }
  
  func updateData(year: Int, month: Int) {
    dayCardData = dayCardRepository.getDayCardsMapForMonth(year: year, month: month)
    
    // 캘린더 그리드 업데이트 (플립 상태일 때만)
    if isCalendarMode {
      // 현재 보이는 셀만 업데이트
      if let cell = getCellForIndex(month - 1) {
        // 수정: CardCell의 createCalendarGrid 호출
        cell.createCalendarGrid(with: dayCardData)
      }
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
    
    
    return min(max(currentIndex, 0), 11) // 0-11 범위 (1월-12월)
  }
  
  func getCellForIndex(_ index: Int) -> CardCell? {
    let indexPath = IndexPath(item: index, section: 0)
    
    // 두 가지 방법으로 시도
    if let cell = cardCollectionView.cellForItem(at: indexPath) as? CardCell {
      return cell
    }
    
    // 화면에 보이지 않는 셀도 적용하기 위해 모든 셀을 탐색
    for cell in cardCollectionView.visibleCells {
      if let cardCell = cell as? CardCell, cardCell.tag == index + 1 {
        return cardCell
      }
    }
    
    return nil
  }
  
  func flipAllToCalendar() {
    // 이미 캘린더 모드면 무시
    guard !isCalendarMode else { return }
    
    // 모드 변경 전에 모든 셀에 애니메이션 적용
    for i in 0..<12 {
      if let cell = getCellForIndex(i) {
        // 현재 보이는 셀과 그 주변 셀에만 애니메이션 적용
        cell.flipToCalendar()
      }
    }
    
    // 이제 모드를 변경
    isCalendarMode = true
    
    
    
    print("CardCalendarView: 모든 카드를 캘린더로 플립 (모든 셀에 애니메이션 적용)")
  }
  
  // 모든 카드를 원래 상태로 한 번에 되돌리기 (모든 셀에 애니메이션 적용)
  func flipAllToCard() {
    // 이미 카드 모드면 무시
    guard isCalendarMode else { return }
    
    // 모드 변경 전에 모든 셀에 애니메이션 적용
    for i in 0..<12 {
      if let cell = getCellForIndex(i) {
        // 현재 보이는 셀과 그 주변 셀에만 애니메이션 적용
        cell.flipToCard()
      }
    }
    
    // 이제 모드를 변경
    isCalendarMode = false
    
    
    
    print("CardCalendarView: 모든 카드를 원래 상태로 되돌림 (모든 셀에 애니메이션 적용)")
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
    
    
    // 데이터 업데이트
    updateData(year: currentYear, month: currentMonth)
  }
  
  func updateYear(year: String) {
    print("CardCalendarView - 연도 업데이트: \(year)")
    
    if let yearInt = Int(year) {
      currentYear = yearInt
      updateData(year: currentYear, month: currentMonth)
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
func cellPrepared(cell: CardCell, forMonth month: Int) {
  // 월을 기준으로 고유 태그 설정 (나중에 찾을 수 있도록)
  cell.tag = month
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
    let month = indexPath.item + 1
    
    // 현재 월의 데이터 가져오기
    let monthData = dayCardRepository.getDayCardsMapForMonth(year: currentYear, month: month)
    
    cell.configure(forMonth: month, year: currentYear, dayCardData: monthData)
    
    // 셀에 고유 태그 설정 (월 기준)
    cellPrepared(cell: cell, forMonth: month)
    
    // 캘린더 모드에 따라 셀 상태 설정
    if isCalendarMode {
      // 애니메이션 없이 상태 설정 (이미 애니메이션은 모드 변경 시 적용)
      cell.flipToCalendar(animated: false)
    } else {
      // 애니메이션 없이 상태 설정
      cell.flipToCard(animated: false)
    }
    
    return cell
  }
  
  // 스크롤 후 현재 보이는 셀에 대한 처리 추가
  
  
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
    
    updateMonth(month: month)
    
    // 디버깅 로그
    print("CardCalendarView - 스크롤 완료: 페이지 \(currentIndex + 1)")
  }
  
  // 스크롤 애니메이션이 끝난 후 호출되는 메서드
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    scrollViewDidEndDecelerating(scrollView)
  }
}
