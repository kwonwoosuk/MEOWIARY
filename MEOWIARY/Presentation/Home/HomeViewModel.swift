//
//  HomeViewModel.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

struct ToggleButtonStyle {
  let title: String
  let backgroundColor: UIColor
  let titleColor: UIColor
  let borderWidth: CGFloat
  let borderColor: CGColor?
}

class HomeViewModel: BaseViewModel {
  
  // MARK: - BaseViewModel
  var disposeBag = DisposeBag()
  
  // MARK: - Input과 Output 타입 정의
  struct Input {
    let viewDidLoad: Observable<Void>
    let yearNavPrev: Observable<Void>
    let yearNavNext: Observable<Void>
    let toggleViewTap: Observable<Void>
  }
  
  struct Output {
    let currentYear: Driver<String>
    let currentMonth: Driver<Int>
    let isShowingSymptoms: Driver<Bool>
    let toggleButtonStyle: Driver<ToggleButtonStyle>
    let weatherInfo: Driver<Weather?>
  }
  
  // MARK: - Private Properties
  let yearSubject = BehaviorRelay<Int>(value: Calendar.current.component(.year, from: Date()))
  private let monthSubject = BehaviorRelay<Int>(value: Calendar.current.component(.month, from: Date()))
  let isShowingSymptomsSubject = BehaviorRelay<Bool>(value: false)
  private let weatherInfoRelay = BehaviorRelay<Weather?>(value: nil)
  private let dayCardRepository: DayCardRepository
  private let weatherService: WeatherService
  
  // MARK: - Initialization
  init(dayCardRepository: DayCardRepository = DayCardRepository(),
       weatherService: WeatherService = WeatherService()) {
    self.dayCardRepository = dayCardRepository
    self.weatherService = weatherService
    
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: Date())
    let currentMonth = calendar.component(.month, from: Date())
    
    self.yearSubject.accept(currentYear)
    self.monthSubject.accept(currentMonth)
    
    print("Initial year set to: \(currentYear), month: \(currentMonth)")
  }
  
  // MARK: - Input-Output Transform
  func transform(input: Input) -> Output {
    // 연도 이전 버튼 액션
    input.yearNavPrev
      .subscribe(onNext: { [weak self] in
        self?.decrementYear()
      })
      .disposed(by: disposeBag)
    
    // 연도 다음 버튼 액션
    input.yearNavNext
      .subscribe(onNext: { [weak self] in
        self?.incrementYear()
      })
      .disposed(by: disposeBag)
    
    // 토글 버튼 액션
    input.toggleViewTap
      .subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        let currentValue = self.isShowingSymptomsSubject.value
        self.isShowingSymptomsSubject.accept(!currentValue)
      })
      .disposed(by: disposeBag)
    
    // 화면 로드 시 초기 데이터 로드
    input.viewDidLoad
      .subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        Task {
          await self.fetchData()
        }
      })
      .disposed(by: disposeBag)
    
    // 토글 버튼 스타일 설정
    let toggleButtonStyle = isShowingSymptomsSubject
      .map { isShowing -> ToggleButtonStyle in
        if isShowing {
          return ToggleButtonStyle(
            title: "사진 기록 보기",
            backgroundColor: .white,
            titleColor: UIColor(hex: DesignSystem.Color.Tint.text.rawValue),
            borderWidth: 1.0,
            borderColor: UIColor.lightGray.cgColor
          )
        } else {
          return ToggleButtonStyle(
            title: "증상 기록 보기",
            backgroundColor: UIColor(hex: DesignSystem.Color.Tint.main.rawValue),
            titleColor: .white,
            borderWidth: 0,
            borderColor: nil
          )
        }
      }
    
    return Output(
      currentYear: yearSubject
        .map { String($0) }
        .distinctUntilChanged()
        .do(onNext: { year in
        })
        .asDriver(onErrorJustReturn: "\(Calendar.current.component(.year, from: Date()))"),
      currentMonth: monthSubject.asDriver(onErrorJustReturn: 1),
      isShowingSymptoms: isShowingSymptomsSubject.asDriver(onErrorJustReturn: false),
      toggleButtonStyle: toggleButtonStyle.asDriver(onErrorJustReturn: ToggleButtonStyle(
        title: "증상 기록 보기",
        backgroundColor: UIColor(hex: DesignSystem.Color.Tint.main.rawValue),
        titleColor: .white,
        borderWidth: 0,
        borderColor: nil
      )),
      weatherInfo: weatherInfoRelay.asDriver(onErrorJustReturn: nil)
    )
  }
  
  // MARK: - Private Methods
  private func incrementYear() {
    let newYear = yearSubject.value + 1
    yearSubject.accept(newYear)
    Task {
      await fetchData()
    }
  }
  
  private func decrementYear() {
    let newYear = yearSubject.value - 1
    yearSubject.accept(newYear)
    Task {
      await fetchData()
    }
  }
  
  private func incrementMonth() {
    var newMonth = monthSubject.value + 1
    var newYear = yearSubject.value
    
    if newMonth > 12 {
      newMonth = 1
      newYear += 1
      yearSubject.accept(newYear)
    }
    
    monthSubject.accept(newMonth)
    Task {
      await fetchData()
    }
  }
  
  private func decrementMonth() {
    var newMonth = monthSubject.value - 1
    var newYear = yearSubject.value
    
    if newMonth < 1 {
      newMonth = 12
      newYear -= 1
      yearSubject.accept(newYear)
    }
    
    monthSubject.accept(newMonth)
    Task {
      await fetchData()
    }
  }
  
    private func toggleView() {
        let currentValue = isShowingSymptomsSubject.value
        isShowingSymptomsSubject.accept(!currentValue)
        
        // 토글 후 적절한 데이터 로드
        if !currentValue { // 증상 모드로 변경됨
            print("증상 기록 모드 활성화")
        } else { // 일반 모드로 변경됨
            print("일반 기록 모드 활성화")
        }
    }
    func fetchData() async {
        let year = yearSubject.value
        let month = monthSubject.value
        
        await fetchWeatherData()
        
        if isShowingSymptomsSubject.value {
            fetchSymptomRecords(year: year, month: month)
        } else {
            fetchDayCardData(year: year, month: month)
        }
    }
  private func fetchWeatherData() async {
    let result = await weatherService.fetchCurrentWeather()
    
    switch result {
    case .success(let weather):
      // 날씨 데이터 가져오기 성공
      print("Weather fetched: \(weather)")
      DispatchQueue.main.async { [weak self] in
        self?.weatherInfoRelay.accept(weather)
      }
    case .failure(let error):
      // 날씨 데이터 가져오기 실패
      print("Error fetching weather: \(error)")
    }
  }
  
  private func fetchDayCardData(year: Int, month: Int) {
      // Realm에서 해당 월의 DayCard 가져오기
    let dayCards = dayCardRepository.getDayCardsMapForMonth(year: year, month: month)

      
      // 데이터 처리 및 UI 업데이트를 위한 내용 추가 가능
      print("Fetched \(dayCards.count) DayCards for \(year)-\(month)")
  }
  
    private func fetchSymptomRecords(year: Int, month: Int) {
        // Realm에서 증상 기록 가져오기
        let records = dayCardRepository.getSymptomRecords(year: year, month: month)
        
        // 증상 기록 갯수 로깅
        var totalSymptoms = 0
        for (_, symptoms) in records {
            totalSymptoms += symptoms.count
        }
        print("월간 증상 기록 로드: \(year)년 \(month)월 - 총 \(totalSymptoms)개 증상")
        
        // 증상 모드가 활성화되었을 때 UI 업데이트를 위해 사용
        if isShowingSymptomsSubject.value {
            // 캘린더 뷰에 증상 데이터 전달 (View Controller에서 처리)
        }
    }

}
