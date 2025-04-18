# 📝🐈MEOWIARY

반려묘 일상 사진기록을 남기고 증상을 간편하게 관리할 수 있는 앱입니다

<div align="center">
    
| 인앱 스크린샷 |
|:---:|
| <img width="1000" alt="새싹 스토어 제출 앱사진" src="https://github.com/user-attachments/assets/6790b609-d965-479d-a7e2-e73eed61db1d" /> | 

</div>



## 📋 목차

- 프로젝트 소개
- 주요기능
- 기술 스택
- 프로젝트 구조
- 주요 구현 내용
- 트러블 슈팅

## 프로젝트 소개

MEOWIARY는 반려묘의 일상을 기록하고 건강 상태를 관리할 수 있는 앱입니다.  
사용자는 반려묘의 일상을 사진과 함께 기록하고, 증상을 간편하게 관리하며  
응급상황시 빠르게 주변 24시 동물병원을 검색할 수 있습니다.  
월별 캘린더 기능을 통해 기록을 한눈에 확인할 수 있으며  
증상의 심각도와 특징을 쉽게 기록할 수 있습니다. 

## ⭐️ 주요 기능


- **일상 기록**: 반려묘의 일상을 사진과 함께 기록
- **증상 관리**: 반려묘의 건강 이상 증상을 심각도와 함께 기록
- **캘린더 뷰**: 월별 기록을 캘린더 형태로 확인
- **24시 병원 검색**: 위치 기반 주변 24시 동물병원 검색
- **이미지 관리**: 갤러리 형태로 기록된 사진 모아보기
- **미디어 생성**: 다중 이미지로 GIF/동영상 생성

## 🛠 기술 스택


![image](https://github.com/user-attachments/assets/413ab3d1-3fd2-4b21-93ae-0befe5af92f9)





- **언어 및 프레임워크**: Swift, UIKit
- **아키텍처**: MVVM + RxSwift Input/Output 패턴
- **UI 레이아웃**: SnapKit
- **네트워크 통신**: URLSession + Swift Concurrency (async/await)
- **비동기 프로그래밍**: RxSwift, RxCocoa
- **지도 서비스**: Kakao Maps API
- **로컬 데이터베이스**: RealmSwift
- **이미지 처리**: AVFoundation, PhotosUI

## 프로젝트 구조

```
MEOWIARY/
├── Models/
│   ├── Realm Models/
│   │   ├── DayCard.swift
│   │   ├── ImageRecord.swift
│   │   ├── Symptom.swift
│   │   ├── SymptomImage.swift
│   │   └── ...
│   └── API Models/
│       ├── Weather.swift
│       ├── Hospital.swift
│       └── KakaoAPIModels.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── DetailViewModel.swift
│   ├── GalleryViewModel.swift
│   ├── DailyDiaryViewModel.swift
│   ├── SymptomRecordViewModel.swift
│   └── ...
├── Views/
│   ├── Controllers/
│   │   ├── MWTabBarController.swift
│   │   ├── HomeViewController.swift
│   │   ├── DailyDiaryViewController.swift
│   │   ├── SymptomRecordViewController.swift
│   │   ├── GalleryViewController.swift
│   │   ├── DetailViewController.swift
│   │   └── ...
│   ├── Cells/
│   │   ├── GalleryCell.swift
│   │   ├── CardCell.swift
│   │   ├── ImageCell.swift
│   │   └── ...
│   └── Common/
│       ├── BaseView.swift
│       ├── BaseViewController.swift
│       ├── NavigationBarView.swift
│       └── ...
├── Utils/
│   ├── Extensions/
│   │   ├── UIColor+Extension.swift
│   │   ├── UILabel+Date.swift
│   │   ├── UIViewController+Extension.swift
│   │   └── ...
│   ├── Constants/
│   │   ├── DesignSystem.swift
│   │   ├── Constants.swift
│   │   └── ...
├── Services/
│   ├── Network/
│   │   ├── NetworkManager.swift
│   │   ├── WeatherService.swift
│   │   ├── KakaoMapManager.swift
│   │   └── ...
│   └── Database/
│       ├── DayCardRepository.swift
│       ├── ImageRecordRepository.swift
│       ├── SymptomRepository.swift
│       └── ...
└── Resources/
    ├── Assets.xcassets
    └── Info.plist

```

## 🔍 주요 구현 내용

### 1. MVVM + RxSwift Input/Output 패턴

모든 ViewModel은 `BaseViewModel` 프로토콜을 준수하여 일관된 아키텍처를 유지했습니다.

```swift
protocol BaseViewModel {
    var disposeBag: DisposeBag { get }

    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

```

각 ViewModel은 이 패턴을 준수하여 뷰와 비즈니스 로직을 명확히 분리했습니다.

```swift
// HomeViewModel 예시
class HomeViewModel: BaseViewModel {
    var disposeBag = DisposeBag()

    // 현재 연도와 월 관리를 위한 Subject
    let yearSubject = BehaviorRelay<Int>(value: Calendar.current.component(.year, from: Date()))
    let monthSubject = BehaviorRelay<Int>(value: Calendar.current.component(.month, from: Date()))
    let isShowingSymptomsSubject = BehaviorRelay<Bool>(value: false)
    private let weatherInfoRelay = BehaviorRelay<Weather?>(value: nil)

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

    func transform(input: Input) -> Output {
        // Input 이벤트를 처리하여 Output으로 변환
        input.yearNavPrev
            .subscribe(onNext: { [weak self] in
                self?.decrementYear()
            })
            .disposed(by: disposeBag)

        // 다른 Input 이벤트 처리...

        return Output(
            currentYear: yearSubject.map { String($0) }.asDriver(onErrorJustReturn: ""),
            currentMonth: monthSubject.asDriver(),
            isShowingSymptoms: isShowingSymptomsSubject.asDriver(),
            toggleButtonStyle: isShowingSymptomsSubject.asDriver(onErrorJustReturn: defaultStyle),
            weatherInfo: weatherInfoRelay.asDriver()
        )
    }
}

```

### 2. 공통 UI 컴포넌트 관리

중복되는 UI 요소는 베이스 클래스로 추상화하여 재사용성을 높였습니다.

```swift
// UI 컴포넌트의 기본 레이아웃 설정을 위한 BaseView
class BaseView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() { }
}

// ViewController의 공통 설정을 위한 BaseViewController
class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureHierarchy()
        configureLayout()
        configureView()
        bind()
        setupKeyboardDismissGesture()
    }

    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() { }
    func bind() { }

    func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

```

### 3. 디자인 시스템 구현

일관된 디자인 요소를 위한 디자인 시스템을 열거형으로 구현했습니다.

```swift
enum DesignSystem {
    enum Color {
        enum Tint: String {
            case main = "FF6A6A"
            case action = "42A5F5"
            case lightGray = "F2F2F2"
            case text = "333333"
            case darkGray = "666666"
            // ...

            func inUIColor() -> UIColor {
                return UIColor(hex: self.rawValue)
            }
        }

        enum Background: String {
            case main = "FFFFFF"
            case card = "63C7FE"
            case lightBlue = "E3F2FD"
            // ...

            func inUIColor() -> UIColor {
                return UIColor(hex: self.rawValue)
            }
        }

        enum Status: String {
            case negative1 = "9E9E9E"   // 경증 (회색)
            case negative2 = "f0e936"   // 구토 (노란색)
            case negative3 = "FF9800"   // 경고 (주황색)
            case negative4 = "F44336"   // 중증 (빨간색)
            case negative5 = "7a1c1a"   // 혈변등 (갈색)

            func inUIColor() -> UIColor {
                return UIColor(hex: self.rawValue)
            }
        }
    }

    enum Font {
        enum Size {
            static let small: CGFloat = 12
            static let regular: CGFloat = 14
            static let medium: CGFloat = 16
            static let large: CGFloat = 22
            static let extraLarge: CGFloat = 32
        }

        enum Weight {
            static func regular(size: CGFloat) -> UIFont {
                return .systemFont(ofSize: size)
            }

            static func bold(size: CGFloat) -> UIFont {
                return .boldSystemFont(ofSize: size)
            }
        }
    }

    enum Layout {
        static let standardMargin: CGFloat = 20
        static let smallMargin: CGFloat = 10
        static let cornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 20
    }
}

```

### 4. 레이아웃 대응성 향상

다양한 화면 크기에 대응하는 레이아웃 설계를 구현했습니다.

```swift
// 기기 특성에 따른 레이아웃 조정
extension DesignSystem {
    enum Device {
        enum ScreenType {
            case small      // iPhone SE, 5.4인치 미만 (height <= 667)
            case medium     // iPhone 8 Plus ~ iPhone 13, 5.5~6.1인치 (667 < height <= 844)
            case large      // iPhone 13 Pro Max 이상, 6.5인치 이상 (844 < height)

            static var current: ScreenType {
                let height = UIScreen.main.bounds.height
                if height <= 667 {
                    return .small
                } else if height <= 844 {
                    return .medium
                } else {
                    return .large
                }
            }
        }

        static var isSmallScreen: Bool {
            return ScreenType.current == .small
        }

        static var isMediumnScreen: Bool {
            return ScreenType.current == .medium
        }

        static var isLargeScreen: Bool {
            return ScreenType.current == .large
        }
    }
}

// 레이아웃 설정 예시
private func configureLayout() {
    let isSmallScreen = DesignSystem.Device.isSmallScreen

    dateLabel.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
        make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
    }

    photoButton.snp.makeConstraints { make in
        make.top.equalTo(dayOfWeekLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
        make.leading.trailing.equalTo(dateLabel)
        make.height.equalTo(isSmallScreen ? 150 : 180) // 화면 크기에 따른 높이 조정
    }
}

```

### 5. 네트워크 계층 설계

Swift Concurrency를 활용한 네트워크 통신 계층을 설계했습니다.

```swift
// 네트워크 매니저
final class NetworkManager {

    // MARK: - Properties
    static let shared = NetworkManager()

    private init() {}

    private let session = URLSession.shared

    // MARK: - Public Methods

    /// 비동기 데이터 요청 (Swift Concurrency)
    func request<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil,
        httpMethod: String = "GET",
        headers: [String: String]? = nil
    ) async throws -> T {

        // URL 생성
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        // 요청 생성
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod

        // 기본 헤더 설정
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 추가 헤더 설정
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // 요청 전송 및 응답 처리
        do {
            let (data, response) = try await session.data(for: request)

            // HTTP 상태 코드 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "HTTPResponse", code: -1))
            }

            // 성공 상태 코드 확인 (200-299)
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            // 데이터 디코딩
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                return decodedData
            } catch {
                throw NetworkError.decodingError
            }
        } catch let urlError as URLError {
            throw NetworkError.unknown(urlError)
        } catch {
            throw error
        }
    }
}

```

### 6. RealmSwift를 활용한 저장소 패턴

로컬 데이터베이스 작업을 위한 저장소 패턴을 구현했습니다.

```swift
// DayCard 저장소
class DayCardRepository: DayCardRepositoryProtocol {
    // 필요할 때마다 새로운 Realm 인스턴스 생성
    private func getRealm() -> Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }

    // DayCard 저장
    func saveDayCard(_ dayCard: DayCard) -> Observable<DayCard> {
        return Observable.create { observer in
            let realm = self.getRealm()

            do {
                try realm.write {
                    realm.add(dayCard, update: .modified)
                    print("DayCard 저장 성공: \(dayCard.id)")
                }
                observer.onNext(dayCard)
                observer.onCompleted()
            } catch {
                print("DayCard 저장 실패: \(error)")
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    // 특정 날짜의 DayCard 조회
    func getDayCardForDate(year: Int, month: Int, day: Int) -> DayCard? {
        let realm = getRealm()
        return realm.objects(DayCard.self)
            .filter("year == %@ AND month == %@ AND day == %@", year, month, day)
            .first
    }

    // 월별 DayCard 조회
    func getDayCards(year: Int, month: Int) -> [DayCard] {
        let realm = getRealm()
        let results = realm.objects(DayCard.self)
            .filter("year == %@ AND month == %@", year, month)
            .sorted(byKeyPath: "day")
        return Array(results)
    }

    // 이미지 레코드 추가
    func addImageRecord(_ imageRecords: [ImageRecord], to dayCard: DayCard) -> Observable<Void> {
        return Observable.create { observer in
            let realm = self.getRealm()

            guard let localDayCard = realm.object(ofType: DayCard.self, forPrimaryKey: dayCard.id) else {
                observer.onError(NSError(domain: "DayCard not found", code: -1, userInfo: nil))
                return Disposables.create()
            }

            do {
                try realm.write {
                    for imageRecord in imageRecords {
                        localDayCard.imageRecords.append(imageRecord)
                    }
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }
}

```

### 7. 캘린더 카드 뷰 구현

월별 기록을 볼 수 있는 플립 가능한 캘린더 카드 뷰를 구현했습니다.

```swift
// CardCell.swift (일부)
func flipToCalendar(animated: Bool = true) {
    // 이미 뒤집힌 상태면 종료
    if isFlipped {
        return
    }

    saveDisplayMode()

    if animated {
        // 애니메이션 옵션 - 일정한 속도로 뒤집기
        UIView.transition(
            with: self.contentView,
            duration: 0.4,
            options: [.transitionFlipFromLeft, .allowUserInteraction, .curveLinear],
            animations: {
                self.containerView.isHidden = true
                self.calendarContainerView.isHidden = false
            },
            completion: { _ in
                self.isFlipped = true
                print("CardCell: \(self.month)월 카드 뒤집기 애니메이션 완료")
            }
        )
    } else {
        // 애니메이션 없이 즉시 상태 변경
        containerView.isHidden = true
        calendarContainerView.isHidden = false
        isFlipped = true
    }
}

func createCalendarGrid(with dayCardData: [Int: DayCard] = [:]) {
    let calendar = Calendar.current

    // 월의 첫번째 날짜와 일수 계산
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = 1

    guard let firstDayOfMonth = calendar.date(from: components) else { return }

    // 첫 번째 요일 (1: 일요일, 2: 월요일, ..., 7: 토요일)
    let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
    let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30

    let isSmallScreen = UIScreen.main.bounds.height <= 667 // iPhone SE, iPhone 8

    // 그리드 생성을 위한 크기 계산
    let gridWidth = calendarGridView.bounds.width
    let buttonWidth = gridWidth / 7.0
    let buttonHeight = isSmallScreen ? buttonWidth * 0.9 : buttonWidth

    // 첫 번째 요일 조정 (0-based: 0 = 일요일, ..., 6 = 토요일)
    let firstWeekdayIndex = firstWeekday - 1

    // 각 날짜별 버튼 생성
    for day in 1...numberOfDaysInMonth {
        // 요일 계산 (0: 일요일, 1: 월요일, ..., 6: 토요일)
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else { continue }
        let weekday = calendar.component(.weekday, from: date) - 1

        // 주차 계산 (0: 첫째 주, 1: 둘째 주, ...)
        let weekOfMonth = (day + firstWeekdayIndex - 1) / 7

        // 버튼 생성 및 배치
        let dayButton = createDayButton(day: day, weekday: weekday)
        dayButton.frame = CGRect(
            x: CGFloat(weekday) * buttonWidth,
            y: CGFloat(weekOfMonth) * buttonHeight,
            width: buttonWidth,
            height: buttonHeight
        )

        calendarGridView.addSubview(dayButton)

        // 오늘 날짜 표시
        if day == Calendar.current.component(.day, from: Date()) &&
            month == Calendar.current.component(.month, from: Date()) &&
            year == Calendar.current.component(.year, from: Date()) {
            addTodayIndicator(to: dayButton)
        }

        // 데이터가 있는 날짜 표시
        if let dayCard = dayCardData[day] {
            if isShowingSymptoms {
                // 증상 모드: 심각도에 따른 표시
                if !dayCard.symptoms.isEmpty {
                    let maxSeverity = dayCard.symptoms.max { $0.severity < $1.severity }?.severity ?? 1
                    addSymptomIndicator(to: dayButton, severity: maxSeverity)
                }
            } else {
                // 일반 모드: 이미지 표시
                if !dayCard.imageRecords.isEmpty,
                   let imageRecord = dayCard.imageRecords.first,
                   let thumbnailPath = imageRecord.thumbnailImagePath {
                    addImageIndicator(to: dayButton, imagePath: thumbnailPath)
                }
            }
        }
    }
}

```

## 🚨 트러블슈팅

### 1. 이미지 처리 및 메모리 최적화

**문제 상황**

- 사용자가 여러 고해상도 이미지를 앱에 저장하면서 메모리 사용량이 급증하는 문제가 발생했습니다.
- 특히 갤러리 뷰에서 스크롤할 때 메모리 누수와 지연 현상이 두드러졌습니다.

**해결 방법**

- 이미지를 원본과 썸네일로 나누어 저장하고, 상황에 맞게 적절한 크기의 이미지를 로드하도록 구현했습니다.
- 이미지 캐싱 시스템을 도입하여 불필요한 디스크 I/O를 줄였습니다.
- 이미지 로딩을 비동기적으로 처리하고, 화면에서 벗어난 이미지는 메모리에서 해제하도록 했습니다.

```swift
// ImageManager 클래스의 최적화된 이미지 로드 메서드
func loadThumbnailImage(from imagePath: String?) -> UIImage? {
    guard let imagePath = imagePath else { return nil }

    // 캐시에 있으면 캐시에서 반환
    if let cachedImage = imageCache[imagePath] {
        return cachedImage
    }

    let fileURL = getThumbnailImagesDirectory().appendingPathComponent(imagePath)

    if let data = try? Data(contentsOf: fileURL),
       let image = UIImage(data: data) {
        // 캐시에 저장
        imageCache[imagePath] = image
        return image
    }

    return UIImage(systemName: "photo")
}

// ViewController에서 리소스 관리
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    // 화면을 벗어날 때 리소스 정리
    if isBeingDismissed || isMovingFromParent {
        imageCache.removeAll()
    }
}

```

### 2. 복잡한 뷰 전환 및 상태 관리

**문제 상황**

- 홈 화면의 카드 뷰와 캘린더 뷰 간 전환 시 애니메이션과 상태 유지에 문제가 발생했습니다.
- 특히 여러 개의 카드가 동시에 플립되는 과정에서 타이밍 이슈와 비동기 처리 문제가 나타났습니다.

**해결 방법**

- 상태 변경 로직과 애니메이션 로직을 명확히 분리했습니다.
- 애니메이션의 완료 시점에 상태를 업데이트하는 콜백 패턴을 도입했습니다.
- DispatchQueue를 활용하여 애니메이션 타이밍을 제어했습니다.

```swift
func flipAllToCalendar() {
    // 이미 캘린더 모드면 무시
    guard !isCalendarMode else { return }

    // 먼저 애니메이션 시작
    cardCalendarView.flipAllToCalendar()

    // 애니메이션 도중(약간의 지연 시간)에 버튼 상태 변경
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        guard let self = self else { return }

        UIView.animate(withDuration: 0.2) {
            self.calendarButton.isHidden = true
            self.backButton.isHidden = false
            self.view.layoutIfNeeded()
        }
    }

    // 데이터 갱신 - 애니메이션 완료 후 호출
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        guard let self = self else { return }

        // 데이터 갱신 명시적으로 재호출
        if let currentMonth = self.cardCalendarView.getCurrentMonth() {
            self.cardCalendarView.updateData(year: self.viewModel.yearSubject.value, month: currentMonth)
        }
    }
}

```

### 3. Realm 데이터 삭제 시 참조 무결성 문제

**문제 상황**

- DayCard와 연결된 이미지 또는 증상 기록을 삭제할 때, 관련 파일이 디스크에 남아있는 문제가 발생했습니다.
- 또한, 데이터 삭제 후 UI 갱신이 즉시 이루어지지 않아 사용자에게 혼란을 주었습니다.

**해결 방법**

- Realm 객체 삭제 전에 관련 파일 경로를 미리 안전하게 복사해두는 패턴을 적용했습니다.
- 파일 삭제 작업은 백그라운드 스레드에서 비동기적으로 처리하되, UI 갱신은 메인 스레드에서 즉시 진행했습니다.
- 알림 시스템(NotificationCenter)을 활용하여 데이터 변경 사항을 앱 전체에 전파했습니다.

```swift
func deleteCurrentDayCards() -> Observable<Void> {
    // 현재 날짜의 DayCard ID들을 먼저 가져옵니다
    let dayCards = dayCardRepository.getDayCards(year: year, month: month)
    let targetDayCards = dayCards.filter { $0.day == day }

    if targetDayCards.isEmpty {
        return Observable.error(NSError(domain: "DetailViewModel",
                                       code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "삭제할 DayCard를 찾을 수 없습니다"]))
    }

    // 객체 참조 대신 ID만 저장
    let dayCardIDs = targetDayCards.map { $0.id }

    // ID를 기반으로 삭제 요청
    return dayCardRepository.deleteDayCardsByIDs(dayCardIDs)
        .do(onNext: { _ in
            // 삭제 성공 시 알림 발송
            NotificationCenter.default.post(
                name: Notification.Name(ImageDeletedNotification),
                object: nil
            )
        })
}

// DayCardRepository 구현
func deleteDayCardsByIDs(_ ids: [String]) -> Observable<Void> {
    return Observable.create { observer in
        let realm = self.getRealm()

        do {
            // 트랜잭션 시작
            try realm.write {
                for id in ids {
                    guard let dayCard = realm.object(ofType: DayCard.self, forPrimaryKey: id) else {
                        print("DayCardRepository: 경고 - ID \(id)에 해당하는 DayCard를 찾을 수 없음")
                        continue
                    }

                    // 증상 데이터 가져오기 및 삭제
                    let symptoms = Array(dayCard.symptoms)
                    realm.delete(symptoms)

                    // 이미지 레코드 가져오기 및 삭제
                    let imageRecords = Array(dayCard.imageRecords)

                    // 파일 시스템의 이미지 파일 삭제 (비동기로 처리하지만 삭제는 확실히)
                    let imageManager = ImageManager.shared
                    for imageRecord in imageRecords {
                        // 삭제할 경로 정보 미리 복사
                        let originalPath = imageRecord.originalImagePath
                        let thumbnailPath = imageRecord.thumbnailImagePath

                        // 레코드 자체는 Realm에서 삭제
                        realm.delete(imageRecord)

                        // 파일 시스템의 이미지 파일 삭제 
                        if originalPath != nil || thumbnailPath != nil {
                            DispatchQueue.global(qos: .background).async {
                                if let originalPath = originalPath {
                                    imageManager.deleteImageFile(path: originalPath, isOriginal: true)
                                }
                                if let thumbnailPath = thumbnailPath {
                                    imageManager.deleteImageFile(path: thumbnailPath, isOriginal: false)
                                }
                            }
                        }
                    }

                    // DayCard 삭제
                    realm.delete(dayCard)
                }
            }

            observer.onNext(())
            observer.onCompleted()
        } catch {
            observer.onError(error)
        }

        return Disposables.create()
    }
}

```

### 4. 위치 기반 서비스와 Kakao Maps API 통합

**문제 상황**

- 위치 권한 획득부터 주변 병원 검색까지의 흐름에서 다양한 오류 상황 처리가 필요했습니다.
- 사용자가 위치 권한을 거부하거나 위치 서비스를 사용할 수 없는 경우에도 앱이 안정적으로 동작해야 했습니다.
- Kakao Maps API와의 통신 과정에서 발생하는 오류 처리와 백그라운드 작업 취소가 필요했습니다.

**해결 방법**

- 위치 권한 상태에 따른 명확한 상태 전이 흐름을 구현했습니다.
- 기본 위치(서울)를 사용하여 위치 권한 없이도 검색 가능하도록 구현했습니다.
- 위치기능을 사용할 수 없는 경우 주소로 검색하여 위치정보를 설정 할 수 있게 구현했습니다.
- Swift의 Task와 취소 메커니즘을 활용하여 비동기 작업을 안전하게 관리했습니다.

```swift
// HospitalSearchViewModel의 위치 권한 처리
private func handleLocationStatus() {
    let status = locationManager.authorizationStatus

    switch status {
    case .notDetermined:
        // 아직 결정되지 않은 상태 - 권한 요청
        locationManager.requestWhenInUseAuthorization()

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

// 안전한 비동기 작업 관리
private func searchHospitalsNear(latitude: Double, longitude: Double) {
    isLoadingRelay.accept(true)

    // 이전 Task 취소
    searchTask?.cancel()

    // 새 Task 시작
    searchTask = Task {
        do {
            guard !Task.isCancelled else { return }
            let hospitals = try await KakaoMapManager.shared.searchHospitals(
                latitude: latitude,
                longitude: longitude
            )

            // 취소 확인
            guard !Task.isCancelled else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hospitalsRelay.accept(hospitals)
                self.isLoadingRelay.accept(false)

                if hospitals.isEmpty {
                    self.errorRelay.accept("주변에 24시 동물병원이 없습니다.")
                } else {
                    self.errorRelay.accept(nil)
                }
            }
        } catch {
            guard !Task.isCancelled else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hospitalsRelay.accept([])
                self.isLoadingRelay.accept(false)
                self.errorRelay.accept("병원 검색 중 오류가 발생했습니다: \(error.localizedDescription)")
            }
        }
    }
}

// 리소스 정리
func cleanup() {
    locationManager.delegate = nil
    locationManager.stopUpdatingLocation()
    searchTask?.cancel() // Task 취소 추가
    searchTask = nil
}

```

## 🎯 향후 개선점

- **다국어 지원**: 영어, 일본어 등 다국어 지원으로 글로벌 사용자 확보
- **데이터 백업 및 복원**: 파일 압축 기반 데이터 백업 및 복원 기능 추가
- **테스트 코드 작성**: 단위 테스트 및 UI 테스트 추가로 앱 안정성 향상
- **성능 최적화**: 대용량 이미지 처리와 메모리 커스텀 캐싱 정책 구현

