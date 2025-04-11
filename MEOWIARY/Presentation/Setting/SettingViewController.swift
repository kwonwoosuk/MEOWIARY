//
//  SettingViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/6/25.
//

import UIKit
import AcknowList
import RealmSwift
import RxSwift

final class SettingViewController: UIViewController {
    // MARK: - Properties (Model)
    private let disposeBag = DisposeBag()
    private let settings = [
        SettingItem(title: "앱버전", hasAction: false),
        SettingItem(title: "오픈 소스 라이브러리", hasAction: true),
        SettingItem(title: "앱 초기화", hasAction: true, isDestructive: true)
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
    
    // MARK: - Realm 데이터 초기화 메서드
    private func resetAllRealmData() {
           // 이미지 파일 삭제 작업 시작
           deleteAllCustomImages()
           
           do {
               let realm = try Realm()
               
               try realm.write {
                   // 모든 데이터 삭제
                   realm.deleteAll()
               }
               
               // UserDefaults 초기화
               resetUserDefaults()
               
               // 앱 초기화 완료 토스트 메시지
               showToast(message: "앱이 초기화되었습니다.")
               
               // 메인 화면으로 돌아가기
               DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                   self?.navigateToMainScreen()
               }
               
           } catch {
               print("Realm 데이터 초기화 중 오류 발생: \(error)")
               showErrorAlert(message: "앱 초기화 중 오류가 발생했습니다.")
           }
       }
    
    private func deleteAllCustomImages() {
          let fileManager = FileManager.default
          let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
          
          // 이미지 디렉토리 삭제 (원본, 썸네일)
          let imageDirectories = ["original_images", "thumbnail_images"]
          
          for directory in imageDirectories {
              let directoryURL = documentsPath.appendingPathComponent(directory)
              
              if fileManager.fileExists(atPath: directoryURL.path) {
                  do {
                      try fileManager.removeItem(at: directoryURL)
                      print("\(directory) 디렉토리가 성공적으로 삭제되었습니다.")
                  } catch {
                      print("\(directory) 디렉토리 삭제 중 오류 발생: \(error)")
                  }
              }
          }
          
          // 대표 이미지 파일 삭제 (feature_image_로 시작하는 모든 파일)
          do {
              let files = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
              for file in files {
                  let filename = file.lastPathComponent
                  if filename.starts(with: "feature_image_") {
                      try fileManager.removeItem(at: file)
                      print("대표 이미지 파일 삭제됨: \(filename)")
                  }
              }
          } catch {
              print("대표 이미지 파일 삭제 중 오류 발생: \(error)")
          }
      }
      
      // UserDefaults 관련 데이터 초기화
      private func resetUserDefaults() {
          let defaults = UserDefaults.standard
          
          // 모의 데이터 생성 상태 초기화
          defaults.set(false, forKey: "mockDataCreated")
          
          // 사용자 정의 색상 팔레트 초기화
          defaults.removeObject(forKey: "customColorPalettes")
          
          // 월별 카드 색상 및 디스플레이 모드 초기화
          for year in 2020...2030 {
              for month in 1...12 {
                  // 카드 색상 삭제
                  defaults.removeObject(forKey: "card_color_\(year)_\(month)")
                  
                  // 디스플레이 모드 삭제
                  defaults.removeObject(forKey: "display_mode_\(year)_\(month)")
                  
                  // 대표 이미지 플래그 삭제
                  defaults.removeObject(forKey: "has_feature_image_\(year)_\(month)")
              }
          }
          
          // 변경사항 동기화
          defaults.synchronize()
          print("UserDefaults 관련 설정이 모두 초기화되었습니다.")
      }
    
    // 메인 화면으로 돌아가는 메서드
    private func navigateToMainScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else {
            return
        }
        
        let tabBarController = MWTabBarController()
        windowScene.windows.first?.rootViewController = tabBarController
        windowScene.windows.first?.makeKeyAndVisible()
    }
    
    // 토스트 메시지 표시
    private func showToast(message: String) {
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.showToast(message: message)
        }
    }
    
    // 에러 알림 표시
   
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
        
        // 앱 초기화 셀의 경우 빨간색으로 표시
      switch setting.isDestructive {
             case .some(true):
                 cell.textLabel?.textColor = .systemRed
             default:
                 cell.textLabel?.textColor = DesignSystem.Color.Tint.text.inUIColor()
             }
        
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
        switch (setting.title, setting.hasAction) {
        case ("오픈 소스 라이브러리", true):
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
        
        case ("앱 초기화", true):
            // 데이터 초기화 경고 알림
            let alert = UIAlertController(
                title: "앱 초기화 확인",
                message: "모든 데이터가 삭제됩니다. 정말 초기화하시겠습니까?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "취소",
                style: .cancel,
                handler: nil
            ))
            
            alert.addAction(UIAlertAction(
                title: "초기화",
                style: .destructive,
                handler: { [weak self] _ in
                    self?.resetAllRealmData()
                }
            ))
            
            present(alert, animated: true)
            
        default:
            break
        }
    }
}

// MARK: - Model
struct SettingItem {
    let title: String
    let hasAction: Bool
    let isDestructive: Bool?
    
    init(title: String, hasAction: Bool, isDestructive: Bool? = nil) {
        self.title = title
        self.hasAction = hasAction
        self.isDestructive = isDestructive
    }
}
