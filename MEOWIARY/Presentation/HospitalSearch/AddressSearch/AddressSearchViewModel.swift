//
//  AddressSearchViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

final class AddressSearchViewModel: BaseViewModel {
    
  deinit {
      print("AddressSearchViewModel deinit 호출됨")
  }
  
    // MARK: - BaseViewModel
    var disposeBag = DisposeBag()
    
    // MARK: - Input & Output Type
    struct Input {
        let searchQuery: Observable<String>
        let searchButtonClicked: Observable<Void>
    }
    
    struct Output {
        let addressResults: Driver<[AddressDocument]>
        let isSearching: Driver<Bool>
        let error: Driver<String?>
    }
    
    // MARK: - Properties
    private let addressResultsRelay = BehaviorRelay<[AddressDocument]>(value: [])
    private let isSearchingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private let searchTextRelay = BehaviorRelay<String>(value: "")
    
    // MARK: - Input-Output Transform
    func transform(input: Input) -> Output {
        // 검색어 바인딩
        input.searchQuery
            .bind(to: searchTextRelay)
            .disposed(by: disposeBag)
        
        // 검색 버튼 클릭 또는 검색어 변경 시 검색 수행
        Observable.merge(
            input.searchButtonClicked,
            input.searchQuery
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .filter { !$0.isEmpty }
                .map { _ in () }
        )
        .subscribe(onNext: { [weak self] in
            self?.searchAddress()
        })
        .disposed(by: disposeBag)
        
        return Output(
            addressResults: addressResultsRelay.asDriver(),
            isSearching: isSearchingRelay.asDriver(),
            error: errorRelay.asDriver()
        )
    }
    
    // MARK: - Private Methods
    private func searchAddress() {
        let query = searchTextRelay.value
        
        guard !query.isEmpty else {
            addressResultsRelay.accept([])
            return
        }
        
        isSearchingRelay.accept(true)
        
        Task {
            do {
                let results = try await KakaoMapManager.shared.searchAddress(query: query)
                
                DispatchQueue.main.async { [weak self] in
                    self?.addressResultsRelay.accept(results)
                    self?.isSearchingRelay.accept(false)
                    
                    // 주소 검색 결과 Analytics 추가
                    AnalyticsService.shared.logAddressSearch(
                        query: query,
                        resultsCount: results.count
                    )
                    
                    if results.isEmpty {
                        self?.errorRelay.accept("검색 결과가 없습니다.")
                    } else {
                        self?.errorRelay.accept(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.addressResultsRelay.accept([])
                    self?.isSearchingRelay.accept(false)
                    self?.errorRelay.accept("검색 중 오류가 발생했습니다: \(error.localizedDescription)")
                    
                    // 검색 실패 Analytics 추가
                    AnalyticsService.shared.logAddressSearch(
                        query: query,
                        resultsCount: 0
                    )
                }
            }
        }
    }
}
