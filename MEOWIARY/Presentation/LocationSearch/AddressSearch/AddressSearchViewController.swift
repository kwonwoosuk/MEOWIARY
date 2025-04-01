//
//  AddressSearchViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation
import SnapKit

protocol AddressSearchViewControllerDelegate: AnyObject {
  func didSelectLocation(coordinate: CLLocationCoordinate2D, addressName: String)
}

final class AddressSearchViewController: BaseViewController {
  
  // MARK: - Properties
  private let viewModel = AddressSearchViewModel()
  private let disposeBag = DisposeBag()
  weak var delegate: AddressSearchViewControllerDelegate?
  
  // MARK: - UI Components
  private let navigationBarView = CustomNavigationBarView()
  
  private let searchBar: UISearchBar = {
    let searchBar = UISearchBar()
    return searchBar
  }()
  
  private let tableView: UITableView = {
    let tableView = UITableView()
    return tableView
  }()
  
  private let loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    return indicator
  }()
  
  private let emptyResultView: UIView = {
    let view = UIView()
    return view
  }()
  
  private let emptyImageView: UIImageView = {
    let imageView = UIImageView()
    return imageView
  }()
  
  private let emptyLabel: UILabel = {
    let label = UILabel()
    return label
  }()
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // 키보드 자동 표시
    searchBar.becomeFirstResponder()
  }
  
  // MARK: - UI Setup
  override func configureHierarchy() {
    view.addSubview(navigationBarView)
    view.addSubview(searchBar)
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
    
    searchBar.snp.makeConstraints { make in
      make.top.equalTo(navigationBarView.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(56)
    }
    
    tableView.snp.makeConstraints { make in
      make.top.equalTo(searchBar.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }
    
    loadingIndicator.snp.makeConstraints { make in
      make.center.equalTo(tableView)
    }
    
    emptyResultView.snp.makeConstraints { make in
      make.center.equalTo(tableView)
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
    navigationBarView.configure(title: "주소 검색", leftButtonType: .close)
    
    // 검색바 설정
    searchBar.placeholder = "주소를 입력하세요"
    searchBar.searchBarStyle = .minimal
    searchBar.returnKeyType = .search
    
    // 테이블뷰 설정
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AddressCell")
    tableView.separatorStyle = .singleLine
    tableView.keyboardDismissMode = .onDrag
    
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
    emptyLabel.text = "검색 결과가 없습니다"
    emptyLabel.textAlignment = .center
    emptyLabel.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    emptyLabel.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    
    // 뷰 배경색 설정
    view.backgroundColor = .white
  }
  
  // MARK: - Binding
  override func bind() {
    // 네비게이션 바 뒤로가기 버튼
    navigationBarView.leftButtonTapObservable
      .subscribe(onNext: { [weak self] in
        self?.dismiss(animated: true)
      })
      .disposed(by: disposeBag)
    
    // 뷰모델 Input 생성
    let input = AddressSearchViewModel.Input(
      searchQuery: searchBar.rx.text.orEmpty.asObservable(),
      searchButtonClicked: searchBar.rx.searchButtonClicked.asObservable()
    )
    
    // 키보드 닫기
    searchBar.rx.searchButtonClicked
      .subscribe(onNext: { [weak self] in
        self?.searchBar.resignFirstResponder()
      })
      .disposed(by: disposeBag)
    
    // 뷰모델 Output 가져오기
    let output = viewModel.transform(input: input)
    
    // 주소 검색 결과 바인딩
    output.addressResults
      .drive(tableView.rx.items(cellIdentifier: "AddressCell", cellType: UITableViewCell.self)) { index, address, cell in
        var content = cell.defaultContentConfiguration()
        content.text = address.addressName
        
        if let roadAddress = address.roadAddress {
          content.secondaryText = "도로명: \(roadAddress.addressName)"
        } else if let jibunAddress = address.address {
          content.secondaryText = "지번: \(jibunAddress.addressName)"
        }
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
      }
      .disposed(by: disposeBag)
    
    // 로딩 상태 바인딩
    output.isSearching
      .drive(loadingIndicator.rx.isAnimating)
      .disposed(by: disposeBag)
    
    // 검색 결과에 따른 빈 화면 표시
    output.addressResults
      .map { $0.isEmpty && !self.loadingIndicator.isAnimating }
      .drive(onNext: { [weak self] isEmpty in
        self?.emptyResultView.isHidden = !isEmpty
      })
      .disposed(by: disposeBag)
    
    // 테이블 뷰 셀 선택 처리
    tableView.rx.itemSelected
      .withLatestFrom(output.addressResults) { indexPath, addresses -> AddressDocument? in
        guard indexPath.row < addresses.count else { return nil }
        return addresses[indexPath.row]
      }
      .subscribe(onNext: { [weak self] selectedAddress in
        self?.tableView.indexPathsForSelectedRows?.forEach {
          self?.tableView.deselectRow(at: $0, animated: true)
        }
        
        if let address = selectedAddress {
          self?.delegate?.didSelectLocation(coordinate: address.coordinate, addressName: address.addressName)
          self?.dismiss(animated: true)
        }
      })
      .disposed(by: disposeBag)
  }
}
