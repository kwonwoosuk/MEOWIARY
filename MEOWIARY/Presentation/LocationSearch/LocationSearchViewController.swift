//
//  LocationSearchViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation
import SnapKit

final class LocationSearchViewController: BaseViewController {
  
  // MARK: - Properties
  private let viewModel = LocationSearchViewModel()
  private let disposeBag = DisposeBag()
  private let manualLocationSelectedSubject = PublishSubject<(CLLocationCoordinate2D, String)>()
  
  // MARK: - UI Components
  private let navigationBarView = CustomNavigationBarView()
  private let locationInfoView = UIView()
  private let locationIcon = UIImageView()
  private let locationLabel = UILabel()
  private let searchAddressButton = UIButton()
  private let tableView = UITableView()
  private let loadingIndicator = UIActivityIndicatorView(style: .large)
  private let emptyResultView = UIView()
  private let emptyImageView = UIImageView()
  private let emptyLabel = UILabel()
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.fetchHospitals()
  }
  
  // MARK: - UI Setup
  override func configureHierarchy() {
    view.addSubview(navigationBarView)
    view.addSubview(locationInfoView)
    locationInfoView.addSubview(locationIcon)
    locationInfoView.addSubview(locationLabel)
    locationInfoView.addSubview(searchAddressButton)
    view.addSubview(tableView)
    view.addSubview(loadingIndicator)
    
    view.addSubview(emptyResultView)
    emptyResultView.addSubview(emptyImageView)
    emptyResultView.addSubview(emptyLabel)
  }
  
  override func configureLayout() {
    navigationBarView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(50)
    }
    
    locationInfoView.snp.makeConstraints { make in
      make.top.equalTo(navigationBarView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
      make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
      make.height.equalTo(50)
    }
    
    locationIcon.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(20)
    }
    
    locationLabel.snp.makeConstraints { make in
      make.leading.equalTo(locationIcon.snp.trailing).offset(DesignSystem.Layout.smallMargin)
      make.centerY.equalToSuperview()
      make.trailing.lessThanOrEqualTo(searchAddressButton.snp.leading).offset(-DesignSystem.Layout.smallMargin)
    }
    
    searchAddressButton.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
      make.centerY.equalToSuperview()
    }
    
    tableView.snp.makeConstraints { make in
      make.top.equalTo(locationInfoView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
      make.leading.trailing.bottom.equalToSuperview()
    }
    
    loadingIndicator.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
    
    emptyResultView.snp.makeConstraints { make in
      make.center.equalTo(tableView.snp.center)
      make.width.equalTo(200)
      make.height.equalTo(120)
    }
    
    emptyImageView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.centerX.equalToSuperview()
      make.width.height.equalTo(48)
    }
    
    emptyLabel.snp.makeConstraints { make in
      make.top.equalTo(emptyImageView.snp.bottom).offset(DesignSystem.Layout.smallMargin)
      make.centerX.equalToSuperview()
      make.leading.trailing.equalToSuperview()
    }
  }
  
  override func configureView() {
    // 네비게이션 바 설정
    navigationBarView.configure(title: "근처 24시 병원", leftButtonType: .back)
    
    // 위치 정보 컨테이너 뷰 설정
    locationInfoView.backgroundColor = DesignSystem.Color.Background.lightBlue.inUIColor()
    locationInfoView.layer.cornerRadius = DesignSystem.Layout.cornerRadius
    
    // 위치 아이콘 설정
    locationIcon.image = UIImage(systemName: "location.fill")
    locationIcon.tintColor = DesignSystem.Color.Tint.action.inUIColor()
    locationIcon.contentMode = .scaleAspectFit
    
    // 위치 레이블 설정
    locationLabel.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.small)
    locationLabel.textColor = DesignSystem.Color.Tint.text.inUIColor()
    locationLabel.text = "현재 위치 주변 검색 중..."
    
    // 주소 검색 버튼 설정
    searchAddressButton.setTitle("주소 검색", for: .normal)
    searchAddressButton.setTitleColor(DesignSystem.Color.Tint.action.inUIColor(), for: .normal)
    searchAddressButton.titleLabel?.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.small)
    
    // 테이블 뷰 설정
    tableView.register(HospitalCell.self, forCellReuseIdentifier: "HospitalCell")
    tableView.backgroundColor = .white
    tableView.separatorStyle = .singleLine
    tableView.rowHeight = 70
    
    // 로딩 인디케이터 설정
    loadingIndicator.hidesWhenStopped = true
    loadingIndicator.color = DesignSystem.Color.Tint.main.inUIColor()
    
    // 빈 결과 화면 설정
    emptyResultView.isHidden = true
    
    // 빈 결과 이미지 설정
    emptyImageView.image = UIImage(systemName: "magnifyingglass")
    emptyImageView.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    emptyImageView.contentMode = .scaleAspectFit
    
    // 빈 결과 레이블 설정
    emptyLabel.text = "주변에 24시 병원이 없습니다."
    emptyLabel.textAlignment = .center
    emptyLabel.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    emptyLabel.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    
    // 화면 배경색 설정
    view.backgroundColor = .white
  }
  
  // MARK: - Binding
  override func bind() {
    
    navigationBarView.leftButtonTapObservable
      .subscribe(onNext: { [weak self] in
        self?.dismiss(animated: true)
      })
      .disposed(by: disposeBag)
    
    // 주소 검색 버튼 클릭 시
    searchAddressButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.showAddressSearchVC()
      })
      .disposed(by: disposeBag)
    
    // 뷰모델 입력
    let viewDidLoadEvent = PublishSubject<Void>()
    let refreshEvent = PublishSubject<Void>()
    
    let input = LocationSearchViewModel.Input(
      viewDidLoad: viewDidLoadEvent.asObservable(),
      refresh: refreshEvent.asObservable(),
      manualLocationSelected: manualLocationSelectedSubject.asObservable()
    )
    
    let output = viewModel.transform(input: input)
    
    // 병원 목록 바인딩
    output.hospitals
      .drive(tableView.rx.items(cellIdentifier: "HospitalCell", cellType: HospitalCell.self)) { _, hospital, cell in
        cell.configure(with: hospital)
      }
      .disposed(by: disposeBag)
    
    // 로딩 상태 바인딩
    output.isLoading
      .drive(onNext: { [weak self] isLoading in
        if isLoading {
          self?.loadingIndicator.startAnimating()
        } else {
          self?.loadingIndicator.stopAnimating()
        }
      })
      .disposed(by: disposeBag)
    
    // 오류 메시지 바인딩
    output.error
      .drive(onNext: { [weak self] errorMessage in
        if let errorMessage = errorMessage {
          // 오류 메시지가 있는 경우 Toast 또는 Alert 표시
          print("오류: \(errorMessage)")
        }
      })
      .disposed(by: disposeBag)
    
    // 검색 결과에 따른 빈 화면 표시
    output.hospitals
      .map { $0.isEmpty && !self.loadingIndicator.isAnimating }
      .drive(onNext: { [weak self] isEmpty in
        self?.emptyResultView.isHidden = !isEmpty
      })
      .disposed(by: disposeBag)
    
    // 위치 이름 바인딩
    output.selectedAddressName
      .drive(onNext: { [weak self] addressName in
        if let addressName = addressName {
          self?.locationLabel.text = "\(addressName) 주변"
        }
      })
      .disposed(by: disposeBag)
    
    // 주소 검색 화면 표시 여부
    output.shouldShowAddressSearch
      .drive(onNext: { [weak self] shouldShow in
        if shouldShow {
          // 위치 권한이 없는 경우 주소 검색 버튼 강조
          self?.searchAddressButton.setTitleColor(DesignSystem.Color.Tint.main.inUIColor(), for: .normal)
          self?.locationLabel.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
          self?.locationIcon.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        }
      })
      .disposed(by: disposeBag)
    
    // 셀 선택 이벤트
    tableView.rx.itemSelected
      .withLatestFrom(output.hospitals) { indexPath, hospitals -> (IndexPath, Hospital?) in
        guard indexPath.row < hospitals.count else {
          return (indexPath, nil)
        }
        return (indexPath, hospitals[indexPath.row])
      }
      .subscribe(onNext: { [weak self] tuple in
        let (indexPath, hospital) = tuple
        self?.tableView.deselectRow(at: indexPath, animated: true)
        
        if let hospital = hospital {
          self?.showHospitalDetails(hospital: hospital)
        }
      })
      .disposed(by: disposeBag)
    
    viewDidLoadEvent.onNext(())
  }
  
  // MARK: - Helper Methods
  private func showAddressSearchVC() {
    let addressSearchVC = AddressSearchViewController()
    addressSearchVC.delegate = self
    addressSearchVC.modalPresentationStyle = .fullScreen
    present(addressSearchVC, animated: true)
  }
  
  private func showHospitalDetails(hospital: Hospital) {
    // 병원 상세 정보 표시 (알림창)
    let alert = UIAlertController(
      title: hospital.name,
      message: """
                주소: \(hospital.address)
                거리: \(hospital.distance)
                전화: \(hospital.phone)
                """,
      preferredStyle: .alert
    )
    
    // 전화걸기 액션
    alert.addAction(UIAlertAction(title: "전화 걸기", style: .default) { _ in
      if let url = URL(string: "tel://\(hospital.phone.replacingOccurrences(of: "-", with: ""))"),
         UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
      }
    })
    
    // 길찾기 액션 (카카오맵 앱으로 연결)
    alert.addAction(UIAlertAction(title: "길찾기", style: .default) { [weak self] _ in
      self?.openKakaoMapNavigation(to: hospital)
    })
    
    alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
    
    present(alert, animated: true)
  }
  
  private func openKakaoMapNavigation(to hospital: Hospital) {
    // 카카오맵 앱 URL 스킴 사용
    let kakaoMapBaseURL = "kakaomap://route"
    let destinationName = hospital.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let latitude = hospital.coordinate.latitude
    let longitude = hospital.coordinate.longitude
    
    let urlString = "\(kakaoMapBaseURL)?ep=\(latitude),\(longitude)&by=CAR&ename=\(destinationName)"
    
    if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url)
    } else {
      // 카카오맵 앱이 설치되어 있지 않은 경우 웹 버전으로 열기
      let webURLString = "https://map.kakao.com/link/to/\(destinationName),\(latitude),\(longitude)"
      if let webURL = URL(string: webURLString) {
        UIApplication.shared.open(webURL)
      }
    }
  }
}

// MARK: - AddressSearchViewControllerDelegate
extension LocationSearchViewController: AddressSearchViewControllerDelegate {
  func didSelectLocation(coordinate: CLLocationCoordinate2D, addressName: String) {
    manualLocationSelectedSubject.onNext((coordinate, addressName))
  }
}
