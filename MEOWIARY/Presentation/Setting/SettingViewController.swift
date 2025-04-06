//
//  SettingViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/6/25.
//

import UIKit
import AcknowList

final class SettingViewController: UIViewController {
    // MARK: - Properties (Model)
    private let settings = [
        SettingItem(title: "앱버전", hasAction: false),
        SettingItem(title: "오픈 소스 라이브러리", hasAction: true)
    ]
    
    // MARK: - UI Components (View)
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        return tableView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // 테이블 뷰 설정
        tableView.delegate = self
        tableView.dataSource = self
        
        // 레이아웃 설정
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func setupNavigation() {
        navigationItem.title = "설정"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "닫기",
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationController?.navigationBar.tintColor = DesignSystem.Color.Tint.text.inUIColor()
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SettingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        let setting = settings[indexPath.row]
        
        cell.textLabel?.text = setting.title
        cell.textLabel?.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.regular)
        cell.textLabel?.textColor = DesignSystem.Color.Tint.text.inUIColor()
        cell.selectionStyle = setting.hasAction ? .default : .none
        
        // "앱버전" 셀에 버전 정보 추가
        if indexPath.row == 0 {
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                cell.detailTextLabel?.text = appVersion
                cell.detailTextLabel?.textColor = .gray
                cell.detailTextLabel?.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
            }
        } else {
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "MEOWAIRY"
    }
    
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      
      let setting = settings[indexPath.row]
      if setting.hasAction && setting.title == "오픈 소스 라이브러리" {
          // CustomAcknowListViewController 생성
          let acknowListVC: CustomAcknowListViewController
          if let url = Bundle.main.url(forResource: "Acknowledgements", withExtension: "plist") {
              acknowListVC = CustomAcknowListViewController(plistFileURL: url, style: .grouped)
          } else {
              acknowListVC = CustomAcknowListViewController()
          }
          
          // 네비게이션 타이틀 설정
          acknowListVC.title = "오픈 소스 라이브러리"
          
          // AcknowListViewController로 push
          navigationController?.pushViewController(acknowListVC, animated: true)
      }
  }
}

// MARK: - Model
struct SettingItem {
    let title: String
    let hasAction: Bool
}
