//
//  CustomAcknowListViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/6/25.
//


import UIKit
import AcknowList

final class CustomAcknowListViewController: AcknowListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 스타일링 적용
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = DesignSystem.Color.Tint.text.inUIColor()
    }
}
