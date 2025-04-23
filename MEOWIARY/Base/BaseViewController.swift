//
//  BaseViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/30/25.
//

import UIKit

class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureHierarchy()
        configureLayout()
        configureView()
        bind()
        setupKeyboardDismissGesture()
        logScreenView() // 어떤 화면에 
    }
    
    func configureHierarchy() { }
    
    func configureLayout() { }
    
    func configureView() { }
    
    func bind() { }
    
    
    private func logScreenView() {
        // 현재 클래스 이름 가져오기
        let screenName = String(describing: type(of: self))
        
        // 필요하다면 특정 화면 이름 커스터마이징
        var customScreenName = screenName
        
        if customScreenName.hasSuffix("ViewController") {
            customScreenName = String(customScreenName.dropLast("ViewController".count))
        }
        
        // Analytics 서비스 호출
        AnalyticsService.shared.logScreenView(
            screenName: customScreenName,
            screenClass: screenName
        )
    }
    
    func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
