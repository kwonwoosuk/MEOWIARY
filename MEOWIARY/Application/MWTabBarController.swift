//
//  MWTabBarController.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import UIKit

final class MWTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBarController()
        setupTabBarAppearance()
        tabBar.delegate = self
    }
    
    private func configureTabBarController() {
        
        let homeTab = HomeViewController()
        homeTab.tabBarItem.image = DesignSystem.Icon.Navigation.note.toUIImage()
        homeTab.tabBarItem.title = "기록"
        
        let addTab = UIViewController() // 추후 구현할 일기 작성 화면
        addTab.tabBarItem.image = DesignSystem.Icon.Navigation.add.toUIImage()
        addTab.tabBarItem.title = ""
        
        let chartsTab = UIViewController()
        chartsTab.tabBarItem.image = DesignSystem.Icon.Navigation.chart.toUIImage()
        chartsTab.tabBarItem.title = "모아보기"
        
        let homeNav = UINavigationController(rootViewController: homeTab)
        homeNav.isNavigationBarHidden = true // 커스텀 네비게이션 바를 사용하므로 기본 네비게이션 바는 숨김
        
        let addNav = UINavigationController(rootViewController: addTab)
        addNav.isNavigationBarHidden = true
        
        let chartsNav = UINavigationController(rootViewController: chartsTab)
        chartsNav.isNavigationBarHidden = true
        
        setViewControllers([homeNav, addNav, chartsNav], animated: true)
        
        // 중앙 탭(+)의 특별한 스타일 적용
        if let items = tabBar.items {
            let addItem = items[1]
            addItem.imageInsets = UIEdgeInsets(top: -15, left: 0, bottom: 15, right: 0)
        }
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
}

// MARK: - UITabBarControllerDelegate
extension MWTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // 중앙 탭(+)이 선택되었을 때 특별한 처리
        if tabBarController.selectedIndex == 1 || viewController == tabBarController.viewControllers?[1] {
            // 일기 작성 모달 화면 표시 (추후 구현)
            presentAddDiaryController()
            return false // 실제 탭 선택은 방지
        }
        return true
    }
    
    private func presentAddDiaryController() {
        // 일기 작성 화면을 모달로 표시 (임시 코드)
        let addDiaryVC = UIViewController()
        addDiaryVC.view.backgroundColor = .white
        addDiaryVC.modalPresentationStyle = .fullScreen
        present(addDiaryVC, animated: true)
    }
}
