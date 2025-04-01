//
//  LocationSearchViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

enum LocationError: Error {
  case locationPermissionDenied
  case locationServicesDisabled
  case locationFailed
  case networkError(Error)
}

final class LocationSearchViewModel: NSObject, BaseViewModel {
  
  // MARK: - BaseViewModel
  var disposeBag = DisposeBag()
  
  // MARK: - Input & Output Type
  struct Input {
    let viewDidLoad: Observable<Void>
    let refresh: Observable<Void>
    let manualLocationSelected: Observable<(CLLocationCoordinate2D, String)>
    let resetToCurrentLocation: Observable<Void>
  }
  
  struct Output {
    let hospitals: Driver<[Hospital]>
    let isLoading: Driver<Bool>
    let error: Driver<String?>
    let userLocation: Driver<CLLocationCoordinate2D>
    let shouldShowAddressSearch: Driver<Bool>
    let selectedAddressName: Driver<String?>
  }
  
  // MARK: - Properties
  private let locationManager = CLLocationManager()
  private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
  private let errorRelay = BehaviorRelay<String?>(value: nil)
  let hospitalsRelay = BehaviorRelay<[Hospital]>(value: [])
  private let userLocationRelay = BehaviorRelay<CLLocationCoordinate2D>(value: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)) // 서울 기본값
  private let shouldShowAddressSearchRelay = BehaviorRelay<Bool>(value: false)
  private let selectedAddressNameRelay = BehaviorRelay<String?>(value: nil)
  private let isUsingCurrentLocationRelay = BehaviorRelay<Bool>(value: true)
  
  // MARK: - Initialization
  override init() {
    super.init()
    setupLocationManager()
  }
  
  // MARK: - Input-Output Transform
  func transform(input: Input) -> Output {
    // 화면 로드 시 위치 권한 요청
    input.viewDidLoad
      .subscribe(onNext: { [weak self] in
        self?.checkDeviceLocation()
      })
      .disposed(by: disposeBag)
    
    // 새로고침 시 데이터 다시 로드
    input.refresh
      .subscribe(onNext: { [weak self] in
        self?.fetchHospitals()
      })
      .disposed(by: disposeBag)
    
    // 수동으로 위치 선택된 경우
    input.manualLocationSelected
        .subscribe(onNext: { [weak self] coordinate, addressName in
            guard let self = self else { return }
            
            self.isUsingCurrentLocationRelay.accept(false)
            self.userLocationRelay.accept(coordinate)
            self.selectedAddressNameRelay.accept(addressName)
            
            // 로딩 표시 확실히 표시
            self.isLoadingRelay.accept(true)
            
            // 병원 검색
            self.searchHospitalsNear(latitude: coordinate.latitude, longitude: coordinate.longitude)
        })
        .disposed(by: disposeBag)
    
    input.resetToCurrentLocation
      .subscribe(onNext: { [weak self] in
        self?.resetToCurrentLocation()
      })
      .disposed(by: disposeBag)
    
    return Output(
      hospitals: hospitalsRelay.asDriver(),
      isLoading: isLoadingRelay.asDriver(),
      error: errorRelay.asDriver(),
      userLocation: userLocationRelay.asDriver(),
      shouldShowAddressSearch: shouldShowAddressSearchRelay.asDriver(),
      selectedAddressName: selectedAddressNameRelay.asDriver()
    )
  }
  
  func resetToCurrentLocation() {
    isUsingCurrentLocationRelay.accept(true)
    isLoadingRelay.accept(true)
    selectedAddressNameRelay.accept(nil)
    
    // 위치 서비스 확인을 비동기적으로 처리
    DispatchQueue.global().async { [weak self] in
      // 시스템 위치 서비스 활성화 여부 확인
      if CLLocationManager.locationServicesEnabled() {
        DispatchQueue.main.async {
          self?.handleLocationServicesEnabled()
        }
      } else {
        DispatchQueue.main.async {
          self?.errorRelay.accept("위치 서비스가 비활성화되어 있습니다.")
          self?.isLoadingRelay.accept(false)
        }
      }
    }
  }
  
  // 위치 서비스가 활성화된 경우 처리하는 메서드 분리
  private func handleLocationServicesEnabled() {
    switch locationManager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.startUpdatingLocation()
    default:
      checkCurrentAuthorizationStatus()
    }
  }
  
  // MARK: - Private Methods
  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
  }
  
  // 위치 서비스 확인 및 권한 요청
  private func checkDeviceLocation() {
    isLoadingRelay.accept(true)
    
    // 시스템 위치 서비스 활성화 여부 확인
    if CLLocationManager.locationServicesEnabled() {
      checkCurrentAuthorizationStatus()
    } else {
      // 위치 서비스가 비활성화된 경우
      shouldShowAddressSearchRelay.accept(true)
      errorRelay.accept("위치 서비스가 꺼져 있어 위치 권한을 요청할 수 없습니다. 주소 검색으로 전환합니다.")
      isLoadingRelay.accept(false)
    }
  }
  
  // 현재 위치 권한 상태 확인
  private func checkCurrentAuthorizationStatus() {
    let status = locationManager.authorizationStatus
    
    switch status {
    case .notDetermined:
      // 아직 결정되지 않은 상태 - 권한 요청
      locationManager.requestWhenInUseAuthorization()
      locationManager.desiredAccuracy = kCLLocationAccuracyBest
      
    case .denied, .restricted:
      // 거부된 상태 - 주소 검색 UI로 전환
      shouldShowAddressSearchRelay.accept(true)
      errorRelay.accept("위치 권한이 거부되었습니다. 주소 검색으로 전환합니다.")
      isLoadingRelay.accept(false)
      
      // 기본 서울 위치 사용
      searchHospitalsNear(latitude: 37.5665, longitude: 126.9780)
      
    case .authorizedWhenInUse, .authorizedAlways:
      // 권한 허용 상태 - 위치 업데이트 시작
      locationManager.startUpdatingLocation()
      
    @unknown default:
      // 알 수 없는 상태 - 주소 검색 UI로 전환
      shouldShowAddressSearchRelay.accept(true)
      errorRelay.accept("알 수 없는 위치 권한 상태입니다. 주소 검색으로 전환합니다.")
      isLoadingRelay.accept(false)
      
      // 기본 서울 위치 사용
      searchHospitalsNear(latitude: 37.5665, longitude: 126.9780)
    }
  }
  
  // MARK: - Public Methods
  func fetchHospitals() {
    checkDeviceLocation()
  }
  
  private func searchHospitalsNear(latitude: Double, longitude: Double) {
    isLoadingRelay.accept(true)
    
    // 카카오맵 API를 사용하여 병원 검색
    Task {
      do {
        let hospitals = try await KakaoMapManager.shared.searchHospitals(
          latitude: latitude,
          longitude: longitude
        )
        
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          
          self.hospitalsRelay.accept(hospitals)
          self.isLoadingRelay.accept(false) // 로딩 인디케이터 비활성화
          
          if hospitals.isEmpty {
            self.errorRelay.accept("주변에 24시 동물병원이 없습니다.")
          } else {
            self.errorRelay.accept(nil)
          }
        }
      } catch {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          
          self.hospitalsRelay.accept([])
          self.isLoadingRelay.accept(false) // 오류 발생 시에도 로딩 인디케이터 비활성화
          self.errorRelay.accept("병원 검색 중 오류가 발생했습니다: \(error.localizedDescription)")
        }
      }
    }
  }
  
  func requestLocationPermission() {
    locationManager.requestWhenInUseAuthorization()
  }
}

// MARK: - CLLocationManagerDelegate
extension LocationSearchViewModel: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.last {
      userLocationRelay.accept(location.coordinate)
      
      // 현재 위치 사용 중일 때만 현재 위치 기반 검색
      if isUsingCurrentLocationRelay.value {
        searchHospitalsNear(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
      }
      
      manager.stopUpdatingLocation()
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // 위치 가져오기 실패 시
    isLoadingRelay.accept(false) // 로딩 인디케이터 비활성화
    errorRelay.accept("위치 정보를 가져오는데 실패했습니다.")
    shouldShowAddressSearchRelay.accept(true)
    
    // 기본 서울 위치 사용
    searchHospitalsNear(latitude: 37.5665, longitude: 126.9780)
  }
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    // iOS 14+ 에서 권한 상태 변경 시 호출
    checkCurrentAuthorizationStatus()
  }
}
