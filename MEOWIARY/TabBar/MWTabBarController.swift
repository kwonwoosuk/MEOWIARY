//
//  MWTabBarController.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - Forward Declarations


final class MWTabBarController: UITabBarController {
  
  // MARK: - Properties
  private let disposeBag = DisposeBag()
  private var diaryOptionView: DiaryOptionView?
  private var dimmedView: UIView?
  private var isOptionViewShowing = false
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    configureTabBarController()
    setupTabBarAppearance()
    tabBar.delegate = self
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    // 이미 추가된 centerButton의 위치 조정
    if let centerButton = view.viewWithTag(999) as? UIButton {
      let screenHeight = UIScreen.main.bounds.height
      let isSmallScreen = screenHeight <= 667 // iPhone SE, iPhone 8
      let isLargeScreen = screenHeight >= 844 // iPhone 12 이상, 14/16 등
      
      let tabBarHeight = tabBar.frame.height
      let yOffset: CGFloat
      
      if isSmallScreen {
        yOffset = tabBar.frame.minY + (tabBarHeight / 2)
      } else if isLargeScreen {
        yOffset = tabBar.frame.minY + (tabBarHeight / 2) - 10
      } else {
        yOffset = tabBar.frame.minY + (tabBarHeight / 2) - 5
      }
      
      centerButton.center = CGPoint(x: tabBar.center.x, y: yOffset)
    }
  }
  
  // MARK: - Configuration
  private func configureTabBarController() {
    // 홈 탭
    let homeTab = HomeViewController()
    homeTab.tabBarItem.image = DesignSystem.Icon.Navigation.note.toUIImage()
    homeTab.tabBarItem.title = "기록"
    
    // 중앙 탭 (플러스 버튼)
    let addTab = UIViewController() // 실제로 전환되지 않을 뷰컨트롤러
    addTab.tabBarItem.image = nil  // 시스템 이미지 대신 커스텀 이미지를 적용할 것임
    addTab.tabBarItem.title = ""
    
    // 이미지 갤러리 탭
    let galleryTab = GalleryViewController()
    galleryTab.tabBarItem.image = DesignSystem.Icon.Navigation.chart.toUIImage()
    galleryTab.tabBarItem.title = "모아보기"
    
    // 네비게이션 컨트롤러로 래핑
    let homeNav = UINavigationController(rootViewController: homeTab)
    homeNav.isNavigationBarHidden = true // 커스텀 네비게이션 바를 사용하므로 기본 네비게이션 바는 숨김
    
    let addNav = UINavigationController(rootViewController: addTab)
    addNav.isNavigationBarHidden = true
    
    let galleryNav = UINavigationController(rootViewController: galleryTab)
    galleryNav.isNavigationBarHidden = true
    
    setViewControllers([homeNav, addNav, galleryNav], animated: true)
    
    // 중앙 탭(+)의 커스텀 이미지 버튼 적용
    setupCenterButton()
  }
  
  private func setupTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundColor = .white
    
    // 그림자 설정
    tabBar.layer.shadowOffset = CGSize(width: 0, height: -0.5)
    tabBar.layer.shadowRadius = 0
    tabBar.layer.shadowColor = UIColor.lightGray.cgColor
    tabBar.layer.shadowOpacity = 0.3
    
    // 선택된 아이템 색상 설정
    tabBar.tintColor = DesignSystem.Color.Tint.action.inUIColor()
    
    // 선택되지 않은 아이템 색상 설정
    appearance.stackedLayoutAppearance.normal.iconColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
      NSAttributedString.Key.foregroundColor: DesignSystem.Color.Tint.darkGray.inUIColor()
    ]
    
    tabBar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      tabBar.scrollEdgeAppearance = appearance
    }
  }
  
  private func setupCenterButton() {
    // 커스텀 중앙 버튼 생성
    let centerButton = UIButton(type: .custom)
    
    // 기기 화면 크기에 따라 버튼 크기 조정
    let isSmallScreen = UIScreen.main.bounds.height <= 667 // iPhone SE, iPhone 8
    let buttonSize: CGFloat = isSmallScreen ? 44 : 50 // 작은 화면에서는 더 작은 버튼
    let buttonRadius = buttonSize / 2
    
    centerButton.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
    
    // 원형 배경 설정
    centerButton.backgroundColor = DesignSystem.Color.Tint.action.inUIColor()
    centerButton.layer.cornerRadius = buttonRadius
    
    // + 아이콘 설정 (작은 화면에서는 아이콘 크기 줄임)
    let iconSize: CGFloat = isSmallScreen ? 18 : 22
    let plusImage = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium))
    centerButton.setImage(plusImage, for: .normal)
    centerButton.tintColor = .white
    
    // 그림자 효과
    centerButton.layer.shadowColor = UIColor.black.cgColor
    centerButton.layer.shadowOpacity = 0.2
    centerButton.layer.shadowOffset = CGSize(width: 0, height: 2)
    centerButton.layer.shadowRadius = 4
    
    // 버튼을 탭바 내부에 위치시키기
    // 탭바의 중앙에 버튼을 배치하고, 위아래 여백을 균등하게 배분
    let tabBarHeight = tabBar.frame.height
    let yPosition = tabBar.frame.minY + (tabBarHeight / 2)
    
    centerButton.center = CGPoint(x: tabBar.center.x, y: yPosition)
    
    // 버튼 눌렀을 때 액션 설정
    centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
    centerButton.tag = 999
    // 뷰에 추가
    view.addSubview(centerButton)
  }
  
  // MARK: - Actions
  @objc private func centerButtonTapped() {
    presentDiaryOptions()
  }
  
  private func presentDiaryOptions() {
    // 이미 표시 중이면 무시
    if isOptionViewShowing {
      return
    }
    
    isOptionViewShowing = true
    
    // 딤드 뷰 생성
    let dimmedView = UIView()
    dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    dimmedView.alpha = 0
    view.addSubview(dimmedView)
    dimmedView.frame = view.bounds
    
    // 탭 제스처 추가
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissDiaryOptions))
    dimmedView.addGestureRecognizer(tapGesture)
    
    // 다이어리 옵션 뷰 생성
    let optionView = DiaryOptionView()
    view.addSubview(optionView)
    
    // 옵션 뷰 크기 및 위치 설정
    let optionViewHeight: CGFloat = 190
    optionView.frame = CGRect(
      x: 0,
      y: view.bounds.height,
      width: view.bounds.width,
      height: optionViewHeight
    )
    
    // 버튼 액션 바인딩
    optionView.dailyRecordButtonTapped
      .subscribe(onNext: { [weak self] in
        self?.dismissDiaryOptions()
        self?.presentDailyDiaryController()
      })
      .disposed(by: disposeBag)
    
    optionView.symptomRecordButtonTapped
      .subscribe(onNext: { [weak self] in
        self?.dismissDiaryOptions()
        self?.presentSymptomRecordController()
      })
      .disposed(by: disposeBag)
    
    // 참조 저장
    self.diaryOptionView = optionView
    self.dimmedView = dimmedView
    
    // 애니메이션으로 표시
    UIView.animate(withDuration: 0.3, animations: {
      dimmedView.alpha = 1
      optionView.frame.origin.y = self.view.bounds.height - optionViewHeight
    })
  }
  
  @objc private func dismissDiaryOptions() {
    guard isOptionViewShowing, let optionView = diaryOptionView, let dimmedView = dimmedView else {
      return
    }
    
    // 애니메이션으로 숨김
    UIView.animate(withDuration: 0.3, animations: {
      dimmedView.alpha = 0
      optionView.frame.origin.y = self.view.bounds.height
    }, completion: { _ in
      dimmedView.removeFromSuperview()
      optionView.removeFromSuperview()
      self.diaryOptionView = nil
      self.dimmedView = nil
      self.isOptionViewShowing = false
    })
  }
  
  // MARK: - Modal Presentations
  private func presentDailyDiaryController() {
    // 일기 작성 화면을 모달로 표시
    let dailyDiaryVC = DailyDiaryViewController()
    let navController = UINavigationController(rootViewController: dailyDiaryVC)
    navController.isNavigationBarHidden = true // 커스텀 네비게이션 바 사용
    navController.modalPresentationStyle = .fullScreen
    present(navController, animated: true)
  }
  
  private func presentSymptomRecordController() {
    // 증상 기록 화면을 모달로 표시
    let symptomRecordVC = SymptomRecordViewController()
    let navController = UINavigationController(rootViewController: symptomRecordVC)
    navController.isNavigationBarHidden = true // 커스텀 네비게이션 바 사용
    navController.modalPresentationStyle = .fullScreen
    present(navController, animated: true)
  }
  
  
}

// MARK: - UITabBarControllerDelegate
extension MWTabBarController: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    // 중앙 탭(+)이 선택되었을 때 특별한 처리
    if tabBarController.selectedIndex == 1 || viewController == tabBarController.viewControllers?[1] {
      // 다이어리 옵션 모달 표시
      presentDiaryOptions()
      return false // 실제 탭 선택은 방지
    }
    return true
  }
}
